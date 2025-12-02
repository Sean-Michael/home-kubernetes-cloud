#!/bin/bash
# startup.sh - Script to bring down K3s Cluster VMs
# Usage: sudo ./shutdown.sh

echo "=== Shutting down K3s Cluster ==="

echo "=== k3s_network ==="
if sudo virsh net-list --all | grep "k3s_network"; then
    sudo virsh net-destroy k3s_network
    echo "Stopping 'k3s_network'"
    exit 1
fi

echo "=== k3s_server (control plane) === "
if sudo virsh list | grep "k3s_server"; then
    sudo virsh shutdown k3s_server
    echo "Server VM shutdown."
else
    echo "Server VM already shutdown."
fi

echo "=== k3s_agent-0 === "
if sudo virsh list | grep "k3s_agent-0"; then
    sudo virsh shutdown k3s_agent-0
    echo "Agent-0 VM shutdown."
else
    echo "Agent-0 VM already shutdown."
fi

echo "=== k3s_agent-1 === "
if sudo virsh list | grep "k3s_agent-1"; then
    sudo virsh shutdown k3s_agent-1
    echo "Agent-1 VM shutdown."
else
    echo "Agent-1 VM already shutdown."
fi