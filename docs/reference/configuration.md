# Configuration Reference

All configurable settings, variables, ports, and credentials used by this project.

---

## Makefile Variables

Defined in `make/vars.mk`. All can be overridden on the command line.

| Variable          | Default Value                                              | Description                                      |
|-------------------|------------------------------------------------------------|--------------------------------------------------|
| `REPO_ROOT`       | repository root                                            | Absolute path to this checkout                   |
| `NODE_IP`         | `127.0.0.1`                                                | IP address of the k3s node                       |
| `BOOTSTRAP_DIR`   | `$(REPO_ROOT)/k8s/bootstrap`                               | Path to bootstrap manifests                      |
| `APPS_DIR`        | `$(REPO_ROOT)/k8s/kustomize`                               | Path to app manifests                            |
| `ROOT_APP`        | `$(BOOTSTRAP_DIR)/root-app.yml`                            | Path to root ArgoCD Application manifest         |
| `DOMAINS_FILE`    | `$(REPO_ROOT)/config/domains`                              | Path to domains file                             |
| `LOGS_DIR`        | `$(REPO_ROOT)/logs`                                        | Path for command logs                            |
| `BIN`             | `k3s kubectl`                                              | kubectl binary to use                            |
| `ARGOCD_CLI`      | `$(REPO_ROOT)/bin/argocd`                                  | ArgoCD CLI binary path                           |
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
make install BOOTSTRAP_DIR=/opt/k8s/bootstrap
```

---

## Ports

### Host-Level Ports

| Port  | Protocol | Service                    | How to reach                                |
|-------|----------|----------------------------|---------------------------------------------|
| 30080 | TCP/HTTP | ArgoCD UI                  | `http://localhost:30080`                    |
| 80    | TCP/HTTP | Istio ingress gateway      | `http://10.1.1.200`, `http://adguard.local`, or other VirtualService hosts |
| 53    | TCP/UDP  | AdGuard Home DNS           | `10.1.1.200:53`                             |
| 8080  | TCP/HTTP | ArgoCD (port-forward only) | `make port-forward` → `http://localhost:8080`|

### Cluster-Internal Ports

| Port  | Service             | DNS name                                            |
|-------|---------------------|-----------------------------------------------------|
| 20001 | Kiali               | `kiali.istio-system.svc.cluster.local`              |
| 3000  | AdGuard Home        | `adguardhome.dns.svc.cluster.local`                 |
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
| AdGuard Home   | 0.107.52  | `adguard/adguardhome`                             |

---

## ArgoCD Sync Waves

Sync waves control the order in which ArgoCD deploys Applications within a single sync operation:

| Wave | Application              | Reason                                         |
|------|--------------------------|------------------------------------------------|
| 1    | `istio-base`             | CRDs must exist before other Istio components  |
| 2    | `istiod`                 | Requires Istio CRDs                            |
| 3    | `istio-ingress`          | Requires istiod to be running                  |
| 4    | `istio-gateway-config`   | Requires ingress gateway pod to exist          |
| 5    | `dns-server`             | Deploys after ingress and gateway config       |

---

## Local Domains

Defined in `config/domains`:

| Domain             | Resolves to (default) | Service               |
|--------------------|-----------------------|-----------------------|
| `argocd.local`     | `127.0.0.1`           | ArgoCD UI             |
| `kiali.local`      | `127.0.0.1`           | Kiali dashboard       |
| `adguard.local`   | `127.0.0.1`           | AdGuard Home admin UI |

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
