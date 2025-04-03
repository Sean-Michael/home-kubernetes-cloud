 # home-kubernetes-cloud
## Overview
The Goal of this project is to learn more about Kubernetes by designing and building a home cloud. Because it's fun, and I want to deploy my own apps and servers. 

## Project Structure:
home-kubernetes-cloud/
├── infrastructure/
│   ├── local/
│   │   ├── storage/
│   │   │   └── local-storage.yaml
│   │   ├── networking/
│   │   │   └── metallb-config.yaml
│   │   └── setup-scripts/
│   │       └── local-k3s-install.sh
│   ├── aws/
│   │   ├── eks/
│   │   │   └── cluster-config.yaml
│   │   └── networking/
│   │       └── vpn-config.yaml
│   └── hybrid/
│       ├── connectivity/
│       │   └── cilium-config.yaml
│       └── dns/
│           └── coredns-custom.yaml
├── platform/
│   ├── namespaces/
│   │   ├── core-services.yaml
│   │   ├── applications.yaml
│   │   └── ml-workloads.yaml
│   ├── monitoring/
│   │   ├── prometheus-values.yaml
│   │   └── grafana-dashboards/
│   │       ├── cluster-overview.json
│   │       └── application-metrics.json
│   └── security/
│       ├── network-policies.yaml
│       └── resource-quotas.yaml
├── applications/
│   ├── game-servers/
│   │   ├── minecraft/
│   │   │   └── deployment.yaml
│   │   └── tf2/
│   │       └── deployment.yaml
│   ├── web-apps/
│   │   └── example-web-app.yaml
│   └── ml-workflows/
│       └── example-ml-pipeline.yaml
└── docs/
    ├── architecture.md
    ├── getting-started.md
    └── deployment-guides/
        ├── game-server-guide.md
        └── web-app-guide.md
