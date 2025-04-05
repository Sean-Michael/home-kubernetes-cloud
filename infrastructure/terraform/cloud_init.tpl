#cloud-config
hostname: ${hostname}
manage_etc_hosts: true
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_key}
package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent
  - python3
  - python3-pip
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent