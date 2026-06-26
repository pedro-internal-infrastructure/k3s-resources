# DNS Server

AdGuard Home provides the cluster's local DNS service and a browser-based admin UI.

## Deployment

| Component | Value |
|---|---|
| Namespace | `dns` |
| Image | `adguard/adguardhome:v0.107.52` |
| ArgoCD app | `dns-server` |
| Manifests | `k8s/kustomize/dns-server/` |

The deployment stores AdGuard configuration and working data in two persistent volume claims:

| PVC | Size | Mount |
|---|---:|---|
| `adguardhome-conf` | 1Gi | `/opt/adguardhome/conf` |
| `adguardhome-work` | 5Gi | `/opt/adguardhome/work` |

## Access

| Endpoint | Purpose |
|---|---|
| `10.1.1.200:53` | DNS over TCP and UDP |
| `http://10.1.1.200` | AdGuard first-run/admin UI |
| `http://adguard.local` | AdGuard admin UI through Istio |

The external AdGuard service exposes only DNS on port 53. The admin UI is routed through the Istio ingress gateway on port 80 and accepts both the raw IP host header and `adguard.local`.

For `adguard.local`, run:

```bash
make hosts-add NODE_IP=10.1.1.200
```

## Verification

```bash
kubectl get pods,svc,pvc -n dns
kubectl get virtualservice -n istio-ingress dns-server
```
