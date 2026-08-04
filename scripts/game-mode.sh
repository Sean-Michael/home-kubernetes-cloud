#!/usr/bin/env bash
# game-mode.sh — free caliban for couch gaming.
#
# Stops the local k3s server and kills its workload containers, releasing the
# GPU, RAM, and CPU held by the platform (Plex & friends included). All media
# state is on /data hostPaths, so this is always safe; media-mode.sh brings
# everything back and ArgoCD re-reconciles from Git.
#
# Requires the sudoers drop-in (installed by migrate-standalone.sh, or run
# scripts/install-mode-switch.sh once with sudo).
set -uo pipefail

echo "=== Game mode: spinning k3s down ==="

sudo -n systemctl stop k3s.service || {
    echo "!! Cannot stop k3s without a password prompt."
    echo "!! Run once:  sudo ./scripts/install-mode-switch.sh"
    exit 1
}
echo "--- k3s stopped"

echo "--- Killing workload containers (frees GPU/RAM)"
sudo -n /usr/local/bin/k3s-killall.sh >/dev/null 2>&1 || true

echo ""
echo "=== Game on. GPU and RAM are yours. ==="
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null | sed 's/^/    GPU memory: /'
echo "    (run ./scripts/media-mode.sh when you're done)"
