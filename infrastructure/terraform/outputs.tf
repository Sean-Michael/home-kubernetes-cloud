output "server_ip" {
  description = "IP address of the K3s server node"
  value       = libvirt_domain.k3s_server.network_interface[0].addresses[0]
}

output "agent_ips" {
  description = "IP addresses of the K3s agent nodes"
  value       = libvirt_domain.k3s_agent[*].network_interface[0].addresses[0]
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl",
    {
      server_ip  = libvirt_domain.k3s_server.network_interface[0].addresses[0]
      agent_ips  = libvirt_domain.k3s_agent[*].network_interface[0].addresses[0]
    }
  )
  filename = "${path.module}/../ansible/inventory/hosts.ini"
}