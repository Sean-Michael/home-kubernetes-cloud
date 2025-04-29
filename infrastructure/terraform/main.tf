terraform {
    required_providers {
      libvirt = {
        source = "dmacvicar/libvirt"
        version = "0.7.1"
      }
    }
}

provider "libvirt" {
    uri = "qemu:///system"
}

variable "agent_count" {
    description = "Number of K3s agent nodes"
    type = number
    default = 2
}

resource "libvirt_pool" "k3s_cluster" {
    name = "k3s_cluster"
    type = "dir"
    path = "/var/lib/libvirt/images/k3s-cluster"

}

resource "libvirt_network" "k3s_network" {
    name = "k3s_network"
    mode = "nat"
    domain = "k3s.local"
    addresses = ["192.168.123.0/24"]

    dns {
        enabled = true
    }
}

resource "libvirt_volume" "ubuntu_base" {
    name = "ubuntu_base"
    pool = libvirt_pool.k3s_cluster.name
    source = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
    format = "qcow2"

}

resource "libvirt_volume" "k3s_server" {
    name = "k3s_server.qcow2"
    base_volume_id = libvirt_volume.ubuntu_base.id 
    pool = libvirt_pool.k3s_cluster.name
    size = 21474836480    # 20GB
}

resource "libvirt_volume" "k3s_agent" {
    count = var.agent_count
    name = "k3s_agent_${count.index}.qcow2"
    base_volume_id = libvirt_volume.ubuntu_base.id 
    pool = libvirt_pool.k3s_cluster.name
    size = 21474836480  # 20GB
}

variable "ssh_public_key_path" {
    description = "Path to SSH public key"
    type = string
    default = "~/.ssh/id_ed25519.pub"
}

resource "libvirt_cloudinit_disk" "server_cloudinit" {
    name = "server-cloudinit.iso"
    pool = libvirt_pool.k3s_cluster.name
    user_data = templatefile("${path.module}/cloud_init.tpl", {
        hostname = "k3s-server"
        ssh_key = file(var.ssh_public_key_path)
    })
    network_config = templatefile("${path.module}/network_config.tpl", {
        ip_address = "192.168.123.10"
        gateway = "192.168.123.1"
    })
}

resource "libvirt_cloudinit_disk" "agent_cloudinit" {
    count = var.agent_count
    pool = libvirt_pool.k3s_cluster.name
    name = "agent-${count.index}-cloudinit.iso"
    user_data = templatefile("${path.module}/cloud_init.tpl", {
        hostname = "k3s-agent-${count.index}"
        ssh_key = file(var.ssh_public_key_path)
    })
    network_config = templatefile("${path.module}/network_config.tpl", {
        ip_address = "192.168.123.${count.index + 11}"
        gateway = "192.168.123.1"
    })
}

resource "libvirt_domain" "k3s_server" {
    name = "k3s_server"
    description = "server k3s node"
    memory = "6144" # 6GB
    vcpu = 2

    cloudinit = libvirt_cloudinit_disk.server_cloudinit.id 

    network_interface {
        network_id = libvirt_network.k3s_network.id 
        addresses = ["192.168.123.10"]
    }

    disk {
        volume_id = libvirt_volume.k3s_server.id
    }

    console {
        type        = "pty"
        target_type = "serial"
        target_port = "0"
    }

    graphics {
        type        = "spice"
        listen_type = "address"
        autoport    = true
    }
}

resource "libvirt_domain" "k3s_agent" {
    count = var.agent_count
    name = "k3s_agent-${count.index}"
    description = "agent k3s node"
    memory = "4096" # 4GB
    vcpu = 1
    
    cloudinit = libvirt_cloudinit_disk.agent_cloudinit[count.index].id

    network_interface {
        network_id = libvirt_network.k3s_network.id 
        addresses = ["192.168.123.${count.index + 11}"]
    }

    disk {
        volume_id = libvirt_volume.k3s_agent[count.index].id
    }

    console {
        type        = "pty"
        target_type = "serial"
        target_port = "0"
    }

    graphics {
        type        = "spice"
        listen_type = "address"
        autoport    = true
    }
}