{{/* Shared template helpers for the zcash-stack chart. */}}

{{/*
zcash-stack.testnet - "true"/"false" for the release's network. lightwalletd, zaino and
explorer derive the backend RPC port from this. zebra wins when enabled so existing
releases render unchanged; a zakura-only release falls back to zakura.testnet.
Usage:
  {{ if eq (include "zcash-stack.testnet" .) "true" }}18232{{ else }}8232{{ end }}
*/}}
{{- define "zcash-stack.testnet" -}}
{{- if .Values.zebra.enabled -}}
{{ .Values.zebra.testnet }}
{{- else if .Values.zakura.enabled -}}
{{ .Values.zakura.testnet }}
{{- else -}}
{{ .Values.zebra.testnet }}
{{- end -}}
{{- end -}}

{{/*
zcash-stack.podSecurityContext - pod securityContext that sets volume ownership
via fsGroup (OnRootMismatch) instead of a root chown init container.
Usage:
  {{- include "zcash-stack.podSecurityContext" (dict "uid" 2001 "global" .Values.global) | nindent 6 }}
*/}}
{{- define "zcash-stack.podSecurityContext" -}}
{{- if .global.fsGroup.enabled }}
securityContext:
  fsGroup: {{ .uid }}
  fsGroupChangePolicy: OnRootMismatch
{{- end }}
{{- end -}}

