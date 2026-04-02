#!/bin/bash
# startup.sh - Script to start K3s cluster VMs in order
# Usage: sudo ./startup.sh

echo "=== Starting K3s Cluster ==="

echo "=== k3s_network ==="
if ! sudo virsh net-list --all | grep "k3s_network"; then
    echo "Error: Network 'k3s_network' not found!"
    exit 1
fi

if ! sudo virsh net-list | grep "k3s_network"; then
    sudo virsh net-start k3s_network
    echo "- k3s_network started."
else 
    echo "- k3s_network already running."
fi

echo "=== the-rock (control plane) === "
if ! sudo virsh list | grep "the-rock"; then
    sudo virsh start the-rock
    echo "the-rock started."
else
    echo "the-rock already running."
fi

sleep 30

echo "=== deathwing-knight ==="
if ! sudo virsh list | grep "deathwing-knight"; then
    sudo virsh start deathwing-knight
    echo "deathwing-knight started."
else
    echo "deathwing-knight already running."
fi

echo "=== ravenwing-black-knight ==="
if ! sudo virsh list | grep "ravenwing-black-knight"; then
    sudo virsh start ravenwing-black-knight
    echo "ravenwing-black-knight started."
else
    echo "ravenwing-black-knight already running."
fi

echo ""
echo "=== K3s Cluster Status ==="
sudo virsh list