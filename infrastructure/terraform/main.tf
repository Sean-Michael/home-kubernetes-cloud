terraform {
    required_providers {
      libvirt = {
        source = "dmacvicar/libvirt"
        version = "~> 0.7.0"
      }
    }
}

provider "libvirt" {
    uri = "qemu:///system"
}

resource "libvirt_volume" "k8s_node_disk" {
    name = "k8s-node-disk"
    pool = "default"
    size = 21474836480
}

resource "libvirt_domain" "k8s_node" {
    name = "k8s-node1"
    memory = 4096
    vcpu = 2

    disk {
        volume_id = libvirt_volume.k8s_node_disk.id
    }

    network_interface {
        network_name = "default"
    }

    cloudinit = libvirt_cloudinit_disk.k8s_cloud_init.id
}

resource "libvirt_cloudinit_disk" "k8s_cloud_init" {
    name = "cloud-init-k8s.iso"
    pool = "default"
    user_data = <<EOF
hostname: k8s-node1
users:
    - name: ubuntu
    ssh-authorized-keys:
        - "${tls_private_key.k8s_ssh_key.public_key_openssh}"
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
EOF
}

resource "tls_private_key" "k8s_ssh_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "local_file" "private_key" {
    content = tls_private_key.k8s_ssh_key.private_key_pem
    filename = "${path.module}/k8s_ssh_key"
    file_permission = "0600"
}

resource "local_file" "public_key" {
    content = tls_private_key.k8s_ssh_key.public_key_openssh
    filename = "${path.module}/k8s_ssh_key.pub"
    file_permission = "0644"
}