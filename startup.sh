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

echo "=== k3s_server (control plane) === "
if ! sudo virsh list | grep "k3s_server"; then
    sudo virsh start k3s_server
    echo "Server VM started."
else
    echo "Server VM already running."
fi

sleep 30

echo "=== k3s_agent-0 ==="
if ! sudo virsh list | grep "k3s_agent-0"; then 
    sudo virsh start k3s_agent-0
    echo "k3s_agent-0 started."
else
    echo "k3s_agent-0 already running."
fi

echo "=== k3s_agent-1 ==="
if ! sudo virsh list | grep "k3s_agent-1"; then 
    sudo virsh start k3s_agent-1
    echo "k3s_agent-1 started."
else
    echo "k3s_agent-1 already running."
fi

echo ""
echo "=== K3s Cluster Status ==="
sudo virsh list