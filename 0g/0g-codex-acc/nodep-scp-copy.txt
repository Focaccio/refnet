#!/usr/bin/env python3
"""Copy a local file to a remote system using the system scp client and stdlib only."""

from __future__ import annotations

import getpass
import os
import pty
import readline
import select
import shutil
import subprocess
import sys
import time
from errno import EIO
from pathlib import Path

readline.parse_and_bind("tab: complete")
readline.parse_and_bind(r'"\e[3~": delete-char')
readline.parse_and_bind(r'"\C-h": backward-delete-char')
readline.parse_and_bind(r'"\177": backward-delete-char')


class ScpSession:
    def __init__(
        self,
        source_ip: str,
        source_path: Path,
        dest_ip: str,
        dest_user: str,
        dest_password: str,
        dest_path: str,
    ):
        self.source_ip = source_ip
        self.source_path = source_path
        self.dest_ip = dest_ip
        self.dest_user = dest_user
        self.dest_password = dest_password
        self.dest_path = dest_path
        self.master_fd: int | None = None
        self.process: subprocess.Popen[bytes] | None = None

    def run(self) -> str:
        if shutil.which("scp") is None:
            raise RuntimeError("scp client not found in PATH.")

        master_fd, slave_fd = pty.openpty()
        self.master_fd = master_fd
        self.process = subprocess.Popen(
            [
                "scp",
                "-o",
                "StrictHostKeyChecking=ask",
                "-o",
                f"BindAddress={self.source_ip}",
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
                str(self.source_path),
                f"{self.dest_user}@{self.dest_ip}:{self.dest_path}",
            ],
            stdin=slave_fd,
            stdout=slave_fd,
            stderr=slave_fd,
            close_fds=True,
        )
        os.close(slave_fd)

        output = ""
        password_sent = False
        deadline = time.time() + 120

        while time.time() < deadline:
            output += self.read_until_quiet(timeout=0.5)
            lowered = output.lower()

            if "are you sure you want to continue connecting" in lowered:
                self.send("yes")
                continue

            if "password:" in lowered and not password_sent:
                self.send(self.dest_password)
                password_sent = True
                continue

            if self.process.poll() is not None:
                if self.process.returncode == 0:
                    return output
                break

        raise RuntimeError(f"SCP transfer failed or timed out.\n{output.strip()}")

    def send(self, text: str) -> None:
        if self.master_fd is None:
            raise RuntimeError("SCP session is not open.")
        os.write(self.master_fd, (text + "\n").encode("utf-8"))

    def read_until_quiet(self, timeout: float = 1.2) -> str:
        if self.master_fd is None:
            raise RuntimeError("SCP session is not open.")

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

    def close(self) -> None:
        if self.process is not None and self.process.poll() is None:
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


def main() -> int:
    source_ip = input("Local source IP address: ").strip()
    source_directory = input("Local source directory: ").strip()
    source_filename = input("Local source filename: ").strip()
    dest_ip = input("Destination IP address: ").strip()
    dest_user = input("Destination username: ").strip()
    dest_password = getpass.getpass("Destination password: ")
    dest_directory = input("Destination directory: ").strip()
    dest_filename = input("Destination filename: ").strip()

    if not all([source_ip, source_directory, source_filename, dest_ip, dest_user, dest_directory, dest_filename]):
        print("All fields are required.")
        return 1

    source_path = Path(source_directory).expanduser() / source_filename
    if not source_path.is_file():
        print(f"Source file not found: {source_path}")
        return 1

    dest_path = str(Path(dest_directory) / dest_filename)

    session = ScpSession(
        source_ip=source_ip,
        source_path=source_path,
        dest_ip=dest_ip,
        dest_user=dest_user,
        dest_password=dest_password,
        dest_path=dest_path,
    )

    try:
        output = session.run()
        if output.strip():
            print(output, end="" if output.endswith("\n") else "\n")
        print(f"Copied {source_path} to {dest_user}@{dest_ip}:{dest_path}")
        return 0
    except RuntimeError as exc:
        print(exc)
        return 1
    finally:
        session.close()


if __name__ == "__main__":
    raise SystemExit(main())
