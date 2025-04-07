# Home Lab: Kubernetes, IaC

## Overview

The Goal of this project is to learn more about Kubernetes by designing and building a home lab/cloud. **Because it's fun!**

## Status

This project is in active development, as I update features I'll try to keep the [to-do](https://github.com/Sean-Michael/home-kubernetes-cloud/tree/main/todo.md) list updated to track progress.

## Technologies

### [Terraform](https://github.com/Sean-Michael/home-kubernetes-cloud/tree/main/infrastructure/terraform)

I chose to use Terraform as my provisioning tool due to it's excellent ability to create immutable infrastructue.

This Infrastructure as Code defines and provisions some guests managed by a [KVM (Kernel-based Virtual Machine)](https://ubuntu.com/blog/kvm-hyphervisor) hypervizor. 

Terraform, uses the [libvirt](https://libvirt.org/) api to create all the necessary storage, network, and os image components to create our cluster! Well , at least provision the VMs that will be our cluster hosts. The configuration of them as K3s nodes is where Ansible comes in.

A more detailed description of the implementation is available in a seperate [README](https://github.com/Sean-Michael/home-kubernetes-cloud/tree/main/infrastructure/terraform/README.md).

### [Ansible](https://github.com/Sean-Michael/home-kubernetes-cloud/tree/main/infrastructure/ansible)

Ansible works very nicely alongside Terraform - both being agentless, free, and open-source. Since Terraform is immuatable in it's nature when we want to .. mutate our nodes we will do so with lovely Ansible playbooks. This is where apts will get updated and K3s will be installed.

### [Prometheus & Grafana](https://github.com/Sean-Michael/home-kubernetes-cloud/tree/main/platform/monitoring)

Prometheus is setup as a Helm Deployment to capture time-series data on our cluster! This is then fed into Grafana for dashboarding and visualization!

I also setup Hashicorp Vault for managing _secrets_ `:O`!