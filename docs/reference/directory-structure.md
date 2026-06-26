# Directory Structure

Complete annotated layout of the repository.

---

```
k3s.install/
│
├── Makefile                          # Entry point — includes all make/ modules
│
├── README.md                         # Project overview and quick start
│
├── config/
│   └── domains                       # List of local hostnames to add to /etc/hosts
│
├── k8s/
│   │
│   ├── bootstrap/                    # ArgoCD bootstrap (applied once by `make install`)
│   │   ├── kustomization.yml         # Kustomize overlay: installs ArgoCD with patches
│   │   ├── namespace.yml             # Creates the `argocd` namespace
│   │   ├── NodePort.yml              # Patch: exposes ArgoCD via NodePort 30080
│   │   ├── argocd-insecure.yml       # Patch: disables TLS on ArgoCD server
│   │   └── root-app.yml             # ArgoCD root Application (App-of-Apps pattern)
│   │
│   └── kustomize/                    # All application manifests (managed by ArgoCD)
│       │
│       ├── kustomization.yml         # Root kustomize: includes child ArgoCD apps
│       ├── dns-server.yml            # App: deploys AdGuard Home DNS server (wave 5)
│       │
│       └── istio/                    # Istio service mesh (ArgoCD Applications)
│           ├── kustomization.yml
│           ├── base.yml              # App: installs istio-base CRDs (wave 1)
│           ├── istiod.yml            # App: installs istiod control plane (wave 2)
│           ├── ingress-gateway.yml   # App: installs Istio ingress gateway (wave 3)
│           └── gateway-config.yml    # App: applies gateway-config/ (wave 4)
│       
│       └── gateway-config/           # Istio Gateway CR + VirtualServices
│           ├── kustomization.yml
│           ├── namespace.yml         # Creates istio-ingress namespace
│           ├── gateway.yml           # Gateway: http-gateway on ports 80 and 443
│           ├── kiali-vs.yml          # VirtualService: kiali.local → Kiali
│           ├── argocd-vs.yml         # VirtualService: argocd.local + /argocd → ArgoCD
│           └── dns-vs.yml            # VirtualService: dns.local → AdGuard Home
│
│       └── dns-server/               # AdGuard Home Kubernetes manifests
│           ├── kustomization.yml
│           ├── namespace.yml         # Creates dns namespace
│           ├── pvc.yml               # Persistent config and work volumes
│           ├── deployment.yml        # AdGuard Home deployment
│           └── service.yml           # DNS and admin UI services
│
├── make/                             # Makefile modules (included by Makefile)
│   ├── vars.mk                       # All variables (paths, ports, colors)
│   ├── help.mk                       # `make help` output
│   ├── k3s.mk                        # k3s install/start/stop/delete targets
│   ├── argocd.mk                     # ArgoCD install/link/unlink/status targets
│   ├── hosts.mk                      # /etc/hosts management targets
│   └── cleanup.mk                    # nuke-apps, prune-apps, ghcr-secret targets
│
├── logs/                             # Runtime logs (not committed to Git)
│   ├── k3s-setup.log                 # Output of `make k3s-setup`
│   ├── install.log                   # Output of `make install`
│   └── port-forward.log             # Output of `make port-forward`
│
└── docs/                             # Project documentation
    ├── getting-started/
    │   ├── prerequisites.md          # System requirements
    │   └── quickstart.md             # Step-by-step setup guide
    ├── architecture/
    │   ├── overview.md               # GitOps flow, namespace layout, sync waves
    │   └── components.md             # Detailed description of every component
    ├── installation/
    │   ├── k3s.md                    # k3s setup and management
    │   └── argocd.md                 # ArgoCD installation and configuration
    ├── applications/
    │   ├── istio.md                  # Istio service mesh deep dive
    │   ├── observability.md          # Kiali observability
    │   └── dns-server.md             # AdGuard Home DNS server
    ├── operations/
    │   ├── make-targets.md           # All make targets with examples
    │   └── hosts.md                  # /etc/hosts domain management
    └── reference/
        ├── directory-structure.md    # This file
        └── configuration.md          # Variables, ports, and configurable settings
```

---

## Key Design Decisions

### `k8s/bootstrap/` vs `k8s/kustomize/`

- **`bootstrap/`** is applied manually once via `make install`. It installs ArgoCD itself, which is a prerequisite for everything else. It is not managed by ArgoCD.
- **`kustomize/`** is managed entirely by ArgoCD. After `make link`, ArgoCD takes ownership and syncs this directory automatically.

### Makefile Modules

The `Makefile` is split into focused modules in `make/` to keep each concern separate and maintainable. The root `Makefile` simply includes them all.

### Logs Directory

The `logs/` directory is created at runtime (by the `Logs:` target in `vars.mk`) when needed. It is not tracked in Git. Log files capture the full output of long-running commands for debugging.
