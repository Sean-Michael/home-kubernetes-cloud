# Home Cloud Architecture
## Overview

This document describes the architectual design of the K3s cluster running on KVM/LibVirt virtual machines.

## On-Prem Physical Infrastructure
### Workstation Host:
* OS: Ubuntu 24.04.2 LTS
* CPU:Intel(R) Core(TM) i7-5930K CPU @ 3.50GHz
* RAM: 64GB DDR4 3200
* GPU: NVIDIA GeForce RTX2070 Super 8GB

## Virtual Infrastructure
The cluster is comprised of 3 virtual machines:
* 1 master node (control plane)
* 2 worker nodes

