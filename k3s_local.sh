#!/bin/bash
# This allows for manipulation of the cluster from you local dev machine.

mkdir -p ~/.kube

scp ubuntu@192.168.123.10:/etc/rancher/k3s/k3s.yaml ~/.kube/config

sed -i 's/127.0.0.1/192.168.123.10/g' ~/.kube/config

export KUBECONFIG=~/.kube/config