# Adding Your Gaming PC as a GPU Node to k3s for Home MLOps

This guide walks through adding a host machine with an NVIDIA GPU to an existing k3s cluster. This setup is ideal for home MLOps workloads where you want to leverage your gaming PC's GPU for machine learning training while it also serves as the hypervisor for your k3s cluster VMs.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GAMING PC (Host)                         │
│                   NVIDIA RTX GPU                            │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ k3s-server  │  │ k3s-agent-1 │  │ k3s-agent-2         │ │
│  │ (VM)        │  │ (VM)        │  │ (VM)                │ │
│  │ Control     │  │ Worker      │  │ Worker              │ │
│  │ Plane       │  │             │  │                     │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
│                                                             │
│  + k3s-agent (running directly on host for GPU access)     │
└─────────────────────────────────────────────────────────────┘
```

In this architecture:
- **VMs** run the k3s control plane and worker nodes (no GPU access needed)
- **Host machine** joins as an additional k3s agent node with GPU access for ML workloads

## Prerequisites

- Existing k3s cluster (control plane accessible)
- NVIDIA GPU with proprietary drivers installed
- Ubuntu/Debian-based host (adjust package commands for other distros)

Verify your GPU and drivers:

```bash
nvidia-smi
```

Expected output shows your GPU model and driver version.

## Step 1: Install NVIDIA Container Toolkit

The NVIDIA Container Toolkit enables containers to access the GPU.

```bash
# Add NVIDIA container toolkit repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install the toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
```

Verify installation:

```bash
which nvidia-container-runtime
nvidia-container-runtime --version
```

## Step 2: Get the k3s Join Token

On your k3s control plane node, retrieve the agent join token:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Save this token for the next step.

## Step 3: Install k3s Agent on the Host

Install k3s as an agent node with a GPU label:

```bash
export K3S_TOKEN="<your-token-from-step-2>"
export K3S_URL="https://<control-plane-ip>:6443"

curl -sfL https://get.k3s.io | sh -s - agent \
  --server $K3S_URL \
  --token $K3S_TOKEN \
  --node-label gpu=true
```

If your host has multiple network interfaces (common when running VMs), specify the correct interface:

```bash
curl -sfL https://get.k3s.io | sh -s - agent \
  --server $K3S_URL \
  --token $K3S_TOKEN \
  --node-label gpu=true \
  --flannel-iface <interface-name>  # e.g., virbr1 for libvirt bridge
```

Verify the node joined:

```bash
kubectl get nodes --show-labels | grep gpu
```

## Step 4: Configure NVIDIA Runtime for k3s

k3s uses its own embedded containerd. We need to configure it to use the NVIDIA runtime.

First, configure the runtime:

```bash
sudo nvidia-ctk runtime configure --runtime=containerd \
  --config=/var/lib/rancher/k3s/agent/etc/containerd/config.toml
```

**Important:** k3s regenerates `config.toml` on restart. To make changes persistent, create a template file:

```bash
sudo tee /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl << 'EOF'
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
```

The critical configuration is:

```toml
[plugins.'io.containerd.cri.v1.runtime'.containerd]
  default_runtime_name = "nvidia"
```

This sets NVIDIA as the default runtime, which is required for the device plugin's auto-discovery to work.

Restart k3s-agent to apply:

```bash
sudo systemctl restart k3s-agent
```

## Step 5: Deploy NVIDIA Device Plugin

The device plugin exposes GPUs as schedulable resources in Kubernetes.

```bash
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.17.0/deployments/static/nvidia-device-plugin.yml
```

Restrict the daemonset to only run on GPU nodes:

```bash
kubectl patch daemonset nvidia-device-plugin-daemonset -n kube-system \
  --type=json \
  -p='[{"op": "add", "path": "/spec/template/spec/nodeSelector", "value": {"gpu": "true"}}]'
```

## Step 6: Verify GPU Access

Check the device plugin is running:

```bash
kubectl get pods -n kube-system | grep nvidia
```

Verify the GPU is exposed as a resource:

```bash
kubectl describe node <gpu-node-name> | grep nvidia.com/gpu
```

Expected output:

```
  nvidia.com/gpu:     1
  nvidia.com/gpu:     1
```

## Step 7: Test GPU Workload

Deploy a test pod to verify GPU access:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
spec:
  restartPolicy: Never
  nodeSelector:
    gpu: "true"
  containers:
  - name: cuda-test
    image: nvidia/cuda:12.0.0-base-ubuntu22.04
    command: ["nvidia-smi"]
    resources:
      limits:
        nvidia.com/gpu: 1
```

```bash
kubectl apply -f gpu-test.yaml
kubectl logs gpu-test
```

You should see the `nvidia-smi` output from inside the container.

## Troubleshooting

### Device Plugin Shows "No devices found"

This usually means the NVIDIA runtime isn't configured as the default:

1. Check the containerd config includes `default_runtime_name = "nvidia"`
2. Ensure you're using `config.toml.tmpl` (not `config.toml` directly)
3. Restart k3s-agent after changes

### Device Plugin CrashLoopBackOff on Non-GPU Nodes

Add a nodeSelector to restrict the daemonset:

```bash
kubectl patch daemonset nvidia-device-plugin-daemonset -n kube-system \
  --type=json \
  -p='[{"op": "add", "path": "/spec/template/spec/nodeSelector", "value": {"gpu": "true"}}]'
```

### k3s Agent Won't Start After Config Changes

Check for syntax errors in the template:

```bash
sudo journalctl -u k3s-agent -f
```

If needed, remove the template to revert to defaults:

```bash
sudo rm /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl
sudo systemctl restart k3s-agent
```

### Network Issues with VM Bridge

If your host runs VMs on a bridge network, ensure flannel uses the correct interface:

```bash
# In /etc/rancher/k3s/config.yaml
flannel-iface: virbr1  # or your bridge interface
```

## Summary

| Component | Purpose |
|-----------|---------|
| nvidia-container-toolkit | Enables container GPU access |
| nvidia-container-runtime | OCI runtime that injects GPU devices |
| config.toml.tmpl | Persistent containerd config for k3s |
| default_runtime_name = "nvidia" | Required for device plugin auto-discovery |
| nvidia-device-plugin | Exposes GPUs as Kubernetes resources |
| gpu=true label | Targets GPU workloads to the right node |

With this setup, you can now schedule ML training jobs, inference workloads, or any GPU-accelerated containers on your home k3s cluster using your gaming PC's GPU.
