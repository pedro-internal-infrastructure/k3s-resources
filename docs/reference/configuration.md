# Configuration Reference

All configurable settings, variables, ports, and credentials used by this project.

---

## Makefile Variables

Defined in `make/vars.mk`. All can be overridden on the command line.

| Variable          | Default Value                                              | Description                                      |
|-------------------|------------------------------------------------------------|--------------------------------------------------|
| `NODE_IP`         | `127.0.0.1`                                                | IP address of the k3s node                       |
| `BOOTSTRAP_DIR`   | `$HOME/personal/k3s.install/k8s/bootstrap`                 | Path to bootstrap manifests                      |
| `APPS_DIR`        | `$HOME/personal/k3s.install/k8s/kustomize`                 | Path to app manifests                            |
| `ROOT_APP`        | `$HOME/personal/k3s.install/k8s/bootstrap/root-app.yml`    | Path to root ArgoCD Application manifest         |
| `DOMAINS_FILE`    | `$HOME/personal/k3s.install/config/domains`                | Path to domains file                             |
| `BIN`             | `k3s kubectl`                                              | kubectl binary to use                            |
| `NAMESPACE`       | `argocd`                                                   | ArgoCD namespace                                 |
| `HTTP_PORT`       | `30080`                                                    | ArgoCD NodePort HTTP port                        |
| `HTTPS_PORT`      | `30443`                                                    | ArgoCD NodePort HTTPS port (currently disabled)  |
| `K3S_INSTALL_URL` | `https://get.k3s.io`                                       | k3s installer URL                                |
| `K3S_UNINSTALL`   | `/usr/local/bin/k3s-uninstall.sh`                          | k3s uninstall script path                        |
| `K3S_SERVICE`     | `k3s`                                                      | systemd service name                             |

### Overriding Variables

Any variable with `?=` assignment can be overridden at the command line:

```bash
make k3s-setup NODE_IP=192.168.1.50
make hosts-add NODE_IP=192.168.1.50
```

---

## Ports

### Host-Level Ports

| Port  | Protocol | Service                    | How to reach                                |
|-------|----------|----------------------------|---------------------------------------------|
| 30080 | TCP/HTTP | ArgoCD UI                  | `http://localhost:30080`                    |
| 80    | TCP/HTTP | Istio ingress gateway      | Accessed via `localhost` or custom hostnames |
| 8080  | TCP/HTTP | ArgoCD (port-forward only) | `make port-forward` → `http://localhost:8080`|

### Cluster-Internal Ports

| Port  | Service             | DNS name                                            |
|-------|---------------------|-----------------------------------------------------|
| 20001 | Kiali               | `kiali.istio-system.svc.cluster.local`              |
| 80    | ArgoCD Server       | `argocd-server.argocd.svc.cluster.local`            |

---

## Default Credentials

> ⚠️ **Change all credentials before exposing any service to a network.**

| Service       | Username | Password         | How to change                                   |
|---------------|----------|------------------|-------------------------------------------------|
| ArgoCD        | `admin`  | auto-generated   | Use ArgoCD UI → User Info → Change Password     |
| Kiali         | —        | —                | Auth disabled (`auth.strategy: anonymous`)       |

---

## Component Versions

| Component      | Version   | Source                                            |
|----------------|-----------|---------------------------------------------------|
| k3s            | latest    | `https://get.k3s.io`                              |
| ArgoCD         | stable    | `https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml` |
| Istio          | 1.22.3    | `https://istio-release.storage.googleapis.com/charts` |
| Kiali          | 2.7.0     | `https://kiali.org/helm-charts`                   |

---

## ArgoCD Sync Waves

Sync waves control the order in which ArgoCD deploys Applications within a single sync operation:

| Wave | Application              | Reason                                         |
|------|--------------------------|------------------------------------------------|
| 1    | `istio-base`             | CRDs must exist before other Istio components  |
| 2    | `istiod`                 | Requires Istio CRDs                            |
| 3    | `istio-ingress`          | Requires istiod to be running                  |
| 4    | `istio-gateway-config`   | Requires ingress gateway pod to exist          |

---

## Local Domains

Defined in `config/domains`:

| Domain             | Resolves to (default) | Service               |
|--------------------|-----------------------|-----------------------|
| `argocd.local`     | `127.0.0.1`           | ArgoCD UI             |
| `kiali.local`      | `127.0.0.1`           | Kiali dashboard       |

Add new domains by appending a line to `config/domains`, then run `make hosts-add`.

---

## GitHub Repository

| Setting             | Value                                               |
|---------------------|-----------------------------------------------------|
| Repository URL      | `https://github.com/pedromota533/kubernetes-intro`  |
| ArgoCD source path  | `k8s/kustomize`                                     |
| Target revision     | `HEAD`                                              |

To use a fork, update all `repoURL` fields in:
- `k8s/bootstrap/root-app.yml`
- `k8s/kustomize/istio/gateway-config.yml`
