# Ansible Configuration for K3s Cluster

This directory contains the Ansible playbooks and inventory files to configure and manage the K3s cluster.

## Overview

The Ansible configuration automates the following tasks:

- Configuring the K3s server node.
- Configuring K3s agent nodes.
- Uninstalling K3s from the cluster.
- Managing the cluster using an inventory file.

## File Structure

```bash
ansible/
|-- README.md
|-- inventory
|   `-- hosts.ini
|-- playbooks
|   |-- k3s-agent.yaml
|   |-- k3s-server.yaml
|   `-- uninstall-k3s.yaml
|-- roles
`-- site.yaml                
```

## Prerequisites

Before running the playbooks, ensure the following:

- Ansible is installed on your control machine. If not, (deb)
  - `sudo apt install ansible`
- The inventory file (`inventory/hosts.ini`) is updated with the correct IP addresses of the server and agent nodes.
  - This was provided by [Terraform](https://github.com/Sean-Michael/home-kubernetes-cloud/tree/main/infrastructure/terraform)
- SSH access is configured for the `ubuntu` user on all nodes.
  - Also should have been done through [Terraform](https://github.com/Sean-Michael/home-kubernetes-cloud/tree/main/infrastructure/terraform)

## Usage

1. **Update the Inventory File**:
   Edit the `inventory/hosts.ini` file to include the IP addresses of your server and agent nodes if you don't like what Terraform gave you or you simply didn't use it. For example:

   ```ini
   [server]
   192.168.123.10 ansible_user=ubuntu

   [agents]
   192.168.123.11 ansible_user=ubuntu
   192.168.123.12 ansible_user=ubuntu

   [k3s_cluster:children]
   server
   agents
   ```

2. **Run the Playbooks**:
   Use the `site.yaml` file to run all playbooks or run individual playbooks as needed.

   - To configure the K3s server and agents:

     ```bash
     ansible-playbook -i inventory/hosts.ini site.yaml
     ```

   - To configure only the K3s server:

     ```bash
     ansible-playbook -i inventory/hosts.ini playbooks/k3s-server.yaml
     ```

   - To configure only the K3s agents:

     ```bash
     ansible-playbook -i inventory/hosts.ini playbooks/k3s-agent.yaml
     ```

   - To uninstall K3s from all nodes:
     - >If you are like me and tend to break things this is useful for getting a fresh start.

     ```bash
     ansible-playbook -i inventory/hosts.ini playbooks/uninstall-k3s.yaml
     ```

## Playbook Details

### k3s-server.yaml

- Configures the K3s server node.
- Installs K3s with the `--disable=traefik` flag.
- Exposes the `node-token` and `kubeconfig` for agent nodes to join the cluster.

### k3s-agent.yaml

- Configures the K3s agent nodes.
- Joins the agents to the K3s cluster using the `node-token` and server IP.

### uninstall-k3s.yaml

- Uninstalls K3s from all nodes (server and agents).
- Removes K3s-related directories and files.

### k3s-gpu-agent.yaml

- Configures a GPU-enabled worker node to join the K3s cluster.
- Ensures that NVIDIA drivers and the NVIDIA Container Toolkit are installed and properly configured.
- Installs the K3s agent with GPU-specific configurations, including enabling Kubernetes `DevicePlugins` and labeling the node with `gpu=true`.

#### Prerequisites for GPU Nodes

- NVIDIA GPU drivers must be installed and functional on the host machine.
- The `nvidia-container-toolkit` must be installed to enable GPU support in containers.

#### Usage

To configure a GPU-enabled worker node, run the following command:

```bash
ansible-playbook -i inventory/hosts.ini [k3s-gpu-agent.yaml](http://_vscodecontentref_/0)
```

Here’s an updated section for your README to document the GPU-enabled worker node playbook:

```markdown
### k3s-gpu-agent.yaml

- Configures a GPU-enabled worker node to join the K3s cluster.
- Ensures that NVIDIA drivers and the NVIDIA Container Toolkit are installed and properly configured.
- Installs the K3s agent with GPU-specific configurations, including enabling Kubernetes `DevicePlugins` and labeling the node with `gpu=true`.

#### Prerequisites for GPU Nodes
- NVIDIA GPU drivers must be installed and functional on the host machine.
- The `nvidia-container-toolkit` must be installed to enable GPU support in containers.

#### Usage
To configure a GPU-enabled worker node, run the following command:
```bash
ansible-playbook -i inventory/hosts.ini k3s-gpu-agent.yaml
```

#### Key Features

- Verifies that NVIDIA drivers are installed using `nvidia-smi`. If not, the playbook will fail with an appropriate error message.
- Adds the NVIDIA Container Toolkit repository and installs the required packages.
- Configures the NVIDIA Container Toolkit for use with `containerd`.
- Installs the K3s agent with GPU-specific configurations, including:
  - Setting the `--node-label="gpu=true"` flag to label the node as GPU-enabled.
  - Enabling the `DevicePlugins` feature gate in Kubernetes.
- Restarts `containerd` if the NVIDIA Container Toolkit configuration changes.

## Notes

- The `flannel_iface` variable in the playbooks should match the network interface configured in your cloud-init templates (e.g., `ens3`).
- Ensure that the k3s-server.yaml playbook is run before the k3s-agent.yaml playbook, as the agents require the `node-token` from the server.
- Ensure that the `flannel_iface` variable matches the network interface used by the node (e.g., `virbr1`).
- The playbook uses the `K3S_URL` and `K3S_TOKEN` environment variables to connect the GPU node to the K3s server. These values must be correctly set in the inventory or group variables.
- Temporary files, such as the K3s installation script, are cleaned up after the playbook completes.

## References

- [Ansible Documentation](https://docs.ansible.com/)
- [K3s Documentation](https://k3s.io/)
