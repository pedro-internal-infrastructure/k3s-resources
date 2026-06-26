# k3s Installation & Management

k3s is the Kubernetes distribution that powers this project. All k3s operations are managed through `make` targets.

---

## Install k3s

```bash
make k3s-setup
```

**What it does:**

1. Downloads the k3s installer from `https://get.k3s.io` using `curl`.
2. Runs the installer as root with:
   ```
   INSTALL_K3S_EXEC="--node-ip=<NODE_IP> --flannel-iface=eth1"
   ```
3. Saves full output to `logs/k3s-setup.log`.

**Configuration flags explained:**

| Flag               | Value          | Purpose                                                      |
|--------------------|----------------|--------------------------------------------------------------|
| `--node-ip`        | `127.0.0.1`    | IP address advertised by the node (override with `NODE_IP=`) |
| `--flannel-iface`  | `eth1`         | Network interface used by Flannel CNI for pod networking     |

**Override NODE_IP:**

```bash
make k3s-setup NODE_IP=192.168.1.50
```

Use this when running k3s on a VM with a non-loopback IP, or when you need services to be reachable from another machine.

---

## Start / Stop k3s

```bash
make k3s-start   # sudo systemctl start k3s
make k3s-stop    # sudo systemctl stop k3s
```

After starting, verify the cluster is up:

```bash
sudo k3s kubectl get nodes
```

---

## Enable / Disable Autostart

```bash
make k3s-enable    # sudo systemctl enable k3s
make k3s-disable   # sudo systemctl disable k3s
```

When enabled, k3s will start automatically when the machine boots.

---

## Uninstall k3s

```bash
make k3s-delete
```

This runs `/usr/local/bin/k3s-uninstall.sh`, which is installed by the k3s setup script. It:
- Stops the k3s service
- Removes all k3s binaries
- Removes all k3s data directories
- Removes the k3s systemd unit

> ⚠️ This is **destructive**. All cluster data, namespaces, and workloads will be lost.

If the uninstall script is not found (k3s not installed), the command exits with an error.

---

## Kubeconfig

k3s writes its kubeconfig to `/etc/rancher/k3s/k3s.yaml` (root-owned). The `k3s kubectl` command reads it automatically.

To use standard `kubectl` instead:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes
```

Or copy it to your home directory:

```bash
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config
```

---

## Troubleshooting

**k3s won't start:**
```bash
sudo journalctl -u k3s -f
```

**Check k3s setup log:**
```bash
cat logs/k3s-setup.log
```

**Check node status:**
```bash
sudo k3s kubectl describe node
```

---

## Next Step

→ [ArgoCD Installation](argocd.md)
