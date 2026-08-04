#!/usr/bin/env bash
# media-mode.sh — bring k3s (and the Plex stack) back up.
#
# Starts the local k3s server; ArgoCD reconciles all workloads from Git,
# nothing else to do.
#
# Requires the sudoers drop-in (installed by migrate-standalone.sh, or run
# scripts/install-mode-switch.sh once with sudo).
set -uo pipefail

echo "=== Media mode: spinning k3s up ==="

sudo -n systemctl start k3s.service || {
    echo "!! Cannot start k3s without a password prompt."
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
