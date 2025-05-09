# To-Do: Features to add & Bugs to fix

## Infrastructure

### Core Services

- [x] Setup host workstation as Hypervizor with KVM/Libvirt/QEMU.
- [x] Setup host workstation as Ansible Control node
- [x] Create Infrastructure as Code using Terraform to provision VMs.
- [x] Utilize Terraform templates to integrate with ansible, auto-updating inventory.
- [x] Create basic Ansible playbooks to configure VMs as k3s nodes using rancher
- [x] Create playbook to setup ssh/dns.
- [ ] Configure special node to utilize GPU resources through the Hypervizor
- [ ] Setup Ingress controllers
- [ ] Configure persistent storage
- [ ] Observability monitoring with Prometheus & Grafana
- [ ] Logging with ?

### Extension - Future learnings

- [ ] Utilize Packer with Terraform to create AWS machine images?
- [ ] More advanced Ansible plays and Terraform configurations.
- [ ] Add additionaly baremetal hosts for on-prem enviroment.
- [ ] Configure simple ethernet switch for communication between baremetal hosts.
- [ ] Integrate with AWS Resources - maybe offload control plane to create a hybrid cloud.

## Container Orchestration

### Core Services

- [x] Setup Kubernetes cluster using k3s: server (control-plane) + 2 agents.
- [ ] Setup Relational Database (Postgres?)
- [ ] Utilize Helm charts for package deployment.
- [ ] Implement ArgoCD GitOps.

### Extension - Future learnings

- [ ] Implement K8s
- [ ] Container Scanning

## Applications

### Core Apps

- [ ] Minecraft and other Game Servers
- [ ] Deploy my personal website (revamped).
- [ ] Deploy Amie's personal website.
- [ ] Add CI/CD with self-hosted GitHub runners
- [ ] Deploy ML Workflows.

### Extension - Future learnings

- [ ] Multiplayer GoLang Chess server/client.
