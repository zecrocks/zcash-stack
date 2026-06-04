[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/zcash)](https://artifacthub.io/packages/search?repo=zcash)

# Zcash Stack Helm Chart

Deploys Zcash infrastructure on Kubernetes: Zebra / Zcashd full nodes, lightwalletd,
zaino, a block explorer, and an optional Tor hidden service.

Inbound TLS and host routing use a standard Kubernetes `Ingress` (no custom CRDs), so
the chart deploys the same way on k3s (the primary target, on dedicated NVMe hardware),
GKE Standard, and GKE Autopilot.

The zec.rocks lightwalletd servers all run from this chart, load balanced with HAProxy
on Fly.io; see the [zecrocks repo](https://github.com/zecrocks/zecrocks) for that side.
Funded by [Zcash Community Grants](https://zcashcommunitygrants.org/).

> Upgrading from a 0.0.x release? The values structure changed in 0.1.0 (standard
> Ingress + cert-manager replaced the custom Traefik setup). Read
> [MIGRATION.md](./MIGRATION.md) before running `helm upgrade`.

## Prerequisites

Three cluster-level pieces are provisioned once; the chart deploys against them.

### 1. An ingress controller (ingress-nginx recommended)

The chart emits a standard `networking.k8s.io/v1` Ingress and defaults to the `nginx`
class. ingress-nginx handles gRPC (lightwalletd/zaino) consistently across all three
platforms. `ingress.className` and `ingress.annotations` are configurable if you prefer
another controller.

```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

- k3s bundles Traefik. Either install k3s with `--disable traefik` (so ingress-nginx
  owns 80/443), or keep Traefik and set `ingress.className: traefik` (gRPC annotations
  differ between controllers).
- On GKE the install above provisions an external L4 LoadBalancer in front of nginx.
  The GKE-native `gce` ingress class does not support the `backend-protocol: GRPC`
  annotation, so lightwalletd/zaino need ingress-nginx, not the default GCE ingress.

### 2. cert-manager + a ClusterIssuer (for automatic TLS)

```bash
helm upgrade --install cert-manager cert-manager \
  --repo https://charts.jetstack.io \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true \
  --set global.leaderElection.namespace=cert-manager   # required on GKE Autopilot

# Edit the email, then apply (test against Let's Encrypt staging first):
kubectl apply -f examples/cluster-issuer.yaml
```

On GKE Autopilot, set `global.leaderElection.namespace` to a normal namespace as shown.
Autopilot blocks writes to `kube-system`, where cert-manager puts its leader-election
leases by default; without the flag the cainjector never becomes leader, the webhook CA
is never injected, and `ClusterIssuer` creation fails with an x509 "unknown authority"
error. The flag is harmless on k3s and GKE Standard.

The chart references the issuer by name via `<service>.ingress.tls.clusterIssuer`
(default `letsencrypt-prod`). A ClusterIssuer is cluster-scoped, so it's a prerequisite
rather than part of the chart.

To bring your own certificate instead, skip cert-manager and set
`<service>.ingress.tls.secretName` to a pre-created `kubernetes.io/tls` Secret. The chart
references it directly and emits no cert-manager annotation.

### 3. A StorageClass

`storageClassName` is set per workload (default empty = cluster default class). Zebra and
Zcashd are IOPS-heavy during the initial sync, so on GKE point them at a provisioned-IOPS
class:

| Platform | zebra / zcashd (chain) | lightwalletd / zaino (cache) |
|---|---|---|
| k3s on NVMe | `local-path` (k3s default; NVMe already gives high IOPS) | `local-path` |
| GKE Standard / Autopilot | `zcash-chainstate-hyperdisk` (see `examples/storageclasses/gke-hyperdisk.yaml`, 12k IOPS / 400 MiB/s) or `premium-rwo` | `premium-rwo` (SSD) or `standard-rwo` |

```bash
# GKE only: create the provisioned-IOPS class once.
kubectl apply -f examples/storageclasses/gke-hyperdisk.yaml
```

`storageClassName` is immutable on an existing StatefulSet, so changing it means
recreating the PVC. `reclaimPolicy: Retain` in the GKE examples keeps a multi-day sync
from being lost on PVC delete; clean up orphaned disks after teardown.

GKE disk quota: new projects default to `SSD_TOTAL_GB = 500` and `HDB_TOTAL_GB = 500` per
region, which is too small for chain nodes (each wants ~300-500 GB of fast disk). On
Autopilot the managed node boot disks also draw from `SSD_TOTAL_GB` (pd-ssd and
pd-balanced both count), so prefer Hyperdisk for the chain state: it has a separate
`HDB_TOTAL_GB` counter. Raise `HDB_TOTAL_GB` for your region (e.g. ~1500 for two 500Gi
zebra replicas) under IAM & Admin > Quotas (Service = Compute Engine API). If you skip
this, PVCs get stuck `Pending` with `CreateVolume ... QUOTA_EXCEEDED`.

### 4. DNS

Point an A/AAAA record for each `ingress.hosts` entry at the ingress controller's external
IP:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

No DNS yet? Bootstrap TLS with [sslip.io](https://sslip.io), a wildcard-DNS service that
resolves an embedded IP to a hostname: `203-0-113-7.sslip.io` -> `203.0.113.7` (the
dotted form `203.0.113.7.sslip.io` works too). Since the name already resolves to the
node, cert-manager's HTTP-01 challenge validates right away and Let's Encrypt issues a
trusted cert with no DNS record to wait on. List it alongside your branded host so one
cert covers both, and the vanity name takes over once its A record points here:

```yaml
lightwalletd:
  ingress:
    hosts:
      - na-jfk.metal.zec.rocks     # branded (primary)
      - 203-0-113-7.sslip.io       # always-resolvable bootstrap/fallback
```

Best for new/test/ephemeral nodes. For a permanent endpoint keep the branded host primary,
since cert renewal (~every 60 days) would otherwise depend on sslip.io staying reachable.
Full example: [`examples/sslip-bootstrap.yaml`](../../examples/sslip-bootstrap.yaml).

## Usage

1. Add the repo:

   ```bash
   helm repo add zcash https://zecrocks.github.io/zcash-stack
   helm repo update
   ```

2. Copy and edit an example from [`examples/`](../../examples): set your domain(s) and RPC
   credentials. See `values.yaml` for every option.

3. Install:

   ```bash
   helm install zcash zcash/zcash-stack -f examples/zebra-mainnet.yaml
   # or, on GKE:
   helm install zcash zcash/zcash-stack -f examples/gke-zebra-mainnet.yaml
   ```

### Upgrading

The helm-diff plugin is handy here.

```bash
helm repo update
helm diff upgrade zcash zcash/zcash-stack -f ./values.yaml   # preview
helm upgrade      zcash zcash/zcash-stack -f ./values.yaml   # apply
```

### Private container registries

Create a docker-registry secret in the release namespace and list it under
`global.imagePullSecrets` (applied to every workload; each service also has its own
`imagePullSecrets` that merges with the global list). Also point each
`<service>.image.repository` at your registry.

```bash
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=USER --docker-password=PASS \
  --namespace=<release-namespace>
```

```yaml
global:
  imagePullSecrets:
    - regcred
zebra:
  image:
    repository: registry.example.com/zfnd/zebra
```

## Recommended instance sizes

Steady-state usage is modest (zebra ~0.1 vCPU / 1.6 GiB, lightwalletd ~0.15 vCPU /
165 MiB), but the initial sync is CPU/IOPS/memory heavy. The full stack (one chain node +
lightwalletd) requests ~1.5 vCPU / 4.5 GiB.

Disk sizing (mainnet, 2026-06): zebra chain state ~260 GiB and growing, lightwalletd cache
~17 GiB. The chart defaults to 500 GiB for chain nodes (zebra/zcashd) and 40 GiB for
lightwalletd/zaino. All recommended StorageClasses allow online expansion, so you can
start smaller. A full single-node stack wants ~600 GiB of disk.

| Platform | Full stack on one node | Split (chain node / frontends) |
|---|---|---|
| k3s on NVMe (primary) | 8 vCPU / 32 GiB / ~1 TB NVMe, `local-path` | chain: 8c / 32 GiB / 1 TB NVMe; frontends: 4c / 16 GiB |
| GKE Standard | `n2-standard-8` (8 vCPU / 32 GiB) + 500 GiB Hyperdisk/pd-ssd | chain pool: `n2-standard-8` + Hyperdisk; frontend pool: `e2-standard-4` (taint chain pool) |
| GKE Autopilot | No node sizing; set requests (chart defaults are tuned) and Autopilot provisions. Use `premium-rwo`/Hyperdisk for chain PVCs. | Logical split via requests/affinity |

The default requests/limits (per workload in `values.yaml`) are GKE-Autopilot compliant:
every request is at least 250m CPU / 512Mi, the memory:CPU ratio stays within 1:1 to
6.5:1, and CPU limits are omitted so sync can burst.

## High availability & zero-downtime deployments

- Probes everywhere. Every workload has readiness/liveness probes, and the slow chain
  nodes have generous startup probes so liveness doesn't kill them during a multi-hour
  sync. Readiness gates Service/Ingress membership, so traffic only reaches pods that can
  serve.
- Rolling updates + PodDisruptionBudgets. StatefulSets use `RollingUpdate`; a PDB
  (`minAvailable: 1`) renders automatically only when `replicas > 1` (a PDB on a single
  replica would block node drains).
- Spread across nodes and zones. Each workload sets `topologySpreadConstraints`
  (`<svc>.topologySpread`) over `kubernetes.io/hostname` and
  `topology.kubernetes.io/zone`. The default `ScheduleAnyway` is best-effort, so a
  single-node k3s box still schedules every replica; on a regional GKE cluster the same
  constraints place replicas in different zones. Set `whenUnsatisfiable: DoNotSchedule`
  for strict spreading on multi-node clusters (otherwise the scheduler only softly prefers
  spreading, and Autopilot bin-packs, so co-location is possible).
- lightwalletd / zaino scale horizontally. They're thin caches in front of the chain RPC;
  each replica gets its own cache PVC. Set `replicas: 2` for zero-downtime rolling updates:
  the ingress load-balances gRPC across ready pods and the PDB keeps one available.
- Chain nodes (zebra/zcashd) are not for load-scaling. Each replica is a full node with its
  own large PVC and its own sync. Run 1 (or 2 for redundancy, at the cost of a second full
  sync) and scale lightwalletd/zaino in front instead.

```bash
# zero-downtime rollout (with replicas: 2)
kubectl rollout restart statefulset/lightwalletd
kubectl rollout status  statefulset/lightwalletd
```

## Resumable snapshot restore

Set `<chain>.initSnapshot.enabled: true` to bootstrap chain state from a published snapshot
instead of a full P2P sync. The restore is idempotent and safe to interrupt, which matters
on GKE where nodes may scale up/down before a sync gets going:

- It writes an in-progress marker before any data and only marks the restore complete after
  extraction succeeds.
- An interrupted download is detected on the next start and redone cleanly, instead of
  booting on a half-written dataset.
- An existing healthy volume from a prior deployment is adopted, never wiped.

`initSnapshot.url` picks the downloader by scheme: `gs://` streams with gsutil on the
cloud-sdk image (anonymous, no disk staging); `https://` streams with wget on alpine. To
force a fresh restore, delete the PVC (or the `.snapshot-complete` marker in the data dir).

## Contributing inbound P2P (zebra)

By default nodes only make outbound peer connections. To accept inbound P2P and contribute
as a reachable full node, enable `zebra.p2pPublic`: it exposes the P2P port via `hostPort`
and advertises the node's public address (`ZEBRA_NETWORK__EXTERNAL_ADDR`). RPC/metrics stay
pod-internal.

```yaml
zebra:
  p2pPublic:
    enabled: true
    externalAddrFrom: hostIP   # or: nodeExternalIP, loadBalancer
```

- `hostIP` advertises the pod's node IP (`status.hostIP`). Correct on bare-metal / k3s
  where the node's IP is publicly reachable.
- `nodeExternalIP` runs an init container that reads the node's `ExternalIP` from the
  Kubernetes API (for cloud VKE like Vultr, where `status.hostIP` is a private VPC address).
  It adds a small get-nodes `ClusterRole`/`ServiceAccount` and a `kubectl` init container.
- `loadBalancer` accepts inbound peers through a `type: LoadBalancer` Service pinned to a
  reserved static IP (`zebra.p2pPublic.externalIP`). This is the way to do inbound P2P on
  GKE Autopilot, where `hostPort` is blocked.

`hostPort` means one zebra replica per node, and the node firewall must allow the P2P port
(8233 mainnet / 18233 testnet).

## TLS termination & gRPC

For lightwalletd/zaino (gRPC), TLS terminates at the ingress and plaintext HTTP/2 (h2c)
flows to the pod inside the cluster (lightwalletd keeps `--no-tls-very-insecure`).
ingress-nginx routes by the HTTP/2 `:authority` (Host) header, so several vanity domains
can all point at one lightwalletd via `ingress.hosts`. Keep `pathType: Prefix` / `path: /`;
gRPC method paths require it.

On Traefik (e.g. k3s), Traefik v2's Kubernetes Ingress provider ignores the h2c
backend-scheme annotation, so a plain Ingress returns HTTP 500 on gRPC. Set
`ingress.className: traefik` + `ingress.backendProtocol: GRPC` and the chart emits a native
Traefik `IngressRoute` (`scheme: h2c`) plus a cert-manager `Certificate` for the same hosts.

If a cert-manager HTTP-01 challenge fails on first issuance because of the HTTPS redirect,
validate with `letsencrypt-staging` first, or temporarily set `ingress.tls.sslRedirect:
"false"` until the cert is issued.

## Tor hidden service

The chart can deploy a Tor hidden service that exposes Zaino or Lightwalletd gRPC over an
`.onion` address. Useful when the cluster has no public IP or domain (common for
self-hosted k3s).

```yaml
tor:
  enabled: true
  targetService: zaino        # 'zaino' or 'lightwalletd'
  hiddenServicePort: 443
```

```bash
kubectl exec -it tor-0 -- cat /var/lib/tor/hidden_service/hostname
```

Test with [zecping](https://github.com/zecrocks/zecping) while Tor runs locally:

```bash
./zecping -socks localhost:9150 -addr <your-onion-address>.onion:443
```

Tor keeps its own root chown/chmod init container because its hidden-service directory must
be mode 0700, which `fsGroup` can't set, so it's excluded from `global.fsGroup`.

## Network upgrades

Around a network upgrade (e.g. NU6), nodes may transiently ban peers still on older
versions and stall; zebra logs `chain updates have stalled, state height has not increased
for N minutes` with repeated "banned peer" warnings. Zebra's banlist is in-memory only, so
restarting zebrad clears every ban and re-peers cleanly. Chain data is reused, so there's
no re-sync:

```bash
kubectl delete pod zebra-0
```

For zcashd the banlist is persisted (`banlist.dat` / `banlist.json`), so a restart alone
won't clear it. Set `zcashd.clearBanlist: true` and the chart runs an init container that
wipes those files on start; chain data is untouched, so no re-sync:

```yaml
zcashd:
  clearBanlist: true   # drop stale peer bans on start (e.g. after a network upgrade)
```

## Kubernetes cheat sheet

```bash
kubectl get all                                 # what's running
kubectl logs -f statefulset/lightwalletd        # watch logs
kubectl logs -f statefulset/zebra
kubectl exec statefulset/zebra -ti -- bash      # shell into a pod
kubectl rollout restart statefulset/lightwalletd
kubectl get svc -n ingress-nginx                # external LoadBalancer IP
kubectl get certificate                         # cert-manager TLS status
```
