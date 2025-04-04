#!/bin/bash
# create-base-vm.sh - Creates a base VM for K3s cluster nodes
# Usage: ./create-base-vm.sh [VM_NAME] [MEMORY_MB] [VCPUS] [DISK_GB]

set -e

# Default values
VM_NAME=${1:-"k3s-base"}
VM_PATH="/var/lib/libvirt/images/k3s-cluster"
MEMORY=${2:-4096}
VCPUS=${3:-2}
DISK_SIZE=${4:-20}
ISO_PATH="/data/ubuntu-24.04.2-live-server-amd64.iso"
ISO_URL="ubuntu-24.04.2-live-server-amd64.iso"

echo "=== Creating Base VM for K3s Cluster ==="
echo "VM Name: $VM_NAME"
echo "Memory: $MEMORY MB"
echo "vCPUs: $VCPUS"
echo "Disk Size: $DISK_SIZE GB"

# Download ISO if not exists
if [ ! -f "$ISO_PATH" ]; then
    echo "Downloading Ubuntu Server ISO..."
    wget "$ISO_URL" -O "$ISO_PATH"
fi

# Create VM
echo "Creating VM..."
sudo virt-install \
  --name "$VM_NAME" \
  --ram "$MEMORY" \
  --vcpus "$VCPUS" \
  --disk path="$VM_PATH/$VM_NAME.qcow2",size="$DISK_SIZE" \
  --network bridge=virbr0,model=virtio \
  --os-variant ubuntu24.04 \
  --graphics vnc,listen=0.0.0.0 \
  --noautoconsole \
  --cdrom "$ISO_PATH"

echo "VM creation initiated. Connect using:"
echo "virt-viewer --connect qemu:///system $VM_NAME"
echo ""
echo "VM is ready for post installation configuration"