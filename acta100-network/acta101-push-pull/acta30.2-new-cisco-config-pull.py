import datetime
import subprocess
import getpass

# variables
hostname = "172.16.86.7172.16.86.7_config_20240902-125456.txt"
username = 'lab'
password = getpass.getpass("Enter password: ")  # Prompt for password securely

# set-up
current_datetime = datetime.datetime.now()
date_string = current_datetime.strftime("%Y%m%d-%H%M%S")
filename = f"{hostname}_config_{date_string}.txt"

# ssh command to net device
ssh_command = [
    "ssh",
    "-oKexAlgorithms=+diffie-hellman-group1-sha1",
    "-c", "3des-cbc",
    "-o", "StrictHostKeyChecking=no",
    f"{username}@{hostname}",
    "show run"
]

try:
    # Execute SSH command
    result = subprocess.run(ssh_command, input=password.encode(), capture_output=True, check=True)

    # Decode the output
    output = result.stdout.decode('utf-8', errors='replace')

    # Remove blank lines and write output to file
    with open(filename, 'w', encoding='utf-8') as file:
        for line in output.splitlines():
            if line.strip():  # Only write non-empty lines
                file.write(line + '\n')

    print(f"Configuration saved to {filename}")

except subprocess.CalledProcessError as e:
    print(f"Error executing SSH command: {e}")
    if e.stderr:
        print(f"SSH error output: {e.stderr.decode('utf-8', errors='replace')}")
except Exception as e:
    print(f"An unexpected error occurred: {e}")