{{/*
zcash-stack.restoreInitContainer - idempotent, resumable snapshot-restore init
container (markers: .snapshot-complete / .snapshot-inprogress). A non-empty unmarked
volume is adopted (never wiped) unless adoptExisting is false, which wipes and
restores instead. Downloader by URL scheme: gs:// via gsutil on the cloud-sdk image,
http(s):// via wget on alpine.
Optional: compression "zstd" (https only, adds zstd via apk), stripComponents (default 1;
zakura's tar is rooted at state/ so it passes 0), resumable (aria2c to a scratch file on
the volume instead of streaming, so a dropped connection resumes instead of restarting;
needs room for the archive AND the extracted data), sha256 (verified when resumable).
Usage:
  {{- include "zcash-stack.restoreInitContainer" (dict
        "url" .Values.zebra.initSnapshot.url
        "uid" "2001"
        "claimName" (printf "%s-data" .Values.zebra.name)
        "doChown" (not .Values.global.fsGroup.enabled)
        "adoptExisting" .Values.zebra.initSnapshot.adoptExisting
        "global" .Values.global) | nindent 6 }}
*/}}
{{- define "zcash-stack.restoreInitContainer" -}}
{{- $isGcs := hasPrefix "gs://" .url -}}
{{- $zstd := eq (toString .compression) "zstd" -}}
{{- if and $zstd $isGcs }}{{ fail "initSnapshot: compression zstd is only supported for http(s) URLs (the cloud-sdk image has no zstd)" }}{{ end -}}
{{- $strip := 1 -}}
{{- if not (kindIs "invalid" .stripComponents) }}{{- $strip = .stripComponents }}{{- end -}}
{{- $resumable := eq (toString .resumable) "true" -}}
{{- if and $resumable $isGcs }}{{ fail "initSnapshot: resumable is only supported for http(s) URLs" }}{{ end -}}
- name: restore-snapshot
  {{- if $isGcs }}
  image: {{ .global.images.cloudSdk.repository }}:{{ .global.images.cloudSdk.tag }}@sha256:{{ .global.images.cloudSdk.hash }}
  {{- else }}
  image: alpine:{{ .global.images.alpine.tag }}@sha256:{{ .global.images.alpine.hash }}
  {{- end }}
  {{- /* Wiping an adopted dataset means unlinking files the previous image wrote as
         root, which the data uid can't do under fsGroup, so wipe as root and chown back. */}}
  {{- $asRoot := or .doChown (eq (toString .adoptExisting) "false") }}
  {{- /* zstd/aria2 need apk, which needs root. Kept separate from $asRoot so it doesn't also
         trigger a pointless chown -R over a few hundred GiB of restored state. */}}
  securityContext:
    {{- if or $asRoot $zstd $resumable }}
    runAsUser: 0
    {{- else }}
    runAsUser: {{ .uid }}
    runAsNonRoot: true
    {{- end }}
  {{- if $isGcs }}
  # gsutil writes state under $HOME; the data uid has no home, so point it at /tmp.
  env:
    - name: HOME
      value: /tmp
  command: ["/bin/bash", "-c"]
  {{- else }}
  command: ["/bin/sh", "-c"]
  {{- end }}
  args:
    - |
      set -eu
      set -o pipefail
      DATA_DIR=/data
      URL="{{ .url }}"
      DO_CHOWN="{{ $asRoot }}"
      UID_OWNER="{{ .uid }}"
      COMPLETE="$DATA_DIR/.snapshot-complete"
      INPROGRESS="$DATA_DIR/.snapshot-inprogress"
      {{- if $resumable }}
      DL_DIR="$DATA_DIR/.snapshot-dl"
      DL_FILE="$DL_DIR/snapshot.dat"
      SHA256="{{ .sha256 }}"
      {{- end }}
      {{- if $resumable }}
      is_empty() { [ -z "$(ls -A "$DATA_DIR" 2>/dev/null | grep -vE '^(lost\+found|\.snapshot-dl)$' || true)" ]; }
      {{- else }}
      is_empty() { [ -z "$(ls -A "$DATA_DIR" 2>/dev/null | grep -v '^lost+found$' || true)" ]; }
      {{- end }}
      restore() {
        echo "Restoring snapshot from $URL ...";
        {{- if $resumable }}
        apk add --no-cache aria2 {{ if $zstd }}zstd{{ end }};
        {{- else if $zstd }}
        apk add --no-cache zstd;
        {{- end }}
        {{- /* The partial download lives under $DATA_DIR, so it must survive the wipe
               or every retry would start from zero, which is the bug this fixes. */}}
        find "$DATA_DIR" -mindepth 1 -maxdepth 1 ! -name 'lost+found' {{ if $resumable }}! -name '.snapshot-dl' {{ end }}-exec rm -rf {} + ;
        : > "$INPROGRESS";
        {{- if $resumable }}
        mkdir -p "$DL_DIR";
        # -c resumes an interrupted transfer across container restarts; aria2 also
        # retries individual segments, which plain wget streaming cannot do.
        aria2c -c -x8 -s8 -j1 --max-tries=0 --retry-wait=10 --file-allocation=none \
          --summary-interval=60 --console-log-level=warn \
          {{ if .sha256 }}--checksum=sha-256="$SHA256" {{ end }}-d "$DL_DIR" -o snapshot.dat "$URL";
        {{- if $zstd }}
        zstd -dc "$DL_FILE" | tar {{ if $strip }}--strip-components={{ $strip }} {{ end }}-xf - -C "$DATA_DIR";
        {{- else }}
        tar {{ if $strip }}--strip-components={{ $strip }} {{ end }}-xf "$DL_FILE" -C "$DATA_DIR";
        {{- end }}
        rm -rf "$DL_DIR";
        {{- else if $isGcs }}
        gsutil -q -o "GSUtil:state_dir=/tmp/gsutil" cp "$URL" - | tar {{ if $strip }}--strip-components={{ $strip }} {{ end }}-xf - -C "$DATA_DIR";
        {{- else if $zstd }}
        wget -qO- "$URL" | zstd -dc | tar {{ if $strip }}--strip-components={{ $strip }} {{ end }}-xf - -C "$DATA_DIR";
        {{- else }}
        wget -qO- "$URL" | tar {{ if $strip }}--strip-components={{ $strip }} {{ end }}-xf - -C "$DATA_DIR";
        {{- end }}
        rm -f "$INPROGRESS";
        : > "$COMPLETE";
        echo "Snapshot restore complete.";
      }
      if [ -f "$COMPLETE" ]; then
        echo "Complete marker present. Skipping restore.";
      elif [ -f "$INPROGRESS" ]; then
        echo "Interrupted restore detected. Wiping and re-restoring.";
        restore;
      elif is_empty; then
        echo "Volume empty. Restoring.";
        restore;
      else
        {{- if (eq (toString .adoptExisting) "false") }}
        echo "Non-empty volume without markers: wiping and restoring (adoptExisting=false).";
        restore;
        {{- else }}
        echo "Non-empty volume without markers: adopting existing dataset as complete.";
        : > "$COMPLETE";
        {{- end }}
      fi
      if [ "$DO_CHOWN" = "true" ]; then
        echo "chown -R $UID_OWNER $DATA_DIR";
        chown -R "$UID_OWNER" "$DATA_DIR";
      fi
  volumeMounts:
    - name: {{ .claimName }}
      mountPath: /data
{{- end -}}

