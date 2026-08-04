#!/usr/bin/env bash
# bootstrap-cluster.sh — rebuild the whole platform on a fresh cluster from Git.
#
# Idempotent. Installs ArgoCD via Helm (chicken-and-egg: ArgoCD can't deploy
# itself onto an empty cluster), applies the pre-GitOps secrets, then applies
# every ArgoCD Application; ArgoCD reconciles the rest from GitHub.
#
# Usage: ./scripts/bootstrap-cluster.sh [backup-dir]
#   backup-dir: exported state from the old cluster (default: newest under
#               /data/cluster-backup) — used for the tailscale oauth secret
#               and the pgvector database restore.
set -euo pipefail
cd "$(dirname "$0")/.."
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

BACKUP_DIR="${1:-$(ls -d /data/cluster-backup/*/ 2>/dev/null | sort | tail -1)}"
echo "Using backup dir: ${BACKUP_DIR:-<none>}"

echo "=== Waiting for node ==="
kubectl wait --for=condition=Ready node/caliban --timeout=300s

echo "=== Installing ArgoCD (helm bootstrap, then self-managed from Git) ==="
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update argo >/dev/null
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
# Our values keep configs.secret.createSecret=false (so neither helm nor the
# self-managed Application ever fights ArgoCD over this secret's contents),
# which means a fresh cluster needs the empty secret pre-created — argocd-server
# populates its signing key and admin password into it on first boot.
kubectl create secret generic argocd-secret -n argocd 2>/dev/null || true
helm upgrade --install argocd argo/argo-cd -n argocd \
    --version 9.1.8 -f applications/argocd/values.yaml --wait --timeout 10m

echo "=== Pre-GitOps secrets ==="
kubectl create namespace tailscale --dry-run=client -o yaml | kubectl apply -f -
if [ -n "${BACKUP_DIR:-}" ] && [ -f "$BACKUP_DIR/tailscale-operator-oauth.yaml" ]; then
    kubectl apply -f "$BACKUP_DIR/tailscale-operator-oauth.yaml"
else
    echo "!! No tailscale operator-oauth backup found — create it manually"
    echo "!! (see applications/tailscale-operator/operator-oauth-secret.example.yaml)"
fi
if [ -f secrets/grafana_passwd.txt ]; then
    ./applications/kube-prometheus-stack/create_secret.sh "$(cat secrets/grafana_passwd.txt)"
else
    echo "!! secrets/grafana_passwd.txt missing — grafana admin secret not created"
fi

echo "=== Applying ArgoCD Applications (dependency order) ==="
apply() { kubectl apply -f "$1"; }
apply applications/argocd/application.yaml            # self-management adoption
apply applications/gateway-api/application.yaml
apply applications/istio/1-base-application.yaml
apply applications/istio/2-istiod-application.yaml
apply applications/istio/3-cni-application.yaml
apply applications/istio/4-ztunnel-application.yaml
apply applications/istio/5-ambient-namespaces-application.yaml
apply applications/tailscale-operator/application.yaml
apply applications/nvidia-device-plugin/application.yaml
apply applications/cloudnativepg/application.yaml
apply applications/kube-prometheus-stack/application.yaml
apply applications/harbor/harbor.yaml
apply applications/KubeRay/kuberay-operator.yaml
apply applications/gateway-routes/application.yaml
apply applications/media/application.yaml

echo "=== Waiting for CNPG operator, then creating pgvector cluster ==="
if kubectl wait --for=condition=Available deploy/cnpg-cloudnative-pg -n cnpg-system --timeout=600s 2>/dev/null \
   || kubectl wait --for=condition=Available deploy -l app.kubernetes.io/name=cloudnative-pg -n cnpg-system --timeout=600s 2>/dev/null; then
    kubectl apply -f applications/cloudnativepg/pgvector-cluster-application.yaml
else
    echo "!! CNPG operator not ready — apply pgvector-cluster-application.yaml once it is"
fi

echo "=== Restoring pgvector data (best-effort) ==="
if [ -n "${BACKUP_DIR:-}" ] && [ -f "$BACKUP_DIR/pgvector-dumpall.sql" ]; then
    if kubectl wait --for=condition=Ready pod/pgvector-1 -n cnpg-system --timeout=900s 2>/dev/null; then
        kubectl exec -i -n cnpg-system pgvector-1 -c postgres -- psql -U postgres \
            < "$BACKUP_DIR/pgvector-dumpall.sql" > /tmp/pgvector-restore.log 2>&1 \
            && echo "    restored (log: /tmp/pgvector-restore.log)" \
            || echo "!! restore had errors — see /tmp/pgvector-restore.log"
    else
        echo "!! pgvector-1 never came up; restore manually:"
        echo "   kubectl exec -i -n cnpg-system pgvector-1 -c postgres -- psql -U postgres < $BACKUP_DIR/pgvector-dumpall.sql"
    fi
fi

echo ""
echo "=== Bootstrap complete — ArgoCD reconciles the rest ==="
kubectl get applications -n argocd
