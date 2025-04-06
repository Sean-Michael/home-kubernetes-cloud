[server]
k3s-server ansible_host=${server_ip} ansible_user=ubuntu

[agents]
%{ for i,ip in agent_ips ~}
k3s-agent-${i} ansible_host=${ip} ansible_user=ubuntu
%{ endfor ~}

[k3s_cluster:children]
server
agents