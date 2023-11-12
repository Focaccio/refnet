###############################################################################################
#~~~WHA?
#NAME: acta14
#WHY: Get device config to a text .txt file
#WHAT: Action with "recahable" ip addressed network device [ITEM1]
#INPUT: IP address, username, password
#OUTPUT: device config to .txt file 
#AUTO: No | Require user input (currently)
###############################################################################################
#~~~FIT?
#FIT1: Old cisco devices with diffie-hellman-group1-sha1 key exchange
###############################################################################################
#~~~PRE-CONDITIONS?
#[ITEM1] username must be privi 15
#[ITEM1] term len 0
###############################################################################################
#~~~VARIABLE-NOTES
#
###############################################################################################
import subprocess
# variables
hostname = 'a.b.c.d'
username = 'username'
password = 'password'

# ssh command to net device
ssh_command = f"ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 -c 3des-cbc {username}@{hostname} 'sh run'"

try:
    # Execute SSH command
    result = subprocess.check_output(ssh_command, shell=True, text=True)

    # Extracting sh_run from the result
    sh_run = result.strip()

    # Write sh_run to a local file
    with open('network-config.txt', 'w') as file:
        file.write(sh_run)

    print(f"sh-run: {sh_run}")
    print("Data written to network-config.txt")
except subprocess.CalledProcessError as e:
    print(f"Error: {e}")
###############################################################################################
#~~~BY? | NOTES?
#areaf | aggregated 20231111
###############################################################################################