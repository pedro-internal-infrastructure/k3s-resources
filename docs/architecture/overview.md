# Architecture Overview

## Design Philosophy

This project follows the **GitOps** pattern: the Git repository is the single source of truth for the cluster state. No manual `kubectl apply` commands are needed after the initial bootstrap. ArgoCD continuously reconciles the cluster against the repository.

---

## High-Level Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│                        Local Machine                              │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    k3s Cluster                              │  │
│  │                                                             │  │
│  │  ┌──────────┐   watches    ┌─────────────────────────────┐  │  │
│  │  │  ArgoCD  │ ──────────► │  GitHub Repository          │  │  │
│  │  │          │             │  k8s/kustomize/              │  │  │
│  │  └──────────┘             └─────────────────────────────┘  │  │
│  │       │ deploys                                             │  │
│  │       ▼                                                     │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │  │
│  │  │  Istio   │  │  GitLab  │  │ MongoDB  │  │  Kiali   │   │  │
│  │  │  (mesh)  │  │   CE     │  │+ Express │  │+Prometheus│   │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │  │
│  │       │                                                     │  │
│  │  ┌──────────────────────────────────────────────────────┐   │  │
│  │  │          Istio Ingress Gateway (:80)                 │   │  │
│  │  │     routes traffic via VirtualService rules          │   │  │
│  │  └──────────────────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                            ▲                                      │
│                     make / kubectl                                 │
│                       (operator)                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## GitOps Flow

```
Developer                  Git Repository              ArgoCD                  Cluster
    │                           │                         │                       │
    │  git push (manifest)      │                         │                       │
    │──────────────────────────►│                         │                       │
    │                           │  polls every 3 minutes  │                       │
    │                           │◄────────────────────────│                       │
    │                           │                         │                       │
    │                           │  detects diff           │                       │
    │                           │────────────────────────►│                       │
    │                           │                         │  kubectl apply        │
    │                           │                         │──────────────────────►│
    │                           │                         │                       │
    │                           │                         │  resource created/    │
    │                           │                         │  updated/deleted      │
```

1. A developer pushes Kubernetes manifests to the `main` branch of this repository.
2. ArgoCD polls GitHub periodically and detects the difference between the desired state (Git) and the live state (cluster).
3. ArgoCD applies the changes to the cluster automatically.

---

## Bootstrap vs GitOps

There is a clear separation between the **bootstrap phase** (one-time, manual) and the **GitOps phase** (ongoing, automatic):

| Phase      | What runs it | What it manages                         |
|------------|--------------|------------------------------------------|
| Bootstrap  | `make`        | k3s install, ArgoCD namespace + install, root Application |
| GitOps     | ArgoCD        | Everything under `k8s/kustomize/`        |

---

## Sync Wave Order

ArgoCD Applications use **sync waves** to control deployment order. This ensures dependencies are ready before dependent applications start:

| Wave | Application         | Reason                                    |
|------|---------------------|-------------------------------------------|
| 1    | `istio-base`        | Installs Istio CRDs first                 |
| 2    | `istiod`            | Control plane depends on CRDs             |
| 3    | `istio-ingress`     | Gateway depends on istiod                 |
| 4    | `istio-gateway-config` | Gateway CRs depend on the gateway pod  |
| 5    | `dns-server`        | Deploys AdGuard Home after ingress config |

---

## Traffic Routing

All HTTP traffic enters the cluster through the **Istio Ingress Gateway** on ports 80 (HTTP) and 443 (HTTPS). VirtualService resources route traffic to backend services based on host or URI prefix:

```
http://argocd.local             → argocd-server.argocd.svc.cluster.local:80
http://localhost/argocd         → argocd-server.argocd.svc.cluster.local:80
http://kiali.local              → kiali.istio-system.svc.cluster.local:20001
http://dns.local                → adguardhome.dns.svc.cluster.local:3000
```

---

## Namespace Layout

| Namespace            | Contents                                      |
|----------------------|-----------------------------------------------|
| `argocd`             | ArgoCD server, repo-server, application-controller |
| `istio-system`       | istiod, Kiali                                 |
| `istio-ingress`      | Istio ingress gateway pod, Gateway CR         |
| `dns`                | AdGuard Home DNS server                       |

---

## Next Step

→ [Components](components.md)
