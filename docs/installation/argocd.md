# ArgoCD Installation & Configuration

ArgoCD is the GitOps engine that manages all applications in this cluster. It is bootstrapped manually once and then manages itself and all other applications.

---

## Install ArgoCD

```bash
make install
```

**What it does:**

Applies the Kustomize overlay at `k8s/bootstrap/` to the cluster using server-side apply:

```bash
kubectl apply --server-side --force-conflicts -k k8s/bootstrap/
```

The bootstrap Kustomize configuration (`k8s/bootstrap/kustomization.yml`) does three things:

1. **Creates the `argocd` namespace** via `namespace.yml`
2. **Installs ArgoCD** from the official stable manifests at:
   `https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
3. **Applies two patches:**

   | Patch File           | What It Changes                                           |
   |----------------------|-----------------------------------------------------------|
   | `NodePort.yml`       | Exposes ArgoCD on NodePort 30080 (HTTP)                   |
   | `argocd-insecure.yml`| Sets `server.insecure: "true"` — disables TLS redirection |

Install logs are written to `logs/install.log`.

---

## Access the UI

Once installed:

```
http://localhost:30080
```

Username: `admin`  
Password: run `make password`

---

## Get the Admin Password

```bash
make password
```

Decodes the base64-encoded password from the Kubernetes secret:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

> **Security note:** Change this password after first login in production environments.

---

## Link ArgoCD to the Repository (GitOps)

```bash
make link
```

Applies `k8s/bootstrap/root-app.yml`, creating the root ArgoCD Application named `lhs-argocd-apps`.

**Root Application spec:**

| Field            | Value                                          |
|------------------|------------------------------------------------|
| Source repo      | `https://github.com/pedromota533/kubernetes-intro` |
| Source path      | `k8s/kustomize`                                |
| Target revision  | `HEAD`                                         |
| Destination      | `https://kubernetes.default.svc`               |
| Destination NS   | `argocd`                                       |

Once linked, ArgoCD discovers all `Application` resources defined in `k8s/kustomize/` and deploys them. This is the **App-of-Apps** pattern.

---

## Unlink ArgoCD

```bash
make unlink
```

Deletes the root Application. ArgoCD stops syncing but existing resources remain in the cluster.

---

## Port-Forward (alternative access)

If NodePort is not available:

```bash
make port-forward
```

Starts a background port-forward from `localhost:8080` to the ArgoCD server service. Logs go to `logs/port-forward.log`.

Then access: `http://localhost:8080`

---

## Cluster Status

```bash
make status   # show all resources in the argocd namespace
make pods     # show pods across all namespaces
```

---

## Deploy / Remove Kustomize Apps Manually

In most cases ArgoCD handles this. If you need manual control:

```bash
make deploy-apps    # kubectl apply -k k8s/kustomize/
make remove-apps    # kubectl delete -k k8s/kustomize/ --ignore-not-found
```

---

## Uninstall ArgoCD

```bash
make uninstall
```

This is a three-step safe uninstall:

1. **Remove finalizers** from the root Application and all Applications — prevents deletion from hanging.
2. **Delete the root Application** and all Applications.
3. **Delete the ArgoCD installation** using `kubectl delete -k k8s/bootstrap/`.

---

## Clean Up Leftover Namespaces

After uninstalling, some namespaces may be stuck due to Istio finalizers:

```bash
make prune-apps
```

This strips finalizers from all resources in the following namespaces, then deletes them:
- `triggerdev`
- `istio-system`
- `istio-ingress`
- `monitoring`
- `kubernetes-dashboard`

---

## Delete All ArgoCD Applications (Emergency)

```bash
make nuke-apps
```

Immediately deletes all ArgoCD `Application` resources without finalizer cleanup. Use this only if `uninstall` is stuck.

---

## GHCR Secret (Private Helm Charts)

To allow ArgoCD to pull Helm charts from `ghcr.io`:

```bash
make ghcr-secret GHCR_USER=<github-username> GHCR_TOKEN=<github-pat>
```

Creates a secret named `ghcr-triggerdev-charts` in the `argocd` namespace with the `argocd.argoproj.io/secret-type=repository` label, which ArgoCD uses to authenticate OCI chart pulls.

---

## Next Step

→ [Istio](../applications/istio.md)
