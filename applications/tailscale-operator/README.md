# Tailscale operator — tailnet HTTPS for cluster apps

Exposes cluster services on the tailnet at `*.tail4dd976.ts.net` with valid
HTTPS, so they're reachable from any tailnet device (e.g. the MacBook) without
public exposure.

## One-time setup in the Tailscale admin console (cannot be automated)

1. **DNS → Enable HTTPS** (`https://login.tailscale.com/admin/dns`). Required
   for `*.ts.net` certificate issuance. MagicDNS is already on.

2. **Add ACL tags** in the policy file
   (`https://login.tailscale.com/admin/acls`):
   ```jsonc
   "tagOwners": {
     "tag:k8s-operator": [],
     "tag:k8s":          ["tag:k8s-operator"],
   }
   ```

3. **Create an OAuth client**
   (`https://login.tailscale.com/admin/settings/oauth`):
   - Write scopes: **Devices Core**, **Auth Keys**, **Services**
   - Assign tag: **tag:k8s-operator**
   - Copy the client ID + secret into the `operator-oauth` secret
     (see `operator-oauth-secret.example.yaml`).

## Install order

```bash
# 1. OAuth secret (out-of-band, not in Git)
kubectl create namespace tailscale
kubectl create secret generic operator-oauth -n tailscale \
  --from-literal=client_id='<id>' --from-literal=client_secret='<secret>'

# 2. Let ArgoCD install the operator (or apply directly)
kubectl apply -f application.yaml
```

Verify: `kubectl get pods -n tailscale` shows `operator-...` Running, and a
`k8s-operator` device appears in the tailnet.
