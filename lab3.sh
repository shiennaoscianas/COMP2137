#!/bin/bash

# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file

# Function to display verbose output
verbose_output() {
    if [ "$verbose" == "true" ]; then
        echo "$1"
    fi
}

#--------------------------------------------------

# Function to transfer configure-host.sh script to server1-mgmt and apply configurations
scp configure-host.sh remoteadmin@server1-mgmt:/root
ssh remoteadmin@server1-mgmt -- "/root/configure-host.sh -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4 $verbose"

# Function to check if ssh command to server1-mgmt was successful
if [ $? -eq 0 ]; then
    verbose_output "Configurations applied successfully on server1-mgmt"
else
    echo "Error: Failed to apply configurations on server1-mgmt"
fi

#--------------------------------------------------

# Function to transfer configure-host.sh script to server2-mgmt and apply configurations
scp configure-host.sh remoteadmin@server2-mgmt:/root
ssh remoteadmin@server2-mgmt -- "/root/configure-host.sh -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3 $verbose"

# Function to check if ssh command to server2-mgmt was successful
if [ $? -eq 0 ]; then
    verbose_output "Configurations applied successfully on server2-mgmt"
else
    echo "Error: Failed to apply configurations on server2-mgmt"
fi

#--------------------------------------------------

# Function to update local /etc/hosts file
./configure-host.sh -hostentry loghost 192.168.16.3 $verbose
./configure-host.sh -hostentry webhost 192.168.16.4 $verbose