{{/*
zcash-stack.setPermissionsInitContainer - root chown fallback when
global.fsGroup.enabled is false and no snapshot restore is configured.
Usage:
  {{- include "zcash-stack.setPermissionsInitContainer" (dict
        "uid" "2001" "claimName" "zebra-data" "global" .Values.global) | nindent 6 }}
*/}}
{{- define "zcash-stack.setPermissionsInitContainer" -}}
- name: set-permissions
  image: busybox:{{ .global.images.busybox.tag }}@sha256:{{ .global.images.busybox.hash }}
  securityContext:
    runAsUser: 0
  command: ["/bin/sh", "-c"]
  args:
    - chown -R {{ .uid }} /data
  volumeMounts:
    - name: {{ .claimName }}
      mountPath: /data
{{- end -}}

{{/*
zcash-stack.ingress - standard networking.k8s.io/v1 Ingress for a service:
multiple hosts to one backend, parameterizable class/annotations, gRPC, and TLS via
cert-manager (set tls.clusterIssuer) or a bring-your-own Secret (set tls.secretName).
tls.hosts narrows the cert to a subset of hosts, for names that route here but are
ACMEd elsewhere (e.g. an edge proxy owns the public name). Default: all hosts.
gRPC on Traefik emits a native IngressRoute (h2c) + Certificate instead.
Usage:
  {{- include "zcash-stack.ingress" (dict
        "ctx" $
        "svc" .Values.lightwalletd.ingress
        "name" (printf "%s-%s" .Release.Name .Values.lightwalletd.name)
        "serviceName" .Values.lightwalletd.name
        "servicePort" .Values.lightwalletd.service.port) }}
*/}}
{{- define "zcash-stack.ingress" -}}
{{- $ctx := .ctx -}}
{{- $svc := .svc -}}
{{- $hosts := $svc.hosts | default (list) -}}
{{- if and $svc.enabled $hosts -}}
{{- $path := $svc.path | default "/" -}}
{{- $pathType := $svc.pathType | default "Prefix" -}}
{{- $tls := $svc.tls | default dict -}}
{{- $autoSecret := printf "%s-tls" .name -}}
{{- $secretName := $tls.secretName | default $autoSecret -}}
{{- $certManager := and $tls.enabled $tls.clusterIssuer (not $tls.secretName) -}}
{{- $isGrpc := eq ($svc.backendProtocol | default "HTTP") "GRPC" -}}
{{- $isTraefik := eq (toString ($svc.className | default "")) "traefik" -}}
{{- if and $isGrpc $isTraefik -}}
{{/* Traefik's k8s Ingress ignores serversscheme, so a standard Ingress can't speak
     h2c to gRPC (HTTP 500); use a native IngressRoute (h2c) + explicit Certificate. */}}
{{- if $certManager }}
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: {{ .name }}
  labels:
    app.kubernetes.io/name: {{ .serviceName }}
    app.kubernetes.io/managed-by: {{ $ctx.Release.Service }}
spec:
  secretName: {{ $secretName | quote }}
  dnsNames:
  {{- range ($tls.hosts | default $hosts) }}
    - {{ . | quote }}
  {{- end }}
  issuerRef:
    name: {{ $tls.clusterIssuer | quote }}
    kind: ClusterIssuer
---
{{- end }}
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: {{ .name }}
  labels:
    app.kubernetes.io/name: {{ .serviceName }}
    app.kubernetes.io/managed-by: {{ $ctx.Release.Service }}
