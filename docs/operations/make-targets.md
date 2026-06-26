# Make Targets Reference

All operations are performed through `make`. Run `make help` at any time for a quick reference.

```bash
make help
```

---

## Variables

These variables can be overridden on the command line:

| Variable    | Default          | Description                                      |
|-------------|------------------|--------------------------------------------------|
| `NODE_IP`   | `127.0.0.1`      | IP address of the k3s node                       |

Example:
```bash
make k3s-setup NODE_IP=192.168.1.50
make hosts-add NODE_IP=192.168.1.50
```

---

## k3s Targets

### `make k3s-setup`

Downloads and installs k3s from `https://get.k3s.io`.

```bash
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="--node-ip=$(NODE_IP) --flannel-iface=eth1" \
  sudo sh -
```

- Output logged to `logs/k3s-setup.log`
- Override `NODE_IP` for VMs: `make k3s-setup NODE_IP=192.168.1.100`

---

### `make k3s-start`

Starts the k3s systemd service.

```bash
sudo systemctl start k3s
```

---

### `make k3s-stop`

Stops the k3s systemd service.

```bash
sudo systemctl stop k3s
```

---

### `make k3s-enable`

Enables k3s to start automatically at boot.

```bash
sudo systemctl enable k3s
```

---

### `make k3s-disable`

Prevents k3s from starting automatically at boot.

```bash
sudo systemctl disable k3s
```

---

### `make k3s-delete`

Completely removes k3s from the system.

Runs `/usr/local/bin/k3s-uninstall.sh`. Fails with an error message if k3s is not installed.

> ⚠️ Destructive — all cluster data is lost.

---

## ArgoCD Targets

### `make install`

Installs ArgoCD into the cluster using the bootstrap Kustomize overlay.

```bash
kubectl apply --server-side --force-conflicts -k k8s/bootstrap/
```

- Logs written to `logs/install.log`
- Fails and prints an error if installation fails

---

### `make uninstall`

Safely removes ArgoCD and all its Applications in three steps:

1. Removes finalizers from the root App and all Applications
2. Deletes the root App and all Applications
3. Deletes ArgoCD itself via `kubectl delete -k k8s/bootstrap/`

---

### `make link`

Applies `k8s/bootstrap/root-app.yml` — creates the ArgoCD root Application that links ArgoCD to this repository.

```bash
kubectl apply -f k8s/bootstrap/root-app.yml
```

---

### `make unlink`

Deletes the root Application.

```bash
kubectl delete -f k8s/bootstrap/root-app.yml --ignore-not-found
```

---

### `make port-forward`

Starts a background port-forward to the ArgoCD server on `localhost:8080`.

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

- Runs in the background (`&`)
- Logs written to `logs/port-forward.log`
- Access ArgoCD at `http://localhost:8080`

---

### `make password`

Prints the ArgoCD initial admin password.

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

---

### `make status`

Shows all Kubernetes resources in the `argocd` namespace.

```bash
kubectl get all -n argocd
```

---

### `make pods`

Shows all pods across all namespaces with node placement.

```bash
kubectl get pods -A -o wide
```

---

### `make deploy-apps`

Manually applies the kustomize app manifests (normally handled by ArgoCD).

```bash
kubectl apply -k k8s/kustomize/
```

---

### `make remove-apps`

Manually removes the kustomize app manifests.

```bash
kubectl delete -k k8s/kustomize/ --ignore-not-found
```

---

### `make nuke-apps`

Immediately deletes all ArgoCD Applications from the cluster.

```bash
kubectl delete applications.argoproj.io --all -n argocd --ignore-not-found
```

> ⚠️ Use only in emergencies — bypasses finalizers and may leave orphaned resources.

---

### `make prune-apps`

Cleans up namespaces left behind after uninstalling ArgoCD. Strips finalizers from all resources in these namespaces, then deletes them:

- `triggerdev`
- `istio-system`
- `istio-ingress`
- `monitoring`
- `kubernetes-dashboard`

---

### `make ghcr-secret`

Adds GHCR credentials to ArgoCD as an OCI repository secret.

```bash
make ghcr-secret GHCR_USER=<github-username> GHCR_TOKEN=<github-pat>
```

**Required parameters:**

| Parameter    | Description                                    |
|--------------|------------------------------------------------|
| `GHCR_USER`  | Your GitHub username                           |
| `GHCR_TOKEN` | GitHub PAT with `read:packages` scope          |

Creates a secret named `ghcr-triggerdev-charts` in the `argocd` namespace with the `argocd.argoproj.io/secret-type=repository` label.

---

## GitLab Targets

### `make deploy-gitlab`

Creates the GitLab ArgoCD Application. ArgoCD then syncs GitLab from GitHub.

Applies:
- `k8s/kustomize/gitlab/namespace.yml`
- `k8s/kustomize/gitlab/project.yml`
- `k8s/kustomize/gitlab/application.yml`

Logs written to `logs/deploy-gitlab.log`.

Access: `http://localhost/gitlab` — Credentials: `root` / `ChangeMe123!`

---

### `make remove-gitlab`

Removes the GitLab ArgoCD Application and AppProject.

1. Removes the finalizer from the `gitlab` Application
2. Deletes the Application, AppProject, and namespace

---

## Hosts Targets

### `make hosts-add`

Reads `config/domains` and adds each domain to `/etc/hosts` pointing to `NODE_IP`.

```bash
make hosts-add              # uses 127.0.0.1
make hosts-add NODE_IP=192.168.1.50
```

Skips entries that already exist.

---

### `make hosts-remove`

Removes all project domains from `/etc/hosts`.

---

## Logs

Operations that produce logs write them to the `logs/` directory:

| File                    | Created by          |
|-------------------------|---------------------|
| `logs/k3s-setup.log`    | `make k3s-setup`    |
| `logs/install.log`      | `make install`      |
| `logs/deploy-gitlab.log`| `make deploy-gitlab`|
| `logs/port-forward.log` | `make port-forward` |
