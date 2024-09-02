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
#[ITEM1-PC1] username must be privi 15
#[ITEM1-PC2] term len 0
###############################################################################################
#~~~VARIABLE-NOTES
#
###############################################################################################
#~~~acta14.alpha
import datetime
import subprocess
# variables
hostname = "a.b.c.d"
username = 'username'
password = 'password'

#set-up
current_datetime = datetime.datetime.now()
date_string = current_datetime.strftime("%Y%m%d-%H%M%S")
filename = f"{hostname}_config_{date_string}"

# ssh command to net device
ssh_command = f"ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 -c 3des-cbc {username}@{hostname} 'sh run'"
try:
    # Execute SSH command
    result = subprocess.check_output(ssh_command, shell=True, text=True)

    # Extracting sh_run from the result
    sh_run = result.strip()

    # Write sh_run to a local file
    with open(filename, 'w') as file:
        file.write(sh_run)
    print(f"sh-run: {sh_run}")
    print("Data written to")
    print(filename)
except subprocess.CalledProcessError as e:
    print(f"Error: {e}")
#~~~acta14.omega
# #############################################################################################
#~~~BY? | NOTES?
#areaf | aggregated 20231111
###############################################################################################