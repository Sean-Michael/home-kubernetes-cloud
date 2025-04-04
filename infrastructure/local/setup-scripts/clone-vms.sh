#!/bin/bash
# clone-vms.sh - Clones VMs from base image for K3s cluster
# Usage: ./clone-vms.sh [BASE_VM_NAME]

set -e

BASE_VM=${1:-"k3s-base"}
VM_PATH="/var/lib/libvirt/images/k3s-cluster"

# Check if base VM exists
if ! sudo virsh list --all | grep -q "$BASE_VM"; then
    echo "Error: Base VM '$BASE_VM' not found!"
    exit 1
fi

# Check if base VM is running
if sudo virsh list | grep -q "$BASE_VM"; then
    echo "Base VM is running. Shutting down..."
    sudo virsh shutdown "$BASE_VM"
    sleep 5
fi

# Creating master node
echo "=== Creating master node VM ==="
sudo virt-clone \
  --original "$BASE_VM" \
  --name "k3s-master" \
  --file "$VM_PATH/k3s-master.qcow2" \
  --auto-clone

# Set master resources
sudo virsh setmaxmem k3s-master 6G --config
sudo virsh setmem k3s-master 6G --config
sudo virsh setvcpus k3s-master 2 --config --maximum
sudo virsh setvcpus k3s-master 2 --config

# Creating worker nodes
echo "=== Creating worker node 1 VM ==="
sudo virt-clone \
  --original "$BASE_VM" \
  --name "k3s-worker1" \
  --file "$VM_PATH/k3s-worker1.qcow2" \
  --auto-clone

sudo virsh setmaxmem k3s-worker1 8G --config
sudo virsh setmem k3s-worker1 8G --config
sudo virsh setvcpus k3s-worker1 3 --config --maximum
sudo virsh setvcpus k3s-worker1 3 --config

echo "=== Creating worker node 2 VM ==="
sudo virt-clone \
  --original "$BASE_VM" \
  --name "k3s-worker2" \
  --file "$VM_PATH/k3s-worker2.qcow2" \
  --auto-clone

sudo virsh setmaxmem k3s-worker2 8G --config
sudo virsh setmem k3s-worker2 8G --config
sudo virsh setvcpus k3s-worker2 3 --config --maximum
sudo virsh setvcpus k3s-worker2 3 --config

echo "=== VM cloning complete ==="
echo "Start your VMs with: sudo virsh start k3s-master"
echo "Connect to console: sudo virsh console k3s-master"
echo ""
echo "Next steps:"
echo "1. Start each VM and set unique hostnames"
echo "2. Configure static IPs on each VM"
echo "3. Run configure-master.sh on the master node"
echo "4. Run configure-worker.sh on each worker node"