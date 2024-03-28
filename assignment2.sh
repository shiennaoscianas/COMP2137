#!/bin/bash

# Assignment 2 - System Modification
# This is for checking if there is a netplan configuration file.
netplan_file="/etc/netplan/50-cloud-init.yaml"
if [ ! -f "$netplan_file" ]; then
    echo "Netplan configuration file not found: $netplan_file"
    exit 1
fi

# This is to specify the updated 192.168.16 network interface settings.
new_config="  addresses:
    - 192.168.16.21/24
  gateway4: 192.168.16.2
  nameservers:
    addresses: [192.168.16.2]
    search: [home.arpa, localdomain]"

# This defines the network interface for private management.
# This has been replaced with the actual interface name
private_mgmt_interface="eth0"  

# Apply the updated settings to the netplan configuration.
sudo sed -i "/$private_mgmt_interface/,/^$/!b;/^$/i$new_config" "$netplan_file"

# Update /etc/hosts file
sudo sed -i '/^192\.168\.16\.21[[:space:]]\+server1$/d' /etc/hosts  # Remove ol>
echo "192.168.16.21    server1" | sudo tee -a /etc/hosts >/dev/null  # Add new >

# Implement the netplan configuration.
sudo netplan apply

echo "Configuration updated successfully."

# To update package index
sudo apt update

# To install Apache2
sudo apt install -y apache2

# To start Apache2
sudo systemctl start apache2

# To enable Apache2 and to start on boot
sudo systemctl enable apache2

# To stop Apache2
sudo systemctl stop apache2

# To switch back to the original Apache2 setup
sudo cp /etc/apache2/apache2.conf.orig /etc/apache2/apache2.conf
sudo cp /etc/apache2/ports.conf.orig /etc/apache2/ports.conf

# To emove custom virtual host configurations
sudo rm -f /etc/apache2/sites-available/*.conf
sudo rm -f /etc/apache2/sites-enabled/*.conf

# This is to enable default virtual host
sudo ln -s /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-enabled/000-default.conf

# To restart Apache2
sudo systemctl start apache2

# To check if Apache2 service is running
if systemctl is-active --quiet apache2; then
    echo "Apache2 is running."

    
# To check if Apache2 configuration is default
    if [ -f "/etc/apache2/apache2.conf" ]; then
        echo "Apache2 is using the default configuration."
    else
        echo "Apache2 is not using the default configuration."
    fi
else
    echo "Apache2 is not running."
fi
# To Squid WebProxy
# To Update package index
sudo apt update

# To install Squid
sudo apt install -y squid

# To start Squid service
sudo systemctl start squid

# To enable Squid service to start on boot
sudo systemctl enable squid

# To check if Squid service is running
if systemctl is-active --quiet squid; then
    echo "Squid service is running."

# Check if Squid is using the default configuration file
    if [ -f "/etc/squid/squid.conf" ]; then
        echo "Squid is using the default configuration file."

    else
        echo "Squid is not using the default configuration file."
    fi
else
    echo "Squid service is not running."
fi
# This is for the Firewall Script
# To enable ufw
sudo ufw enable

# To allow SSH on port 22 only on the management network
sudo ufw allow from mgmt_network_ip to any port 22

# To allow HTTP on both interfaces
sudo ufw allow http

# To allow web proxy on both interfaces (assuming default Squid proxy port 3128)
sudo ufw allow 3128

# To enable logging (optional)
sudo ufw logging on

# To reload ufw to apply changes
sudo ufw reload

# To display firewall rules
sudo ufw status verbose


# This is the user list that needs to be created.
usernames=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

# To create users with home directory and bash shell
for user in "${usernames[@]}"; do
    sudo useradd -m -s /bin/bash "$user"
done

# To create SSH Keys for rsa and ed25519 algorithm
# To loop through each username
for username in "${usernames[@]}"; do
	# To check if the user exists
    if id "$username" &>/dev/null; then
        echo "Adding SSH keys for $username"

        # Create user's SSH directory if it doesn't exist
        sudo -u "$username" mkdir -p /home/"$username"/.ssh
	sudo chmod 700 "/home/${username}/.ssh"
        # Generate RSA key pair if it doesn't exist
        if [ ! -f "/home/$username/.ssh/id_rsa" ]; then
            sudo -i -u "$username" ssh-keygen -t rsa -N "" -f "/home/$username/.ssh/id_rsa"
        fi

        # Generate Ed25519 key pair if it doesn't exist
        if [ ! -f "/home/$username/.ssh/id_ed25519" ]; then
            sudo -i -u "$username" ssh-keygen -t ed25519 -N "" -f "/home/$username/.ssh/id_ed25519"
        fi

        # Append RSA public key to authorized_keys
        cat "/home/$username/.ssh/id_rsa.pub" | sudo -u "$username" tee -a "/home/$username/.ssh/authorized_keys" >/dev/null

        # Append Ed25519 public key to authorized_keys
        cat "/home/$username/.ssh/id_ed25519.pub" | sudo -u "$username" tee -a "/home/$username/.ssh/authorized_keys" >/dev/null
    else
        echo "User $username does not exist."
    fi
done

# Configure userid dennis to have sudo access
userid="dennis"

# Check if the user exists
if id "$userid" &>/dev/null; then
    # Add the user to the sudo group
    usermod -aG sudo "$userid"
    echo "Sudo access granted to $userid."
else
    echo "User $userid does not exist."
fi

# Define the userid
userid="dennis"

# Define the public key
public_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

# Check if the user exists
if ! id "$userid" &>/dev/null; then
    echo "User '$userid' does not exist."
    exit 1
fi

# Ensure the .ssh directory exists
sudo mkdir -p /home/"$userid"/.ssh

# Set the correct permissions for the .ssh directory
sudo chmod 700 /home/"$userid"/.ssh

# Add the public key to the authorized_keys file
echo "$public_key" >> /home/"$userid"/.ssh/authorized_keys

# Set the correct permissions for the authorized_keys file
sudo chmod 600 /home/"$userid"/.ssh/authorized_keys

# Set the ownership of the .ssh directory and authorized_keys file
sudo chown -R "$userid:$userid" /home/"$userid"/.ssh

echo "SSH access has been configured for user '$userid'."

