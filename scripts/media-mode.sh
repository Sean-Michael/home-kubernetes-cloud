#!/usr/bin/env bash
# media-mode.sh — bring the cluster (and the Plex stack) back up.
#
# Starts the libvirt network + VMs in dependency order, waits for the K3s
# API, then starts the local k3s agent. ArgoCD reconciles all workloads
# from Git; nothing else to do.
#
# Requires the sudoers drop-in from install-mode-switch.sh (one-time):
#   sudo ./scripts/install-mode-switch.sh
set -uo pipefail
export LIBVIRT_DEFAULT_URI=qemu:///system

SERVER_IP=192.168.123.10

echo "=== Media mode: spinning the cluster up ==="

echo "--- libvirt network"
virsh net-list | grep -q k3s_network || virsh net-start k3s_network

echo "--- the-rock (control plane)"
virsh domstate the-rock | grep -q running || virsh start the-rock >/dev/null

echo -n "--- waiting for K3s API at $SERVER_IP:6443 "
for _ in $(seq 60); do
    if timeout 2 bash -c "</dev/tcp/$SERVER_IP/6443" 2>/dev/null; then
        echo "— up"
        break
    fi
    echo -n "."
    sleep 5
done
if ! timeout 2 bash -c "</dev/tcp/$SERVER_IP/6443" 2>/dev/null; then
    echo ""
    echo "!! K3s API never came up; check 'virsh console the-rock'"
    exit 1
fi

echo "--- worker VMs"
for vm in deathwing-knight ravenwing-black-knight; do
    virsh domstate "$vm" | grep -q running || virsh start "$vm" >/dev/null
    echo "    $vm: running"
done

echo "--- k3s agent on caliban"
sudo -n systemctl start k3s-agent.service || {
    echo "!! Cannot start k3s-agent without a password prompt."
    echo "!! Run once:  sudo ./scripts/install-mode-switch.sh"
    exit 1
}

echo -n "--- waiting for caliban to be Ready "
for _ in $(seq 36); do
    if kubectl get node caliban 2>/dev/null | grep -q ' Ready'; then
        echo "— Ready"
        break
    fi
    echo -n "."
    sleep 5
done

echo ""
echo "=== Cluster status ==="
kubectl get nodes 2>/dev/null || echo "(kubectl not reachable yet — give it a minute)"
echo ""
echo "Media stack (once pods settle):"
echo "    Plex        http://caliban:32400/web"
echo "    Overseerr   http://caliban:30055"
echo "    Sonarr      http://caliban:30989"
echo "    Radarr      http://caliban:30878"
echo "    Prowlarr    http://caliban:30696"
echo "    qBittorrent http://caliban:30080"
echo "    Tautulli    http://caliban:30181"
