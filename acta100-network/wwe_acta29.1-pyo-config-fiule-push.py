import subprocess

def send_config_to_router(router_ip, username, password, config_file):
    # Establish an authenticated SSH connection with the router
    ssh_client = subprocess.Popen(["ssh", "-oKexAlgorithms=+diffie-hellman-group1-sha1", "-caes128-cbc", username + "@" + router_ip], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    # Send the password for authentication
    ssh_client.stdin.write(password.encode("utf-8") + "\n".encode("utf-8"))
    ssh_client.stdin.flush()

    # Open the configuration file and read each line
    with open(config_file, "r") as f:
        config_lines = f.readlines()

    # Send each configuration line to the router
    for line in config_lines:
        ssh_client.stdin.write((line + "\n").encode("utf-8"))

    # Flush the input buffer to ensure all commands are sent
    ssh_client.stdin.flush()

    # Wait for the configuration to finish applying
    ssh_client.wait()

    # Check for any errors during execution
    error_output = ssh_client.stderr.read().decode("utf-8")
    if error_output:
        print(error_output)

if __name__ == "__main__":
    router_ip = "10.0.0.1"
    username = "lab"
    password = "lab"
    config_file = "/rn440_py3_config-pusher101/a28-config-pusher/config.txt"

    send_config_to_router(router_ip, username, password, config_file)
