# Istio Service Mesh

Istio provides the service mesh, traffic management, and ingress for this cluster. It is deployed as four separate ArgoCD Applications using sync waves to ensure correct ordering.

---

## Overview

| Component           | ArgoCD App            | Source                                      | Namespace       | Wave |
|---------------------|-----------------------|---------------------------------------------|-----------------|------|
| Istio CRDs          | `istio-base`          | `istio/base` chart v1.22.3                  | `istio-system`  | 1    |
| Istio control plane | `istiod`              | `istio/istiod` chart v1.22.3                | `istio-system`  | 2    |
| Ingress gateway     | `istio-ingress`       | `istio/gateway` chart v1.22.3               | `istio-ingress` | 3    |
| Gateway config      | `istio-gateway-config`| `k8s/kustomize/gateway-config/` (this repo) | `istio-ingress` | 4    |

All Istio Helm charts are pulled from `https://istio-release.storage.googleapis.com/charts`.

---

## istio-base (Wave 1)

Installs all Istio Custom Resource Definitions (CRDs) into the cluster:
- `Gateway`
- `VirtualService`
- `DestinationRule`
- `ServiceEntry`
- `PeerAuthentication`
- and more

Uses `ServerSideApply=true` sync option to avoid field manager conflicts with the large CRD manifests.

---

## istiod (Wave 2)

Installs the Istio control plane daemon (`istiod`), which:
- Manages Envoy proxy sidecar configuration
- Handles certificate issuance for mTLS
- Implements the xDS API consumed by all Envoy sidecars

`istiod` watches for pods in namespaces labeled `istio-injection: enabled` and automatically injects Envoy sidecar containers at pod creation time.

**Namespaces with sidecar injection enabled:**
- `gitlab`
- `mongodb`

---

## istio-ingress (Wave 3)

Deploys the Istio Ingress Gateway as a standalone pod in the `istio-ingress` namespace. The release name is `ingress`.

This pod runs an Envoy proxy configured as a gateway — it listens for incoming connections and routes them based on `Gateway` and `VirtualService` resources.

---

## Gateway Configuration (Wave 4)

Source: `k8s/kustomize/gateway-config/`

This Kustomize overlay deploys:

### `namespace.yml`
Creates the `istio-ingress` namespace (if not already created by the gateway chart).

### `gateway.yml`
Defines the `http-gateway` Gateway resource:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: http-gateway
  namespace: istio-ingress
spec:
  selector:
    istio: ingress          # targets the ingress gateway pod
  servers:
    - port:
        number: 80
        protocol: HTTP
      hosts:
        - "*"               # accepts traffic for any hostname
```

This is the single entry point for all HTTP traffic into the cluster.

### `kiali-vs.yml`
Routes `kiali.local` hostname to the Kiali service:

```yaml
hosts: ["kiali.local"]
gateways: ["istio-ingress/http-gateway"]
route: kiali.istio-system.svc.cluster.local:20001
```

---

## VirtualService Routing Summary

Each application defines its own VirtualService. All reference `istio-ingress/http-gateway` as the gateway:

| Host            | Match                    | Destination                                    |
|-----------------|--------------------------|------------------------------------------------|
| `*` (localhost) | prefix `/gitlab`         | `gitlab.gitlab.svc.cluster.local:80`           |
| `*` (localhost) | prefix `/mongodb-node`   | `mongo-express.mongodb.svc.cluster.local:8081` |
| `*` (localhost) | (no match, Kiali)        | `kiali.istio-system.svc.cluster.local:20001`   |
| `kiali.local`   | (any)                    | `kiali.istio-system.svc.cluster.local:20001`   |
| `dns.local`     | (any)                    | `adguardhome.dns.svc.cluster.local:3000`       |

---

## Accessing Services via Istio

Istio routes traffic through the ingress gateway. To reach services from your browser, traffic must enter on port 80 of the node.

In k3s with the default configuration, the ingress gateway pod will have a `LoadBalancer` service (k3s includes a built-in load balancer called ServiceLB / Klipper).

If the LoadBalancer service does not bind to port 80 automatically, check:

```bash
kubectl get svc -n istio-ingress
```

---

## Troubleshooting

**Check Istio pod status:**
```bash
kubectl get pods -n istio-system
kubectl get pods -n istio-ingress
```

**Check sidecar injection:**
```bash
kubectl get pods -n gitlab -o jsonpath='{.items[*].spec.containers[*].name}'
```
You should see both the app container and `istio-proxy`.

**Verify Gateway and VirtualServices:**
```bash
kubectl get gateway -A
kubectl get virtualservice -A
```

**Check ingress gateway logs:**
```bash
kubectl logs -n istio-ingress -l istio=ingress -f
```

---

## Next Step

→ [GitLab](gitlab.md)
