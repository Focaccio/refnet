#!/usr/bin/env python3
"""Pull network device configuration using the system ssh client and only stdlib imports."""

from __future__ import annotations

import getpass
import os
import pty
import re
import select
import shutil
import subprocess
import sys
import time
from errno import EIO
from datetime import datetime
from pathlib import Path


def extract_hostname(text: str) -> str | None:
    patterns = [
        r"^hostname\s+([A-Za-z0-9_.-]+)",
        r"^set\s+system\s+host-name\s+([A-Za-z0-9_.-]+)",
        r"^sysname\s+([A-Za-z0-9_.-]+)",
    ]
    for pattern in patterns:
        match = re.search(pattern, text, flags=re.MULTILINE | re.IGNORECASE)
        if match:
            return match.group(1)
    return None


def sanitize_filename(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_.-]", "-", value.strip())
    return cleaned or "unknown-host"


class SshShell:
    def __init__(self, target_ip: str, username: str, password: str):
        self.target_ip = target_ip
        self.username = username
        self.password = password
        self.master_fd: int | None = None
        self.process: subprocess.Popen[bytes] | None = None

    def connect(self) -> str:
        if shutil.which("ssh") is None:
            raise RuntimeError("ssh client not found in PATH.")

        master_fd, slave_fd = pty.openpty()
        self.master_fd = master_fd
        self.process = subprocess.Popen(
            [
                "ssh",
                "-o",
                "StrictHostKeyChecking=ask",
                "-o",
                "KexAlgorithms=+diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1,diffie-hellman-group1-sha1",
                "-o",
                "HostKeyAlgorithms=+ssh-rsa,ssh-dss",
                "-o",
                "PubkeyAcceptedAlgorithms=+ssh-rsa,ssh-dss",
                "-o",
                "Ciphers=+aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc",
                "-o",
                "PreferredAuthentications=password",
                "-o",
                "PubkeyAuthentication=no",
                "-o",
                "ConnectTimeout=10",
                f"{self.username}@{self.target_ip}",
            ],
            stdin=slave_fd,
            stdout=slave_fd,
            stderr=slave_fd,
            close_fds=True,
        )
        os.close(slave_fd)

        output = ""
        password_sent = False
        deadline = time.time() + 20

        while time.time() < deadline:
            output += self.read_until_quiet(timeout=0.5)
            lowered = output.lower()

            if "are you sure you want to continue connecting" in lowered:
                self.send("yes")
                continue

            if "password:" in lowered and not password_sent:
                self.send(self.password)
                password_sent = True
                continue

            if re.search(r"[A-Za-z0-9_.-]+[>#]\s*$", output):
                return output

            if self.process.poll() is not None:
                break

        raise RuntimeError(f"SSH login failed or timed out.\n{output.strip()}")

    def close(self) -> None:
        if self.process is not None and self.process.poll() is None:
            try:
                self.send("exit")
                time.sleep(0.2)
            except OSError:
                pass
            self.process.terminate()
            try:
                self.process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.process.kill()
        if self.master_fd is not None:
            try:
                os.close(self.master_fd)
            except OSError:
                pass
            self.master_fd = None

    def send(self, command: str) -> None:
        if self.master_fd is None:
            raise RuntimeError("SSH session is not open.")
        os.write(self.master_fd, (command + "\n").encode("utf-8"))

    def read_until_quiet(self, timeout: float = 1.2) -> str:
        if self.master_fd is None:
            raise RuntimeError("SSH session is not open.")

        end = time.time() + timeout
        output = ""
        while time.time() < end:
            remaining = max(0.0, end - time.time())
            ready, _, _ = select.select([self.master_fd], [], [], remaining)
            if not ready:
                break
            try:
                chunk = os.read(self.master_fd, 65535).decode("utf-8", errors="ignore")
            except OSError as exc:
                if exc.errno == EIO:
                    break
                raise
            if not chunk:
                break
            output += chunk
            end = time.time() + timeout
        return output

    def run_command(self, command: str, timeout: float = 1.2) -> str:
        self.send(command)
        return self.read_until_quiet(timeout=timeout)


def main() -> int:
    target_ip = input("Target device IP address: ").strip()
    username = input("Username: ").strip()
    password = getpass.getpass("Password: ")

    if not target_ip or not username:
        print("IP address and username are required.")
        return 1

    shell = SshShell(target_ip=target_ip, username=username, password=password)

    try:
        banner = shell.connect()
    except RuntimeError as exc:
        print(exc)
        return 1

    try:
        if banner.strip():
            print(banner, end="" if banner.endswith("\n") else "\n")

        paging_off_commands = [
            "terminal length 0",
            "terminal pager 0",
            "no page",
            "set cli screen-length 0",
            "screen-length 0 temporary",
        ]
        for cmd in paging_off_commands:
            shell.run_command(cmd, timeout=0.6)

        config_commands = [
            "show running-config",
            "show configuration",
            "show configuration | display set",
            "display current-configuration",
            "show config",
        ]

        config_output = ""
        used_command = ""
        for cmd in config_commands:
            output = shell.run_command(cmd, timeout=2.0)
            lowered = output.lower()
            if output.strip() and not any(
                phrase in lowered
                for phrase in [
                    "invalid input",
                    "incomplete command",
                    "unknown command",
                    "error:",
                    "% unrecognized",
                ]
            ):
                config_output = output
                used_command = cmd
                break

        if not config_output:
            print("Could not retrieve configuration with built-in command list.")
            return 1

        host = extract_hostname(config_output)
        if not host:
            prompt_text = shell.read_until_quiet(timeout=0.8)
            prompt_lines = prompt_text.splitlines()
            if prompt_lines:
                prompt_match = re.search(r"([A-Za-z0-9_.-]+)[#>]\s*$", prompt_lines[-1])
                if prompt_match:
                    host = prompt_match.group(1)

        hostname = sanitize_filename(host or target_ip)
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        output_name = f"{hostname}-{timestamp}.txt"
        output_path = Path(__file__).resolve().parent / output_name

        header = (
            f"# Target: {target_ip}\n"
            f"# Retrieved: {datetime.now().isoformat()}\n"
            f"# Command: {used_command}\n\n"
        )
        output_path.write_text(header + config_output, encoding="utf-8")

        print(f"Configuration saved to: {output_path}")
        return 0
    finally:
        shell.close()


if __name__ == "__main__":
    raise SystemExit(main())
