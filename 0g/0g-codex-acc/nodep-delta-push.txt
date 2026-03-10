#!/usr/bin/env python3
"""Push full-device configuration commands using the system ssh client and only stdlib imports."""

from __future__ import annotations

import getpass
import os
import pty
import select
import shutil
import subprocess
import sys
import time
from errno import EIO
from pathlib import Path


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

            if output.rstrip().endswith("#") or output.rstrip().endswith(">"):
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


def load_commands(directory: str, filename: str) -> tuple[Path, list[str]]:
    path = Path(directory).expanduser() / filename
    if path.suffix.lower() != ".txt":
        raise ValueError("The filename must end with .txt")
    if not path.is_file():
        raise FileNotFoundError(f"File not found: {path}")

    commands = []
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("!"):
            commands.append(stripped)

    if not commands:
        raise ValueError("The text file does not contain any usable commands.")

    return path, commands


def main() -> int:
    target_ip = input("Target router IP address: ").strip()
    username = input("Username: ").strip()
    password = getpass.getpass("Password: ")
    directory = input("Directory containing the .txt file: ").strip()
    filename = input("Text filename (.txt): ").strip()

    if not target_ip or not username or not directory or not filename:
        print("IP address, username, directory, and filename are required.")
        return 1

    try:
        file_path, commands = load_commands(directory, filename)
    except (FileNotFoundError, ValueError, OSError) as exc:
        print(exc)
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

        print(f"Loaded {len(commands)} commands from {file_path}")

        print(shell.run_command("terminal length 0", timeout=0.6), end="")
        print(shell.run_command("configure terminal", timeout=0.8), end="")

        for command in commands:
            print(f"Sending: {command}")
            output = shell.run_command(command, timeout=0.8)
            if output.strip():
                print(output, end="" if output.endswith("\n") else "\n")

        print(shell.run_command("end", timeout=0.8), end="")
        print("Completed full-device configuration push.")
        print(f"Pasted file: {file_path}")
        return 0
    finally:
        shell.close()


if __name__ == "__main__":
    raise SystemExit(main())
