#!/bin/bash
# post-install.sh - Runs post install configurations on a VM
# Usage: ./post-install.sh [VM_NAME]

# Default Values

# Connect to the VM:

# Execute the following commands within the VM:
#   "1. Update system: sudo apt update && sudo apt upgrade -y"
sudo apt update && sudo apt upgrade -y
#   "2. Install prerequisites: sudo apt install -y curl open-iscsi nfs-common"
sudo apt install -y curl open-iscsi nfs-common
#   "3. Shutdown VM: sudo shutdown -h now"
sudo shutdown -h now