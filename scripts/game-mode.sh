#!/usr/bin/env bash
# game-mode.sh — free caliban for couch gaming.
#
# Stops the local k3s agent, kills its workload containers (releases GPU,
# RAM, and CPU held by Plex & friends), then shuts down the cluster VMs.
# All media-stack state lives on /data hostPaths, so this is always safe;
# media-mode.sh brings everything back and ArgoCD re-reconciles.
#
# Requires the sudoers drop-in from install-mode-switch.sh (one-time):
#   sudo ./scripts/install-mode-switch.sh
set -uo pipefail
export LIBVIRT_DEFAULT_URI=qemu:///system

VMS=(ravenwing-black-knight deathwing-knight the-rock)

echo "=== Game mode: spinning the cluster down ==="

echo "--- Stopping k3s agent on caliban"
sudo -n systemctl stop k3s-agent.service || {
    echo "!! Cannot stop k3s-agent without a password prompt."
    echo "!! Run once:  sudo ./scripts/install-mode-switch.sh"
    exit 1
}

echo "--- Killing leftover workload containers (frees GPU/RAM)"
sudo -n /usr/local/bin/k3s-killall.sh >/dev/null 2>&1 || true

echo "--- Shutting down cluster VMs"
for vm in "${VMS[@]}"; do
    if virsh domstate "$vm" 2>/dev/null | grep -q running; then
        virsh shutdown "$vm" >/dev/null
        echo "    $vm: shutdown requested"
    else
        echo "    $vm: already off"
    fi
done

# Give ACPI shutdown up to 60s, then hard-stop stragglers.
for _ in $(seq 12); do
    running=$(virsh list --name | grep -c . || true)
    [ "$running" -eq 0 ] && break
    sleep 5
done
for vm in "${VMS[@]}"; do
    if virsh domstate "$vm" 2>/dev/null | grep -q running; then
        echo "    $vm: forcing off"
        virsh destroy "$vm" >/dev/null
    fi
done

echo ""
echo "=== Game on. GPU and RAM are yours. ==="
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null | sed 's/^/    GPU memory: /'
echo "    (run ./scripts/media-mode.sh when you're done)"
