###############################################################################################
#~~~WHA?
#NAME: acta20
#WHY: Push config commands to net device using text .txt file
#WHAT: Action with "recahable" ip addressed network device [ITEM1]
#INPUT: hostname, username, password, config_file_path
#OUTPUT: text file commands run on netdevice [ITEM1]
#AUTO: Yes | runs with no user input needed
###############################################################################################
#~~~FIT?
#FIT1: cisco devices
###############################################################################################
#~~~DEPENDENCIES?
#paramiko
#
###############################################################################################
#~~~PRE-CONDITIONS?
#[ITEM1-PC1] username must be privi 15
#[ITEM1-PC2] term len 0
###############################################################################################
#~~~VARIABLE-NOTES
#
###############################################################################################
#~~~acta14.alpha
import paramiko
from time import sleep

def configure_router(hostname, username, password, config_file_path):
    # Connect to the router via SSH
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname, username=username, password=password)

    # Open an SSH session
    session = ssh.invoke_shell()

    # Read the configuration file
    with open(config_file_path, 'r') as config_file:
        config_commands = config_file.readlines()

    # Send configuration commands to the router
    for command in config_commands:
        session.send(command)
        sleep(1)  # Add a delay between commands (adjust as needed)

    # Close the SSH session
    session.close()

    # Disconnect from the router
    ssh.close()

if __name__ == "__main__":
    hostname = "10.0.0.1"
    username = "lab"
    password = "lab"
    config_file_path = "/rn440_py3_config-pusher101/cfg-test.txt"

    configure_router(router_hostname, router_username, router_password, config_file_path)

# Open the text file for reading.
with open(config_file_path, "r") as f:
    # Read the entire contents of the file into a variable.
    contents = f.read()

# Print the contents of the file.
print(contents)
#~~~acta20.omega
# #############################################################################################
#~~~BY? | NOTES?
#areaf | aggregated 20231112
###############################################################################################

