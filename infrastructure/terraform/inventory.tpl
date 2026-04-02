[server]
the-rock ansible_host=${server_ip} ansible_user=ubuntu

[agents]
deathwing-knight ansible_host=${agent_ips[0]} ansible_user=ubuntu
ravenwing-black-knight ansible_host=${agent_ips[1]} ansible_user=ubuntu
caliban ansible_host=127.0.0.1 ansible_connection=local

[gpu_nodes]
caliban ansible_host=127.0.0.1 ansible_connection=local

[k3s_cluster:children]
server
agents