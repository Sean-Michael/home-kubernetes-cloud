output "server_ip" {
  description = "IP address of the K3s server node"
  value       = "192.168.123.10"
}

output "agent_ips" {
  description = "IP addresses of the K3s agent nodes"
  value       = [for i in range(var.agent_count) : "192.168.123.${i + 11}"]
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl",
    {
      server_ip  = "192.168.123.10"
      agent_ips  = [for i in range(var.agent_count) : "192.168.123.${i + 11}"]
    }
  )
  filename = "${path.module}/../ansible/inventory/hosts.ini"
}