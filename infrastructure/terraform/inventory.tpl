[server]
${server_ip} ansible_user=ubuntu

[agents]
%{ for ip in agent_ips ~}
${ip} ansible_user=ubuntu
%{ endfor ~}

[k3s_cluster:children]
server
agents