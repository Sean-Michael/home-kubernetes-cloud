#!/usr/bin/env bash
# media-mode.sh — bring k3s back up.
#
# Starts the local k3s server; ArgoCD reconciles all workloads from Git,
# nothing else to do.
#
# Requires the sudoers drop-in (installed by migrate-standalone.sh, or run
# scripts/install-mode-switch.sh once with sudo).
set -uo pipefail

echo "=== spinning k3s up ==="

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
echo "Apps (once pods settle):"
echo "    ComfyUI     http://caliban:30188"
