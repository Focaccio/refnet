import subprocess
import getpass
import argparse

def push_config(hostname, username, password, enable_password, config_file):
    try:
        with open(config_file, 'r') as file:
            config = file.read()
    except IOError as e:
        print(f"Error reading configuration file: {e}")
        return False

    ssh_command = [
        "ssh",
        "-oKexAlgorithms=+diffie-hellman-group1-sha1",
        "-c", "3des-cbc",
        "-o", "StrictHostKeyChecking=no",
        f"{username}@{hostname}",
    ]

    try:
        ssh = subprocess.Popen(ssh_command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        
        # Send configuration commands
        ssh.stdin.write("enable\n")
        ssh.stdin.write(f"{enable_password}\n")
        ssh.stdin.write("configure terminal\n")
        ssh.stdin.write(config)
        ssh.stdin.write("end\n")
        ssh.stdin.write("write memory\n")
        ssh.stdin.write("exit\n")
        ssh.stdin.close()

        # Capture and print output
        for line in ssh.stdout:
            print(line.strip())
        
        # Print any errors
        for line in ssh.stderr:
            print(f"Error: {line.strip()}")

        ssh.wait(timeout=60)  # 60 second timeout
        
        if ssh.returncode == 0:
            print("\nConfiguration successfully pushed and saved.")
            return True
        else:
            print(f"\nError pushing configuration. Return code: {ssh.returncode}")
            return False

    except subprocess.TimeoutExpired:
        print("SSH connection timed out.")
        return False
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Push Cisco device configuration via SSH.")
    parser.add_argument("hostname", help="Hostname or IP address of the device")
    parser.add_argument("username", help="SSH username")
    parser.add_argument("config_file", help="Path to the configuration file")
    args = parser.parse_args()

    password = getpass.getpass("Enter login password: ")
    enable_password = getpass.getpass("Enter enable password: ")

    if push_config(args.hostname, args.username, password, enable_password, args.config_file):
        print("\nSuccess: Configuration pushed successfully!")
    else:
        print("\nFailure: Unable to push the configuration.")

if __name__ == "__main__":
    main()