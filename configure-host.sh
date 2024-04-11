#!/bin/bash

# Function to log changes to syslog
# if changes are made, this is sent to the system log describing the changes
log_changes() {
    local message=$1
    logger -t configure-host.sh "$message"
}

#----------------------------------------------------

# Function to check if verbose mode is enabled
is_verbose() {
    [[ $verbose == "true" ]]
}

#----------------------------------------------------

# Function to update name desiredName
update_hostname() {
    local desired_name=$1
    local current_hostname=$(hostname)
    if [ "$current_hostname" != "$desired_name" ]; then
        sudo sed -i "s/$current_hostname/$desired_name/g" /etc/hostname
        sudo sed -i "s/127.0.1.1.*$current_hostname/127.0.1.1\t$desired_name/g" /etc/hosts
        sudo hostnamectl set-hostname "$desired_name"
        if is_verbose; then
            log_changes "Hostname updated to $desired_name"
        fi
    fi
}

#----------------------------------------------------

# Function to update ip desiredIPAddress
update_ip() {
    local desired_ip=$1
    local current_ip=$(hostname -I | awk '{print $1}')
    if [ "$current_ip" != "$desired_ip" ]; then
        sudo sed -i "s/$current_ip/$desired_ip/g" /etc/hosts
        # Update netplan configuration assuming it's using netplan
        sudo sed -i "s/address $current_ip/address $desired_ip/g" /etc/netplan/*.yaml
        sudo netplan apply
        if is_verbose; then
            log_changes "IP address updated to $desired_ip"
        fi
    fi
}

#----------------------------------------------------

# Function to update hostentry desiredName desiredIPAddress
update_host_entry() {
    local desired_name=$1
    local desired_ip=$2
    local host_entry="$desired_ip\t$desired_name"
    if ! grep -q "$host_entry" /etc/hosts; then
        echo -e "$desired_ip\t$desired_name" | sudo tee -a /etc/hosts >/dev/null
        if is_verbose; then
            log_changes "Added host entry: $desired_name $desired_ip"
        fi
    fi
}

#----------------------------------------------------

# Handle SIGTERM, SIGINT, and SIGHUP signals
# The script must ignore TERM, HUP and INT signals.
trap '' SIGTERM SIGINT SIGHUP

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -verbose)
        verbose="true"
        shift
        ;;
        -name)
        desired_name="$2"
        shift
        shift
        ;;
        -ip)
        desired_ip="$2"
        shift
        shift
        ;;
        -hostentry)
        desired_name="$2"
        desired_ip="$3"
        shift
        shift
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

#----------------------------------------------------

# Apply configurations
if [ -n "$desired_name" ]; then
    update_hostname "$desired_name"
fi

if [ -n "$desired_ip" ]; then
    update_ip "$desired_ip"
fi

if [ -n "$desired_name" ] && [ -n "$desired_ip" ]; then
    update_host_entry "$desired_name" "$desired_ip"
fi

