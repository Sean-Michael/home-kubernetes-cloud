#!/usr/bin/env bash
# migrate-standalone.sh — one-time migration: caliban k3s agent -> standalone server.
#
# The VM cluster (the-rock + knights) is retired; caliban becomes a single-node
# k3s server. VM disks and the Terraform/Ansible code are kept so the VM
# cluster can be resurrected if ever needed.
#
# This script does ONLY the root-required steps:
#   1. uninstall the old k3s agent
#   2. install k3s server (pinned to the version the cluster already runs)
#   3. restore the nvidia containerd runtime config
#   4. update the mode-switch sudoers drop-in for k3s.service
#   5. hand the kubeconfig to smr
#
# Afterwards run (as smr):  ./scripts/bootstrap-cluster.sh
#
# Usage: sudo ./scripts/migrate-standalone.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo $0"
    exit 1
fi

K3S_VERSION="v1.33.6+k3s1"   # match the version the VM cluster ran; upgrade separately
TMPL_DIR=/var/lib/rancher/k3s/agent/etc/containerd
TMPL=$TMPL_DIR/config.toml.tmpl
SAVED_TMPL=""

echo "=== 1/5 Uninstalling old k3s agent ==="
if [ -f "$TMPL" ]; then
    SAVED_TMPL=$(mktemp)
    cp "$TMPL" "$SAVED_TMPL"
    echo "    saved existing containerd nvidia template"
fi
if [ -x /usr/local/bin/k3s-agent-uninstall.sh ]; then
    /usr/local/bin/k3s-agent-uninstall.sh
else
    echo "    (agent already uninstalled)"
fi

echo "=== 2/5 Installing k3s server $K3S_VERSION ==="
curl -sfL https://get.k3s.io | \
    INSTALL_K3S_VERSION="$K3S_VERSION" \
    INSTALL_K3S_SKIP_START=true \
    sh -s - server \
        --disable=traefik \
        --node-label gpu=true \
        --tls-san caliban \
        --tls-san 100.91.243.56

echo "=== 3/5 Restoring nvidia containerd runtime config ==="
mkdir -p "$TMPL_DIR"
if [ -n "$SAVED_TMPL" ]; then
    cp "$SAVED_TMPL" "$TMPL"
else
    # Canonical template from docs/adding-gpu-node-to-k3s.md — nvidia as the
    # DEFAULT runtime so pods get the GPU via NVIDIA_VISIBLE_DEVICES alone.
    cat > "$TMPL" <<'EOF'
version = 3
root = "/var/lib/rancher/k3s/agent/containerd"
state = "/run/k3s/containerd"

[grpc]
  address = "/run/k3s/containerd/containerd.sock"

[plugins.'io.containerd.internal.v1.opt']
  path = "/var/lib/rancher/k3s/agent/containerd"

[plugins.'io.containerd.grpc.v1.cri']
  stream_server_address = "127.0.0.1"
  stream_server_port = "10010"

[plugins.'io.containerd.cri.v1.runtime']
  enable_selinux = false
  enable_unprivileged_ports = true
  enable_unprivileged_icmp = true
  device_ownership_from_security_context = false

[plugins.'io.containerd.cri.v1.images']
  snapshotter = "overlayfs"
  disable_snapshot_annotations = true
  use_local_image_pull = true

[plugins.'io.containerd.cri.v1.images'.pinned_images]
  sandbox = "rancher/mirrored-pause:3.6"

[plugins.'io.containerd.cri.v1.runtime'.cni]
  bin_dirs = ["/var/lib/rancher/k3s/data/cni"]
  conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d"

[plugins.'io.containerd.cri.v1.runtime'.containerd]
  default_runtime_name = "nvidia"

[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"

[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
  SystemdCgroup = true

[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.'nvidia']
  runtime_type = "io.containerd.runc.v2"

[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.'nvidia'.options]
  BinaryName = "/usr/bin/nvidia-container-runtime"
  SystemdCgroup = true

[plugins.'io.containerd.cri.v1.images'.registry]
  config_path = "/var/lib/rancher/k3s/agent/etc/containerd/certs.d"
EOF
fi
systemctl enable --now k3s

echo "=== 4/5 Updating mode-switch sudoers for k3s.service ==="
cat > /etc/sudoers.d/k3s-mode-switch <<'EOF'
# Allow the desktop user to flip caliban between game mode and media mode
# (see scripts/game-mode.sh / media-mode.sh in home-kubernetes-cloud).
smr ALL=(root) NOPASSWD: /usr/bin/systemctl start k3s.service, /usr/bin/systemctl stop k3s.service, /usr/local/bin/k3s-killall.sh
EOF
chmod 0440 /etc/sudoers.d/k3s-mode-switch
visudo -c -f /etc/sudoers.d/k3s-mode-switch >/dev/null

echo "=== 5/5 Handing kubeconfig to smr ==="
mkdir -p /home/smr/.kube
[ -f /home/smr/.kube/config ] && cp /home/smr/.kube/config /home/smr/.kube/config.the-rock.bak
until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 2; done
cp /etc/rancher/k3s/k3s.yaml /home/smr/.kube/config
chown -R smr:smr /home/smr/.kube
chmod 600 /home/smr/.kube/config

echo ""
echo "Done. k3s server is starting. Now run as smr:"
echo "    ./scripts/bootstrap-cluster.sh"
