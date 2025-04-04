# VM Specifications for K3s Cluster

This document outlines the specifications for virtual machines in our K3s cluster.

## Base VM

- **Purpose**: Template for creating other VMs
- **OS**: Ubuntu Server 24.02 LTS
- **RAM**: 4GB
- **vCPUs**: 2
- **Storage**: 20GB
- **Network**: Bridge (virbr0)

## Master Node (Control Plane)

- **Hostname**: k3s-master
- **IP Address**: 192.168.123.10 (Static)
- **RAM**: 6GB
- **vCPUs**: 2
- **Storage**: 20GB
- **Purpose**: Runs the Kubernetes control plane including API server, scheduler, controller manager
- **Notes**: Lower CPU requirement but needs sufficient RAM for control plane components

## Worker Node 1

- **Hostname**: k3s-worker1
- **IP Address**: 192.168.123.11 (Static)
- **RAM**: 8GB
- **vCPUs**: 3
- **Storage**: 20GB
- **Purpose**: Runs application workloads

## Worker Node 2

- **Hostname**: k3s-worker2
- **IP Address**: 192.168.123.12 (Static)
- **RAM**: 8GB
- **vCPUs**: 3
- **Storage**: 20GB
- **Purpose**: Runs application workloads

## Network Configuration

- **Network Name**: k3s-network
- **Network Type**: NAT with fixed IPs
- **CIDR**: 192.168.123.0/24
- **Gateway**: 192.168.123.1

## Storage Configuration

All nodes use local storage with the possibility to configure:
- NFS shared storage
- Longhorn distributed storage (after cluster setup)