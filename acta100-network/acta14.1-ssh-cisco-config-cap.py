###############################################################################################
#~~~WHA?
#NAME: acta14
#AUTO: No | Require user input (currently)
#INPUT: IP address, username, password
#OUTPUT: cisco config to .txt file 
##############################################################################################################################################################################################
#~~~FIT?
#Old cisco devices with diffie-hellman-group1-sha1 key exchange
###############################################################################################
#~~~PRE-CONDITIONS?
#username must be privi 15
#term len 0
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
#~~~areaf aggregated 20231111
###############################################################################################