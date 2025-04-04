#!/bin/bash
# post-install.sh - Runs post install configurations on a VM
# Usage: ./post-install.sh [VM_NAME] [IP_ADDRESS]
# Realistically this is just a reference of what to do

# Default Values
VM_NAME=${1:-"k3s-node"}
IP_ADDRESS=${2:-"192.168.122.11"}

# Set the hostname
sudo hostnamectl set-hostname $VM_NAME

# Create a new netplan config file instead of appending to existing one
sudo tee /etc/netplan/01-netcfg.yaml > /dev/null << EOF
network:
  ethernets:
    enp1s0:
      dhcp4: no
      addresses: [$IP_ADDRESS/24]
      gateway4: 192.168.122.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
  version: 2
EOF

# Apply network configuration
sudo netplan apply

# Update system and install prerequisites
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl open-iscsi nfs-common

# Print confirmation
echo "Post-installation completed for $VM_NAME with IP $IP_ADDRESS"
echo "The system will shutdown in 5 seconds..."

# Delay shutdown to allow seeing the message
sleep 5
sudo shutdown -h now