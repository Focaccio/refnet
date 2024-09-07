import datetime
import subprocess
import getpass
import argparse
import sys
import os

def get_config(hostname, username, password):
    ssh_command = [
        "ssh",
        "-oKexAlgorithms=+diffie-hellman-group1-sha1",
        "-c", "3des-cbc",
        "-o", "StrictHostKeyChecking=no",
        f"{username}@{hostname}",
        "show run"
    ]
    try:
        result = subprocess.run(ssh_command, input=password.encode(), capture_output=True, check=True, timeout=30)
        return result.stdout.decode('utf-8', errors='replace')
    except subprocess.CalledProcessError as e:
        print(f"Error executing SSH command: {e}")
        if e.stderr:
            print(f"SSH error output: {e.stderr.decode('utf-8', errors='replace')}")
        return None
    except subprocess.TimeoutExpired:
        print("SSH connection timed out. Please check your network connection and try again.")
        return None

def save_config(config, filename):
    try:
        print("Configuration being saved:")
        with open(filename, 'w', encoding='utf-8') as file:
            for line in config.splitlines():
                if line.strip():  # Only write non-empty lines
                    print(line)  # Print each line to the screen
                    file.write(line + '\n')
        print(f"\nConfiguration saved to {filename}")
        return True
    except IOError as e:
        print(f"Error writing to file: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Capture Cisco device configuration via SSH.")
    parser.add_argument("hostname", help="Hostname or IP address of the device")
    parser.add_argument("username", help="SSH username")
    parser.add_argument("-o", "--output", help="Output file name (default: hostname_config_YYYYMMDD-HHMMSS.txt)")
    args = parser.parse_args()

    password = getpass.getpass("Enter password: ")

    if not args.output:
        current_datetime = datetime.datetime.now()
        date_string = current_datetime.strftime("%Y%m%d-%H%M%S")
        args.output = f"{args.hostname}_config_{date_string}.txt"

    config = get_config(args.hostname, args.username, password)
    if config:
        if save_config(config, args.output):
            print("\nSuccess: Configuration captured and saved successfully!")
        else:
            print("\nFailure: Unable to save the configuration.")
    else:
        print("\nFailure: Unable to retrieve the configuration.")

if __name__ == "__main__":
    main()