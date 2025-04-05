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

## Notes

- The `flannel_iface` variable in the playbooks should match the network interface configured in your cloud-init templates (e.g., `ens3`).
- Ensure that the k3s-server.yaml playbook is run before the k3s-agent.yaml playbook, as the agents require the `node-token` from the server.

## Troubleshooting

- If a playbook fails, check the logs for detailed error messages.
- Ensure that the SSH key used for Ansible is valid and accessible.
- Verify that the `cloud-init` process has completed on all nodes before running the playbooks.

## References

- [Ansible Documentation](https://docs.ansible.com/)
- [K3s Documentation](https://k3s.io/)