spec:
  entryPoints:
    - {{ $svc.traefikEntryPoint | default "websecure" }}
  routes:
    - kind: Rule
      match: {{ range $i, $h := $hosts }}{{ if $i }} || {{ end }}Host(`{{ $h }}`){{ end }}
      services:
        - name: {{ $.serviceName }}
          port: {{ $.servicePort }}
          scheme: h2c
  {{- if $tls.enabled }}
  tls:
    secretName: {{ $secretName | quote }}
  {{- end }}
{{- else -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .name }}
  labels:
    app.kubernetes.io/name: {{ .serviceName }}
    app.kubernetes.io/managed-by: {{ $ctx.Release.Service }}
  annotations:
    {{- if eq ($svc.backendProtocol | default "HTTP") "GRPC" }}
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    {{- end }}
    {{- if hasKey $tls "sslRedirect" }}
    nginx.ingress.kubernetes.io/ssl-redirect: {{ $tls.sslRedirect | quote }}
    {{- end }}
    {{- if $certManager }}
    cert-manager.io/cluster-issuer: {{ $tls.clusterIssuer | quote }}
    {{- end }}
    {{- with $svc.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- with $svc.className }}
  ingressClassName: {{ . }}
  {{- end }}
  {{- if $tls.enabled }}
  tls:
    - hosts:
      {{- range ($tls.hosts | default $hosts) }}
        - {{ . | quote }}
      {{- end }}
      secretName: {{ $secretName | quote }}
  {{- end }}
  rules:
  {{- range $hosts }}
    - host: {{ . | quote }}
      http:
        paths:
          - path: {{ $path }}
            pathType: {{ $pathType }}
            backend:
              service:
                name: {{ $.serviceName }}
                port:
                  number: {{ $.servicePort }}
  {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
zcash-stack.pdb - PodDisruptionBudget, rendered only when replicas > 1 (a
minAvailable:1 PDB on a single replica would block every node drain).
Usage:
  {{- include "zcash-stack.pdb" (dict
        "replicas" .Values.lightwalletd.replicas
        "name" .Values.lightwalletd.name
        "minAvailable" .Values.lightwalletd.pdb.minAvailable) }}
*/}}
{{- define "zcash-stack.pdb" -}}
{{- if gt (int .replicas) 1 -}}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ .name }}-pdb
  labels:
    app: {{ .name }}
spec:
  minAvailable: {{ .minAvailable | default 1 }}
  selector:
    matchLabels:
      app: {{ .name }}
{{- end -}}
{{- end -}}

{{/*
zcash-stack.topologySpread - spread replicas across nodes and zones. Defaults to
ScheduleAnyway so single-node clusters still schedule; DoNotSchedule for strict.
Usage:
  {{- include "zcash-stack.topologySpread" (dict
        "cfg" .Values.lightwalletd.topologySpread "name" .Values.lightwalletd.name) | nindent 6 }}
*/}}
{{- define "zcash-stack.topologySpread" -}}
{{- if .cfg.enabled }}
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: {{ .cfg.whenUnsatisfiable | default "ScheduleAnyway" }}
    labelSelector:
      matchLabels:
        app: {{ .name }}
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: {{ .cfg.whenUnsatisfiable | default "ScheduleAnyway" }}
    labelSelector:
      matchLabels:
        app: {{ .name }}
{{- end }}
{{- end -}}

{{/*
zcash-stack.imagePullSecrets - render imagePullSecrets from the merged list of
secret names (global + optional per-workload). The secrets must already exist in
the namespace. Renders nothing when the list is empty.
Usage:
  {{- include "zcash-stack.imagePullSecrets" (concat (.Values.global.imagePullSecrets | default list) (.Values.zebra.imagePullSecrets | default list)) | nindent 6 }}
*/}}
{{- define "zcash-stack.imagePullSecrets" -}}
{{- $names := list -}}
{{- range (.Values.global.imagePullSecrets | default list) }}
  {{- if kindIs "string" . }}{{- $names = append $names . -}}{{- else }}{{- $names = append $names .name -}}{{- end }}
{{- end -}}
{{- if and .Values.imageCredentials .Values.imageCredentials.enabled }}{{- $names = append $names .Values.imageCredentials.name -}}{{- end -}}
{{- with $names }}
imagePullSecrets:
{{- range . }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end -}}
