# Components

Detailed description of every component deployed by this project.

---

## k3s

**Namespace:** system-level (not a Kubernetes namespace)  
**Managed by:** `make` (systemd)

k3s is a lightweight, certified Kubernetes distribution by Rancher. It packages the entire Kubernetes control plane into a single binary and uses `containerd` as the container runtime. It replaces the standard `kube-apiserver`, `kube-scheduler`, and `kube-controller-manager` with a single optimized process.

Key differences from upstream Kubernetes:
- SQLite is used as the default backing store instead of etcd
- Traefik ingress is bundled (not used here — Istio is used instead)
- `kubectl` is embedded as `k3s kubectl`

In this project k3s is installed with:
```
--node-ip=<NODE_IP> --flannel-iface=eth1
```

---

## ArgoCD

**Namespace:** `argocd`  
**Exposed at:** `http://argocd.local` or `http://localhost/argocd`  
**Managed by:** Bootstrap (`make install`)

ArgoCD is the GitOps engine of this project. It continuously watches this Git repository and reconciles the cluster state to match what is defined in `k8s/kustomize/`.

### How it's configured

ArgoCD is installed in insecure mode (HTTP only) and exposed via Istio Gateway with dual access:

1. **Domain-based access:** `http://argocd.local` (requires `/etc/hosts` entry)
2. **Path-based access:** `http://localhost/argocd` (no hosts entry needed)

A VirtualService routes both paths to the ArgoCD server service.

### Root Application

The root Application (`lhs-argocd-apps`) is the entry point. It points to `k8s/kustomize/` and uses Kustomize to discover all child Application manifests. This creates an **App-of-Apps** pattern.

---

## Istio Service Mesh

**Namespace:** `istio-system` (control plane), `istio-ingress` (data plane)  
**Version:** 1.22.3  
**Managed by:** ArgoCD (sync waves 1–4)

Istio provides:
- **Service mesh** — mutual TLS between services in sidecar-injected namespaces
- **Ingress gateway** — a single entry point for all HTTP traffic into the cluster
- **Traffic management** — VirtualService and Gateway resources control routing

### Istio Components (in order of deployment)

| ArgoCD App           | Chart              | Wave | Purpose                               |
|----------------------|--------------------|------|---------------------------------------|
| `istio-base`         | `istio/base`       | 1    | CRDs (Gateway, VirtualService, etc.)  |
| `istiod`             | `istio/istiod`     | 2    | Pilot (control plane daemon)          |
| `istio-ingress`      | `istio/gateway`    | 3    | Ingress gateway pod in `istio-ingress`|
| `istio-gateway-config` | local Kustomize  | 4    | Gateway CR + VirtualServices          |

### Gateway Configuration

The Gateway listens on ports 80 (HTTP) and 443 (HTTPS) and accepts traffic for all hosts. VirtualServices route traffic based on hostname and URI path.
- `mongodb`

---

## Istio Gateway & Routing

**Namespace:** `istio-ingress`

The `http-gateway` Gateway resource listens on ports 80 (HTTP) and 443 (HTTPS) and accepts traffic for all hosts (`*`). VirtualService resources route traffic to backend services based on host or URI prefix.

**Gateway definition:**
```yaml
selector:
  istio: ingress
servers:
  - port: { number: 80, protocol: HTTP }
    hosts: ["*"]
  - port: { number: 443, protocol: HTTPS }
    tls: { mode: PASSTHROUGH }
    hosts: ["*"]
```

---

## Kiali

**Namespace:** `istio-system`  
**Version:** 2.7.0 (Helm chart)  
**Exposed at:** `http://kiali.local`  
**Auth:** Anonymous (no login required)  
**Managed by:** ArgoCD (sync wave 2)

Kiali is the observability dashboard for Istio. It provides:
- Service topology graph
- Traffic flow visualization
- Health and performance metrics
- Istio configuration validation

Kiali is configured with anonymous authentication and has read access to all namespaces via a `ClusterRoleBinding`.

---

## Next Step

→ [k3s Installation](../installation/k3s.md)
