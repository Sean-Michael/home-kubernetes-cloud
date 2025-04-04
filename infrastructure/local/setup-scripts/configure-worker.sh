#!/bin/bash
# configure-worker.sh - Configures a VM as K3s worker node
# Usage: ./configure-worker.sh [MASTER_IP] [NODE_TOKEN] [HOSTNAME]

set -e

if [ $# -lt 2 ]; then
    echo "Usage: ./configure-worker.sh [MASTER_IP] [NODE_TOKEN] [HOSTNAME]"
    exit 1
fi

MASTER_IP=$1
NODE_TOKEN=$2
HOSTNAME=${3:-""}

# Update hostname if provided
if [ ! -z "$HOSTNAME" ]; then
    sudo hostnamectl set-hostname "$HOSTNAME"
fi

# Disable swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Install K3s agent
echo "Installing K3s agent and joining cluster..."
curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$NODE_TOKEN sudo sh -s - --flannel-iface=enp1s0

echo "Worker node configured and joined to cluster!"
echo "Verify by running 'kubectl get nodes' on the master node."