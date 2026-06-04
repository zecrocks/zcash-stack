# Migrating to zcash-stack 0.1.0

0.1.0 replaces the custom Traefik `IngressRouteTCP` setup with a standard Kubernetes
`Ingress` + cert-manager, and reorganizes `values.yaml`. This is a breaking change: update
your values file and cluster prerequisites before running `helm upgrade`.

Chain data (PVCs) is not affected, only the chart's resources and value keys. The new
snapshot-restore logic adopts an existing healthy volume without re-downloading.

## Cluster prerequisites changed

| Before (0.0.x) | Now (0.1.0) |
|---|---|
| `install-traefik.sh` (Traefik + its built-in ACME) | An ingress controller (ingress-nginx recommended) |
| Traefik `certResolver: letsencrypt` | cert-manager + a `ClusterIssuer` (see `examples/cluster-issuer.yaml`) |

`install-traefik.sh` is removed. See the README "Prerequisites" section for the new setup.
On k3s, install with `--disable traefik` or set `ingress.className: traefik` in your values.

## Values key changes

### Ingress (the biggest change)

The top-level `ingress` block is gone. Each exposed service now has its own `ingress`
sub-block. The old `ingress.domains` list (which routed to lightwalletd) becomes
`lightwalletd.ingress.hosts`.

Before:
```yaml
ingress:
  enabled: true
  domains:
    - lwd.example.com
    - zec.rocks
  sniCatchallEnabled: true
zaino:
  ingress:
    enabled: true
    domains:
      - zaino.example.com
```

After:
```yaml
lightwalletd:
  ingress:
    enabled: true
    className: nginx
    hosts:
      - lwd.example.com
      - zec.rocks
    backendProtocol: GRPC
    tls:
      enabled: true
      clusterIssuer: letsencrypt-prod   # or set secretName for bring-your-own TLS
zaino:
  ingress:
    enabled: true
    className: nginx
    hosts:
      - zaino.example.com
    backendProtocol: GRPC
    tls:
      enabled: true
      clusterIssuer: letsencrypt-prod
```

| Old key | New key |
|---|---|
| `ingress.enabled` | `lightwalletd.ingress.enabled` |
| `ingress.domains` | `lightwalletd.ingress.hosts` |
| `zaino.ingress.domains` | `zaino.ingress.hosts` |
| (none; explorer was internal) | `explorer.ingress.*` (new, optional) |
| `ingress.sniCatchallEnabled` | removed (see below) |

#### sniCatchallEnabled is removed

There's no standard-Ingress equivalent of Traefik's `HostSNI(\`*\`)` catch-all. List the
hostnames you serve in `lightwalletd.ingress.hosts` instead (one multi-SAN certificate
covers them all). If you really need a hostless/default backend, configure it on the
ingress controller directly; a hostless TLS rule has no SNI certificate.

### Resources

Flat `requests`/`limits` keys are unified under `<service>.resources`.

Before:
```yaml
zebra:
  requests: { cpu: 2, memory: 4Gi }
  limits:   { memory: 16Gi }
```

After:
```yaml
zebra:
  resources:
    requests: { cpu: 500m, memory: 2Gi }
    limits:   { memory: 8Gi }     # CPU limit omitted (burst + Autopilot)
```

This applies to `zebra`, `zcashd`, `lightwalletd`, `zaino`, and `tor` (new).
`explorer.resources` keeps its nested shape, but its CPU limit was removed (the old
`cpu: "1"` limit with a `0.1` request violated GKE Autopilot).

### Probes

`<service>.probes` now covers `startup`, `readiness`, and `liveness` for every workload
(previously only zebra had a `probes` block). Defaults are sensible; tune thresholds there.
lightwalletd/zaino expose a `probes.<kind>.type` (`tcpSocket` | `grpc` | `exec`) so you can
switch probe style without editing templates.

### New keys

| Key | Default | Purpose |
|---|---|---|
| `global.fsGroup.enabled` | `true` | Set volume ownership via `fsGroup` instead of a root chown init container (faster restarts). Set `false` to keep root chown init containers. |
| `<service>.storageClassName` | `""` | Now on all stateful workloads (was only zebra/zcashd). Empty = cluster default. |
| `<service>.replicas` / `podManagementPolicy` / `minReadySeconds` / `pdb.minAvailable` | see values | Rolling-update / HA controls. A PDB renders only when `replicas > 1`. |

## Suggested upgrade procedure

1. Install the new prerequisites (ingress controller, cert-manager, ClusterIssuer,
   StorageClass); see the README.
2. Rewrite your values file using the tables above. Start from the matching file in
   `examples/`.
3. Preview: `helm diff upgrade <release> zcash/zcash-stack -f values.yaml`. Expect the
   Traefik `IngressRouteTCP` objects to be removed and standard `Ingress` objects added;
   StatefulSets update in place (PVCs retained).
4. Point DNS at the new ingress controller's external IP.
5. `helm upgrade <release> zcash/zcash-stack -f values.yaml`.
6. Verify: `kubectl get ingress`, `kubectl get certificate`, and a gRPC probe
   (`grpcurl <host>:443 cash.z.wallet.sdk.rpc.CompactTxStreamer/GetLightdInfo`). Validate
   with `letsencrypt-staging` before switching to `letsencrypt-prod`.
