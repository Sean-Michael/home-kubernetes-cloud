# Terraform Configuration for K3s Cluster

This directory contains the Terraform configuration files to provision my K3s cluster on a KVM/LibVirt environment.

## Overview

The Terraform configuration automates the creation of the following resources:

- A NAT-based virtual network for the cluster.
- A base Ubuntu image for the virtual machines.
- One master node and multiple worker nodes for the K3s cluster.
- Cloud-init configurations for initial VM setup.
- Ansible inventory file for further configuration.

## Prerequisites

Before using this configuration, ensure the following are installed on your system:

- [Terraform](https://www.terraform.io/downloads)
- [LibVirt](https://libvirt.org/)
- [QEMU](https://www.qemu.org/)
- [Ansible](https://www.ansible.com/)
- SSH key pair (default path: `~/.ssh/id_ed25519.pub`)

## Usage

1. **Initialize Terraform**:
   Run the following command to initialize the Terraform working directory:

   ```bash
   terraform init
   ```

2. **Customize Variables**:
   Edit the `main.tf` file or create a `terraform.tfvars` file to override default variables. For example:

   ```hcl
   agent_count = 3
   ssh_public_key_path = "~/.ssh/id_rsa.pub"
   ```

3. **Plan the Infrastructure**:
   Preview the changes Terraform will make:

   ```bash
   terraform plan
   ```

4. **Apply the Configuration**:
   Apply the configuration to create the resources:

   ```bash
   terraform apply
   ```

5. **Access the Ansible Inventory**:
   After applying, the Ansible inventory file will be generated at `../ansible/inventory/hosts.ini`.

## Outputs

The following outputs are generated:

- `server_ip`: The IP address of the K3s server node.
- `agent_ips`: The IP addresses of the K3s agent nodes.
- Ansible inventory file for further configuration.

## File Structure

```bash
terraform/
|-- README.md
|-- cloud_init.tpl
|-- inventory.tpl
|-- main.tf
|-- network_config.tpl
|-- outputs.tf
```

## Notes

- The base Ubuntu image is downloaded from the official Ubuntu cloud images repository.
- The virtual machines are configured with static IPs in the `192.168.123.0/24` subnet.
- Ensure the `libvirt` pool path (`/var/lib/libvirt/images/k3s-cluster`) exists and has sufficient storage.

## Cleanup

To destroy the created resources, run:

```bash
terraform destroy
```

## Troubleshooting

- If the `terraform apply` command fails, check the LibVirt logs for errors.
- Ensure the SSH key specified in `ssh_public_key_path` is valid and accessible.

## References

- [Terraform LibVirt Provider](https://github.com/dmacvicar/terraform-provider-libvirt)
- [K3s Documentation](https://k3s.io/)