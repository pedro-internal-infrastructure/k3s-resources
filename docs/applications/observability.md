# Observability — Kiali

This project includes **Kiali** for Istio service mesh visualization and observability.

---

## Overview

| Component  | ArgoCD App   | Namespace      | Version         | Wave | URL                  |
|------------|--------------|----------------|-----------------|------|----------------------|
| Kiali      | `kiali`      | `istio-system` | 2.7.0 (chart)   | 2    | `http://kiali.local` |

---

## Kiali

### Purpose

Kiali is the observability and management console for Istio. It provides:

- **Service graph** — visual topology of all services and their connections
- **Traffic metrics** — requests per second, error rates, latency percentiles
- **Health indicators** — per-service and per-workload health status
- **Istio config validation** — detects misconfigured VirtualServices, Gateways, etc.
- **Tracing integration** — supports Jaeger/Zipkin (not deployed in this project)

### ArgoCD Application

```yaml
name: kiali
source:
  repoURL: https://kiali.org/helm-charts
  chart: kiali-server
  targetRevision: 2.7.0
  helm:
    values: |
      auth:
        strategy: anonymous
      external_services:
        istio:
          root_namespace: istio-system
      deployment:
        accessible_namespaces:
          - "**"
destination:
  namespace: istio-system
syncOptions:
  - CreateNamespace=true
```

**Configuration explained:**

| Setting                          | Value                                                  | Reason                                                    |
|----------------------------------|--------------------------------------------------------|-----------------------------------------------------------|
| `auth.strategy`                  | `anonymous`                                            | No login required — open access for local dev            |
| `external_services.prometheus.url`| `http://prometheus-server.monitoring.svc.cluster.local`| Kiali reads metrics from this Prometheus instance        |
| `external_services.istio.root_namespace`| `istio-system`                                  | Tells Kiali where Istiod lives                           |
| `deployment.accessible_namespaces`| `["**"]`                                              | Kiali can see all namespaces                              |

### RBAC — ClusterRoleBinding

The file `k8s/kustomize/dashboard/admin-user.yml` creates a `ClusterRoleBinding` that grants the Kiali service account read access to all namespaces:

```yaml
kind: ClusterRoleBinding
metadata:
  name: kiali-viewer
roleRef:
  kind: ClusterRole
  name: view
subjects:
  - kind: ServiceAccount
    name: kiali
    namespace: istio-system
```

Without this binding, Kiali would only be able to see resources in `istio-system`.

### Accessing Kiali

**Via hostname (requires hosts-add):**

```
http://kiali.local
```

Requires `make hosts-add` to have been run, which adds `127.0.0.1 kiali.local` to `/etc/hosts`.

**Via VirtualService routing on localhost:**

The `dashboard/virtual-service.yml` (for local port-forward access) also routes `localhost` to Kiali on port 20001.

---

## Kustomize Structure

Both Prometheus and Kiali are managed from `k8s/kustomize/dashboard/`:

```
dashboard/
├── kustomization.yml     # References prometheus.yml, dashboard-app.yml, admin-user.yml
├── prometheus.yml        # ArgoCD Application for Prometheus
├── dashboard-app.yml     # ArgoCD Application for Kiali
├── admin-user.yml        # ClusterRoleBinding for Kiali
└── virtual-service.yml   # Istio VirtualService for Kiali (localhost routing)
```

---

## Troubleshooting

**Kiali not showing metrics:**
- Verify Prometheus is running: `kubectl get pods -n monitoring`
- Verify Prometheus URL is reachable from Kiali: `kubectl exec -n istio-system -l app=kiali -- curl -s http://prometheus-server.monitoring.svc.cluster.local/-/healthy`

**Kiali not showing service graph:**
- Confirm Istio sidecar injection is enabled on target namespaces
- Confirm traffic is flowing through the mesh (generate some requests)

**Kiali pod not starting:**
```bash
kubectl describe pod -n istio-system -l app=kiali
kubectl logs -n istio-system -l app=kiali -f
```

**kiali.local not resolving:**
```bash
make hosts-add
```

---

## Next Step

→ [Make Targets Reference](../operations/make-targets.md)
