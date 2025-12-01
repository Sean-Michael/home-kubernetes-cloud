#!/bin/bash
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic grafana-admin-credentials \
  --namespace monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="${1:?Usage: $0 <password>}" \
  --dry-run=client -o yaml | kubectl apply -f -
