{{/* Shared template helpers for the zcash-stack chart. */}}

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
container (markers: .snapshot-complete / .snapshot-inprogress; adopts a non-empty
unmarked volume, never wipes it). Downloader by URL scheme: gs:// via gsutil on the
cloud-sdk image, http(s):// via wget on alpine.
Usage:
  {{- include "zcash-stack.restoreInitContainer" (dict
        "url" .Values.zebra.initSnapshot.url
        "uid" "2001"
        "claimName" (printf "%s-data" .Values.zebra.name)
        "doChown" (not .Values.global.fsGroup.enabled)
        "global" .Values.global) | nindent 6 }}
*/}}
{{- define "zcash-stack.restoreInitContainer" -}}
{{- $isGcs := hasPrefix "gs://" .url -}}
- name: restore-snapshot
  {{- if $isGcs }}
  image: {{ .global.images.cloudSdk.repository }}:{{ .global.images.cloudSdk.tag }}@sha256:{{ .global.images.cloudSdk.hash }}
  {{- else }}
  image: alpine:{{ .global.images.alpine.tag }}@sha256:{{ .global.images.alpine.hash }}
  {{- end }}
  securityContext:
    {{- if .doChown }}
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
      DO_CHOWN="{{ .doChown }}"
      UID_OWNER="{{ .uid }}"
      COMPLETE="$DATA_DIR/.snapshot-complete"
      INPROGRESS="$DATA_DIR/.snapshot-inprogress"
      is_empty() { [ -z "$(ls -A "$DATA_DIR" 2>/dev/null | grep -v '^lost+found$' || true)" ]; }
      restore() {
        echo "Restoring snapshot from $URL ...";
        find "$DATA_DIR" -mindepth 1 -maxdepth 1 ! -name 'lost+found' -exec rm -rf {} + ;
        : > "$INPROGRESS";
        {{- if $isGcs }}
        gsutil -q -o "GSUtil:state_dir=/tmp/gsutil" cp "$URL" - | tar --strip-components=1 -xf - -C "$DATA_DIR";
        {{- else }}
        wget -qO- "$URL" | tar --strip-components=1 -xf - -C "$DATA_DIR";
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
        echo "Non-empty volume without markers: adopting existing dataset as complete.";
        : > "$COMPLETE";
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
  {{- range $hosts }}
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
      {{- range $hosts }}
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
