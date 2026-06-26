# kubernetes-intro

> A local Kubernetes homelab built on **k3s** with **ArgoCD** GitOps and **Istio** service mesh — all managed through a single `Makefile`.

---

## Overview

This project provisions a fully functional Kubernetes cluster on a local machine using k3s (lightweight Kubernetes). All applications are deployed and kept in sync automatically by ArgoCD following the GitOps pattern — the cluster state is defined entirely in this repository.

| Component      | Purpose                                      | Version     |
|----------------|----------------------------------------------|-------------|
| k3s            | Lightweight Kubernetes distribution          | latest      |
| ArgoCD         | GitOps continuous delivery                   | stable      |
| Istio          | Service mesh & traffic management            | 1.22.3      |
| Kiali          | Istio observability dashboard                | 2.7.0       |
| AdGuard Home   | Local DNS server and DNS admin UI            | 0.107.52    |

---

## Quick Start

```bash
# 1. Install k3s
make k3s-setup

# 2. Enable and start k3s
make k3s-enable && make k3s-start

# 3. Install ArgoCD
make install

# 4. Link ArgoCD to this repository (GitOps)
make link

# 5. Add local domains to /etc/hosts
make hosts-add

# 6. Get the ArgoCD admin password
make password
```

After step 4, ArgoCD will automatically sync and deploy all applications defined in `k8s/kustomize/`.

---

## Documentation

| Section | Description |
|---|---|
| [Getting Started](docs/getting-started/prerequisites.md) | Requirements and initial setup |
| [Quickstart Guide](docs/getting-started/quickstart.md) | Step-by-step from zero to running cluster |
| [Architecture Overview](docs/architecture/overview.md) | High-level design and GitOps flow |
| [Components](docs/architecture/components.md) | All deployed components explained |
| [k3s Installation](docs/installation/k3s.md) | k3s setup and management |
| [ArgoCD Installation](docs/installation/argocd.md) | ArgoCD bootstrap and configuration |
| [Istio](docs/applications/istio.md) | Service mesh installation and gateway config |
| [Observability](docs/applications/observability.md) | Kiali observability setup |
| [Make Targets](docs/operations/make-targets.md) | Full reference of all `make` commands |
| [Hosts Management](docs/operations/hosts.md) | Local DNS via /etc/hosts |
| [Directory Structure](docs/reference/directory-structure.md) | Repository layout explained |
| [Configuration Reference](docs/reference/configuration.md) | Variables, ports, and settings |

---

## Repository Layout

```
.
├── Makefile                  # Entry point — all operations
├── config/
│   └── domains               # Local domain definitions
├── k8s/
│   ├── bootstrap/            # ArgoCD installation manifests
│   └── kustomize/            # All application manifests (GitOps)
│       ├── istio/            # Istio service mesh
│       └── gateway-config/   # Istio Gateway + VirtualServices
├── make/                     # Makefile modules
│   ├── vars.mk               # Variables
│   ├── k3s.mk                # k3s targets
│   ├── argocd.mk             # ArgoCD targets
│   ├── hosts.mk              # /etc/hosts management
│   ├── cleanup.mk            # Cleanup utilities
│   └── help.mk               # Help output
└── logs/                     # Operation logs (gitignored)
```

---

## Accessing Services

Once running, services are available at:

| Service       | URL                               | Credentials            |
|---------------|-----------------------------------|------------------------|
| ArgoCD        | `http://argocd.local`             | `admin` / see `make password` |
| ArgoCD (alt)  | `http://localhost/argocd`         | `admin` / see `make password` |
| Kiali         | `http://kiali.local`              | anonymous              |
| DNS server    | `http://dns.local` or `http://10.1.1.200:443` | create during AdGuard setup |

**Note:** ArgoCD is accessible two ways:
- Via domain: `http://argocd.local` (requires entry in `/etc/hosts`)
- Via path: `http://localhost/argocd` (no hosts entry needed)

AdGuard Home provides DNS on `10.1.1.200:53` and the first-run admin UI on `10.1.1.200:443`.

---

## License

MIT
