# Prerequisites

Before setting up the cluster, ensure your system meets the following requirements.

---

## Operating System

- **Linux** (Ubuntu 22.04 LTS or later recommended)
- A user account with `sudo` privileges
- systemd-based init system (required for k3s service management)

---

## Hardware Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU      | 2 cores | 4+ cores    |
| RAM      | 4 GB    | 8+ GB       |
| Disk     | 20 GB   | 40+ GB      |

> **Note:** GitLab alone requests a minimum of 2 GiB RAM and 500m CPU. Running the full stack (k3s + Istio + GitLab + MongoDB + Kiali + Prometheus) requires at least 8 GB RAM for a comfortable experience.

---

## Required Tools

These tools must be installed before running any `make` commands:

| Tool     | Purpose                          | Install                                |
|----------|----------------------------------|----------------------------------------|
| `make`   | Task runner (Makefile)           | `sudo apt install make`               |
| `curl`   | Download k3s installer           | `sudo apt install curl`               |
| `sudo`   | Privilege escalation             | Included in most Linux distributions  |

> `kubectl` is bundled with k3s and available as `k3s kubectl`. No separate installation needed.

---

## Network Requirements

- Port **30080** must be free (ArgoCD NodePort HTTP)
- Port **30443** must be free (ArgoCD NodePort HTTPS, currently disabled)
- Port **80** must be reachable for Istio ingress routing
- The machine must have outbound internet access to pull container images

---

## GitHub Repository Access

This project uses the public repository `https://github.com/pedromota533/kubernetes-intro` as the ArgoCD source. ArgoCD will pull manifests directly from GitHub. No authentication is required for a public repository.

If you fork the repository, update the `repoURL` fields in:
- `k8s/bootstrap/root-app.yml`
- `k8s/kustomize/istio/gateway-config.yml`
- `k8s/kustomize/istio/mongodb.yml`
- `k8s/kustomize/gitlab/application.yml`

---

## Optional: GHCR Credentials

If you plan to use private Helm charts hosted on GitHub Container Registry (ghcr.io), you will need:
- A GitHub username (`GHCR_USER`)
- A GitHub Personal Access Token with `read:packages` scope (`GHCR_TOKEN`)

These are used with the `make ghcr-secret` target.

---

## Next Step

→ [Quickstart Guide](quickstart.md)
