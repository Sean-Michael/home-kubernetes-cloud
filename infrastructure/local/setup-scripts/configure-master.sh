#!/bin/bash
# configure-master.sh - Configures a VM as K3s master node
# Run this script ON the master VM after it's created and network is configured

set -e

# Disable swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Update hostname if provided
if [ ! -z "$1" ]; then
    sudo hostnamectl set-hostname "$1"
fi

# Install K3s server
echo "Installing K3s server..."
curl -sfL https://get.k3s.io | sudo sh -s - --disable=traefik

# Wait for K3s to be ready
echo "Waiting for K3s to initialize..."
sleep 30

# Get node token for workers to join
NODE_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
MASTER_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

echo "=================================================================="
echo "K3s master node configured successfully!"
echo "Master IP: $MASTER_IP"
echo "Node Token: $NODE_TOKEN"
echo ""
echo "To join worker nodes, run the following on each worker:"
echo "curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$NODE_TOKEN sh -"
echo "=================================================================="

# Copy kubeconfig to user's home directory for easier access
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo sed -i "s/127.0.0.1/$MASTER_IP/g" $HOME/.kube/config

# Set environment variable
echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc