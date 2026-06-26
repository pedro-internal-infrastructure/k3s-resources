# Hosts Management

This project includes two `make` targets for managing local DNS entries via `/etc/hosts`, allowing you to access services by hostname rather than IP and port.

---

## Domain Definitions

All project domains are declared in `config/domains`:

```
# Domains managed by this project
# Format: <subdomain>   # <description>
# All resolve to NODE_IP (default: 127.0.0.1)

triggerdev.local    # Trigger.dev webapp
kiali.local         # Kiali — Istio observability dashboard
```

**Format:**
- One domain per line
- Lines starting with `#` are comments and are ignored
- Blank lines are ignored
- Only the first field of each line is used as the domain name

To add a new domain, simply append a line to `config/domains` and re-run `make hosts-add`.

---

## Adding Domains

```bash
make hosts-add
```

For each non-comment, non-blank line in `config/domains`, this target adds an entry to `/etc/hosts` in the format:

```
<NODE_IP>  <domain>
```

**Default (NODE_IP = 127.0.0.1):**
```
127.0.0.1 triggerdev.local
127.0.0.1 kiali.local
127.0.0.1 dns.local
```

**Custom NODE_IP:**
```bash
make hosts-add NODE_IP=192.168.1.50
```

Results in:
```
192.168.1.50 triggerdev.local
192.168.1.50 kiali.local
192.168.1.50 dns.local
```

Use a custom `NODE_IP` when k3s runs on a VM or remote machine and you need to access services from another host.

### Idempotency

The target checks if each entry already exists in `/etc/hosts` before adding it. Existing entries are skipped with an `already exists` message.

---

## Removing Domains

```bash
make hosts-remove
```

Removes all entries whose domain name appears in `config/domains` from `/etc/hosts`, regardless of the IP address they point to.

This uses `sed` to delete matching lines:
```bash
sudo sed -i "/[[:space:]]<domain>$/d" /etc/hosts
```

---

## Manual /etc/hosts Edit

If you prefer to manage `/etc/hosts` manually:

```bash
sudo nano /etc/hosts
```

Add lines like:
```
127.0.0.1 kiali.local
127.0.0.1 triggerdev.local
127.0.0.1 dns.local
```

---

## How It Affects Service Access

With the hosts file updated, you can access services by hostname:

| Domain             | Resolves to | Routes to                              |
|--------------------|-------------|----------------------------------------|
| `kiali.local`      | `NODE_IP`   | Kiali dashboard (via Istio VirtualService) |
| `triggerdev.local` | `NODE_IP`   | Trigger.dev (if deployed)              |
| `dns.local`        | `NODE_IP`   | AdGuard Home admin UI (via Istio VirtualService) |

The Istio ingress gateway receives traffic on port 80 and inspects the `Host` header to match VirtualService rules.

---

## Troubleshooting

**Domain not resolving:**
```bash
cat /etc/hosts | grep local
```

**Verify DNS resolution:**
```bash
ping kiali.local
```

**Browser caching old DNS:**  
Clear the browser DNS cache or use a private/incognito window after updating `/etc/hosts`.
