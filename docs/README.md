# Documentation

Complete documentation for the `kubernetes-intro` project — a local Kubernetes homelab built on k3s with ArgoCD GitOps and Istio service mesh.

---

## Table of Contents

### 🚀 Getting Started
| Document | Description |
|---|---|
| [Prerequisites](getting-started/prerequisites.md) | Hardware, software, and network requirements |
| [Quickstart Guide](getting-started/quickstart.md) | Step-by-step: from zero to a running cluster |

### 🏗️ Architecture
| Document | Description |
|---|---|
| [Overview](architecture/overview.md) | GitOps flow, sync waves, namespace layout, traffic routing |
| [Components](architecture/components.md) | Every deployed component described in detail |

### ⚙️ Installation
| Document | Description |
|---|---|
| [k3s](installation/k3s.md) | Installing, starting, stopping, and removing k3s |
| [ArgoCD](installation/argocd.md) | Bootstrapping ArgoCD and linking it to the repository |

### 📦 Applications
| Document | Description |
|---|---|
| [Istio](applications/istio.md) | Service mesh, ingress gateway, and VirtualService routing |
| [Observability](applications/observability.md) | Kiali observability and service graph |
| [DNS Server](applications/dns-server.md) | AdGuard Home DNS service and admin UI |

### 🔧 Operations
| Document | Description |
|---|---|
| [Make Targets](operations/make-targets.md) | Full reference of all `make` commands with examples |
| [Hosts Management](operations/hosts.md) | Managing local DNS entries via /etc/hosts |

### 📖 Reference
| Document | Description |
|---|---|
| [Directory Structure](reference/directory-structure.md) | Annotated repository layout |
| [Configuration Reference](reference/configuration.md) | All variables, ports, credentials, and versions |

---

## Quick Links

- **ArgoCD UI (domain):** `http://argocd.local`
- **ArgoCD UI (path):** `http://localhost/argocd`
- **Kiali:** `http://kiali.local`
- **DNS server:** `http://adguard.local` or `http://10.1.1.200`
- **Get ArgoCD password:** `make password`
- **See all make targets:** `make help`
