# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal home lab / "home cloud": a K3s cluster running on KVM/libvirt VMs on a single
workstation, plus a Tailscale-joined bare-metal node. Infrastructure is provisioned with
Terraform, configured with Ansible, and workloads are deployed via ArgoCD GitOps. The repo
is the source of truth — ArgoCD `Application` manifests point back at this repo.

There is no application build/test/lint pipeline here; "running" the project means
provisioning infrastructure and applying manifests to the cluster.

## Cluster topology (standalone, since 2026-08)

The VM cluster is **retired**: caliban (the workstation itself, NVIDIA RTX 2070 Super,
labeled `gpu=true`) now runs a single-node K3s **server** installed with
`--disable=traefik`. It doubles as the living-room gaming PC — see game/media mode below.

- Migration entrypoints: `scripts/migrate-standalone.sh` (root steps: agent→server,
  nvidia containerd template, sudoers) then `scripts/bootstrap-cluster.sh` (helm-installs
  ArgoCD, applies pre-GitOps secrets + every `Application`; Git does the rest). The
  bootstrap script is the canonical dependency-ordered list of Applications — rerun it
  any time on a fresh cluster.
- **thonkpad** (`100.105.11.113`) — old laptop, joinable as a bare-metal agent over
  **Tailscale** (`flannel-iface=tailscale0`); server URL is caliban's tailnet IP
  `100.91.243.56` (a `--tls-san`). Not currently joined.
- Pre-GitOps state a fresh cluster needs: the `operator-oauth` tailscale secret and the
  grafana admin secret — both handled by `bootstrap-cluster.sh` from
  `/data/cluster-backup/` and `secrets/`.

### Retired VM cluster (kept as code)

`infrastructure/terraform` + `infrastructure/ansible` still fully describe the old
KVM/libvirt cluster (the-rock `.10` control plane, deathwing-knight/ravenwing-black-knight
agents on NAT `192.168.123.0/24`, caliban joined as GPU agent). VM disks were kept;
`scripts/startup.sh` boots them again if ever needed. The last VM-cluster state (pgvector
dump, secrets, Application specs) is backed up under `/data/cluster-backup/`.

```bash
# (retired path) Provision VMs
cd infrastructure/terraform && terraform init && terraform apply
# (retired path) Configure VMs as K3s nodes
cd ../ansible && ansible-playbook -i inventory/hosts.ini site.yaml
```

## Game mode / media mode

Caliban doubles as the living-room gaming PC. `scripts/game-mode.sh` stops k3s and kills
its containers (frees GPU/RAM); `scripts/media-mode.sh` starts k3s again and ArgoCD
re-reconciles everything from Git. Passwordless flipping needs the sudoers drop-in
(installed by `migrate-standalone.sh`, or `sudo scripts/install-mode-switch.sh`, which
also adds desktop launchers). Media-stack state is all hostPath under `/data`, so mode
flips are lossless.

## GitOps with ArgoCD (`applications/`)

Each subdirectory is an ArgoCD-managed workload. Apps are not auto-discovered by an
app-of-apps root — each `Application` manifest is applied to the cluster (typically
`kubectl apply -f`), after which ArgoCD self-heals/prunes from Git.

Two patterns appear in the `Application` specs:

- **Upstream Helm chart**, optionally with values from this repo via a second
  `source`/`$values` reference (see `applications/harbor/harbor.yaml`,
  `applications/cloudnativepg/application.yaml`).
- **Raw manifests from this repo**, with `repoURL` = this repo, `targetRevision: HEAD`,
  and a `path`/`directory.include` selecting specific files (see
  `pgvector-cluster-application.yaml` pulling in `pgvector.yaml`).

When a CRD's spec is mutated by its operator (e.g. CNPG `Cluster`), the Application uses
`ignoreDifferences` + `RespectIgnoreDifferences` so ArgoCD doesn't fight the operator.
Most apps run with `automated: { prune: true, selfHeal: true }` and `CreateNamespace=true`.

Notable apps: `kube-prometheus-stack` (monitoring/Grafana, with DCGM GPU metrics),
`cloudnativepg` (Postgres operator + `pgvector` cluster for RAG), `KubeRay`, `harbor`
(private registry for pushing custom images), `vllm`/`home-mlops` (ML inference/training),
`media` (Plex + Sonarr/Radarr/Prowlarr/qBittorrent/Overseerr/Tautulli pinned to caliban,
hostPath state under `/data`, Plex on hostNetwork :32400 with NVENC — see its README).

## Submodules

`applications/dbaas` and `applications/home-mlops` are git submodules (separate repos —
see `.gitmodules`). Run `git submodule update --init --recursive` before working on them.
The `infrastructure/ansible/playbooks/roles/dbaas/` role builds and deploys the dbaas app.

## Gotchas

- `secrets/`, `terraform.tfvars`, `terraform.tfstate*`, and `infrastructure/terraform/passwd`
  are gitignored. `group_vars/gpu_nodes/vault.yaml` holds Ansible-vault secrets.
- Terraform state is local (no remote backend) — destroying state loses VM tracking.
- The README's documented topology ("2 worker nodes") is stale; trust `hosts.ini` for the
  current node list.
