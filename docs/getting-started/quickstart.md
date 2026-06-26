# Quickstart Guide

This guide walks you through setting up the full stack from scratch on a fresh Linux machine.

---

## Step 1 — Clone the Repository

```bash
git clone https://github.com/pedromota533/kubernetes-intro ~/personal/k3s.install
cd ~/personal/k3s.install
```

> The Makefile variables assume the project lives at `$HOME/personal/k3s.install`. If you clone elsewhere, update the path variables in `make/vars.mk`.

---

## Step 2 — Install k3s

```bash
make k3s-setup
```

This downloads and installs k3s using the official installer at `https://get.k3s.io`. The install is executed with:

```
INSTALL_K3S_EXEC="--node-ip=127.0.0.1 --flannel-iface=eth1"
```

Installation output is saved to `logs/k3s-setup.log`.

> To use a different node IP (e.g., a VM's eth0 IP): `make k3s-setup NODE_IP=192.168.1.100`

---

## Step 3 — Enable and Start k3s

```bash
make k3s-enable
make k3s-start
```

- `k3s-enable` registers k3s as a systemd service that starts on boot.
- `k3s-start` starts the service immediately.

Verify k3s is running:

```bash
sudo k3s kubectl get nodes
```

Expected output:
```
NAME     STATUS   ROLES                  AGE   VERSION
<host>   Ready    control-plane,master   1m    v1.x.x+k3s1
```

---

## Step 4 — Install ArgoCD

```bash
make install
```

This applies the Kustomize configuration at `k8s/bootstrap/` to the cluster using server-side apply. It:

1. Creates the `argocd` namespace
2. Installs ArgoCD from the official stable manifests
3. Patches ArgoCD to:
   - Expose via NodePort on port **30080**
   - Run in **insecure mode** (HTTP only, no TLS redirect)

Install logs are written to `logs/install.log`.

---

## Step 5 — Retrieve the Admin Password

```bash
make password
```

This decodes and prints the initial admin password from the `argocd-initial-admin-secret` Kubernetes secret. Save it — you will need it to log in to the ArgoCD UI.

---

## Step 6 — Link ArgoCD to the Repository (GitOps)

```bash
make link
```

This applies `k8s/bootstrap/root-app.yml`, which creates the ArgoCD **root Application** (`lhs-argocd-apps`). This Application points ArgoCD at `k8s/kustomize/` in this repository. ArgoCD then discovers and deploys all child Applications defined there.

> After this step, ArgoCD manages the cluster state. Do not manually apply manifests from `k8s/kustomize/` — push changes to the repository and ArgoCD will sync them.

---

## Step 7 — Add Local Domains to /etc/hosts

```bash
make hosts-add
```

Reads `config/domains` and adds an entry for each domain to `/etc/hosts`, pointing to `NODE_IP` (default: `127.0.0.1`).

Current domains:
```
127.0.0.1 triggerdev.local
127.0.0.1 kiali.local
```

---

## Step 8 — Access the ArgoCD UI

Open your browser and navigate to:

```
http://localhost:30080
```

Log in with:
- **Username:** `admin`
- **Password:** output of `make password`

You should see the root application `lhs-argocd-apps` and its child applications syncing.

---

## Step 9 — (Optional) Deploy GitLab

GitLab is not included in the auto-synced root app by default. Deploy it explicitly:

```bash
make deploy-gitlab
```

GitLab takes 2–5 minutes to become ready. Track progress with:

```bash
make pods
```

Access GitLab at `http://localhost/gitlab` with `root` / `ChangeMe123!`.

---

## Tear Down

To completely remove everything:

```bash
# Remove all ArgoCD Applications
make uninstall

# Remove k3s from the system
make k3s-delete
```

---

## Next Step

→ [Architecture Overview](../architecture/overview.md)
