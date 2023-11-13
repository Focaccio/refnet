import subprocess
import sys
import time
from select import select

def non_blocking_readlines(fd, timeout=0.1):
    lines = []
    while True:
        rlist, _, _ = select([fd], [], [], timeout)
        if rlist:
            line = fd.readline()
            if not line:
                break
            lines.append(line)
        else:
            break
    return lines

def send_commands_to_router(commands, router_ip, username, password):
    try:
        # Construct the SSH command
        ssh_command = f"ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 -caes128-cbc {username}@{router_ip}"

        # Start the SSH process
        ssh_process = subprocess.Popen(
            ssh_command,
            shell=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,  # Line-buffered to avoid buffering issues
            universal_newlines=True  # Text mode for cross-platform compatibility
        )

        # Wait for the password prompt
        prompt = non_blocking_readlines(ssh_process.stdout)
        sys.stdout.writelines(prompt)
        sys.stdout.flush()

        # Send password
        ssh_process.stdin.write(password + '\n')
        ssh_process.stdin.flush()

        # Wait for the command prompt
        prompt = non_blocking_readlines(ssh_process.stdout)
        sys.stdout.writelines(prompt)
        sys.stdout.flush()

        # Send commands to the router
        for command in commands:
            ssh_process.stdin.write(command + '\n')
            ssh_process.stdin.flush()
            time.sleep(2)  # Adjust sleep time as needed

            # Add logic to handle interactive prompts
            if "Password:" in prompt:
                ssh_process.stdin.write(password + '\n')
                ssh_process.stdin.flush()

            # Wait for the command prompt
            prompt = non_blocking_readlines(ssh_process.stdout)
            sys.stdout.writelines(prompt)
            sys.stdout.flush()

        # Close the stdin to signal that no more input will be sent
        ssh_process.stdin.close()

        # Read the remaining output until the process finishes
        while True:
            remaining_output = non_blocking_readlines(ssh_process.stdout)
            if not remaining_output:
                break
            sys.stdout.writelines(remaining_output)
            sys.stdout.flush()

        # Wait for the SSH process to finish
        ssh_process.communicate()

    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        if ssh_process.poll() is None:
            # If the process is still running, terminate it
            ssh_process.terminate()

if __name__ == "__main__":
    router_ip = "a.b.c.d"
    username = "nomasssys"
    password = "nomasssys"

    commands_to_send = [
        "conf t",
        "int f0/0",
        "des CODE-DID-THIS",
        "int s0/0",
        "des XSERIAL-INTERFACE-DESCRIPTION-BY-CODE",
                "int f0/1",
        "des CODE-DID-THIS2",
        "int s0/1",
        "des XSERIAL-INTERFACE-DESCRIPTION-BY-CODE2",
        "end",
        "wr"
    ]

    send_commands_to_router(commands_to_send, router_ip, username, password)
