{{/*
Deployment and Service combination
*/}}
{{- define "elCicdResources.deploymentService" }}
  {{- include "elCicdResources.deployment" . }}
---
  {{- include "elCicdResources.service" . }}
{{- end }}
{{/*
Deployment and Service combination
*/}}
{{- define "elCicdResources.deploymentServiceIngress" }}
  {{- include "elCicdResources.deployment" . }}
---
  {{- include "elCicdResources.service" . }}
---
  {{- include "elCicdResources.ingress" . }}
{{- end }}

{{/*
HorizontalPodAutoscaler Metrics
*/}}
{{- define "elCicdResources.hpaMetrics" }}
{{- $ := index . 0 }}
{{- $metrics := index . 1 }}
metrics:
{{- range $metric := $metrics }}
- type: {{ $metric.type }}
  {{- lower $metric.type | indent 2 }}:
    metric:
      name: {{ $metric.name }}
      {{- if $metric.selector }}
      selector: {{ $metric.selector | toYaml | nindent 6}}
      {{- end }}
    target: {{- $metric.target | toYaml | nindent 4 }}
    {{- if $metric.describedObject }}
    describedObject: {{- $metric.describedObject | toYaml | nindent 4 }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Job Template
*/}}
{{- define "elCicdResources.jobTemplate" }}
{{- $ := index . 0 }}
{{- $jobValues := index . 1 }}
{{- include "elCicdResources.apiMetadata" . }}
spec:
  {{- if $jobValues.activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ $jobValues.activeDeadlineSeconds }}
  {{- end }}
  {{- if $jobValues.activeDeadlineSeconds }}
  backoffLimit: {{ $jobValues.activeDeadlineSeconds }}
  {{- end }}
  {{- if $jobValues.completionMode }}
  completionMode: {{ $jobValues.completionMode }}
  {{- end }}
  {{- if $jobValues.completions }}
  completions: {{ $jobValues.completions }}
  {{- end }}
  {{- if $jobValues.manualSelector }}
  manualSelector: {{ $jobValues.manualSelector }}
  {{- end }}
  {{- if $jobValues.parallelism }}
  parallelism: {{ $jobValues.parallelism }}
  {{- end }}
  {{- $_ := set $jobValues "restartPolicy" ($jobValues.restartPolicy | default "Never") }}
  template: {{ include "elCicdResources.podTemplate" (list $ $jobValues false) | indent 4 }}
  {{- if $jobValues.ttlSecondsAfterFinished }}
  ttlSecondsAfterFinished: {{ $jobValues.ttlSecondsAfterFinished }}
  {{- end }}
{{- end }}

{{/*
Pod Template
*/}}
{{- define "elCicdResources.podTemplate" }}
{{- $ := index . 0 }}
{{- $podValues := index . 1 }}
{{- include "elCicdResources.apiMetadata" . }}
spec:
  {{- if $podValues.activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ $podValues.activeDeadlineSeconds }}
  {{- end }}
  {{- if $podValues.affinity }}
  affinity: {{ $podValues.affinity | toYaml | nindent 4 }}
  {{- end }}
  containers:
    {{- $containers := prepend ($podValues.sidecars | default list) $podValues }}
    {{- include "elCicdResources.containers" (list $ $containers) | trim | nindent 2 }}
  {{- if $podValues.dnsConfig }}
  dnsConfig: {{ $podValues.dnsConfig | toYaml | nindent 4 }}
  {{- end }}
  {{- if $podValues.dnsPolicy }}
  dnsPolicy: {{ $podValues.dnsPolicy }}
  {{- end }}
  {{- if $podValues.ephemeralContainers }} 
  ephemeralContainers:
    {{- include "elCicdResources.containers" (list $ $podValues.ephemeralContainers false) | trim | nindent 2 }}
  {{- end }}
  {{- if $podValues.hostIPC }}
  hostIPC: {{ $podValues.hostIPC }}
  {{- end }}
  {{- if $podValues.hostNetwork }}
  hostNetwork: {{ $podValues.hostNetwork }}
  {{- end }}
  {{- if $podValues.hostName }}
  hostname: {{ $podValues.hostName }}
  {{- end }}
  {{- $_ := set $podValues "imagePullSecrets" ($podValues.imagePullSecrets | default $.Values.global.defaultImagePullSecrets) }}
  {{- $_ := set $podValues "imagePullSecret" ($podValues.imagePullSecret | default $.Values.global.defaultImagePullSecret) }}
  {{- if $podValues.imagePullSecrets }}
  imagePullSecrets:
    {{- range $secretName := $podValues.imagePullSecrets }}
  - name: {{ $secretName }}
    {{- end }}
  {{- else if $podValues.imagePullSecret }}
  imagePullSecrets:
  - name: {{ $podValues.imagePullSecret }}
  {{- end }}
  {{- if $podValues.initContainers }} 
  initContainers:
    {{- include "elCicdResources.containers" (list $ $podValues.initContainers false) | trim | nindent 2 }}
  {{- end }}
  {{- if $podValues.os }}
  os: {{ $podValues.os }}
  {{- end }}
  {{- if $podValues.preemptionPolicy }}
  preemptionPolicy: {{ $podValues.preemptionPolicy }}
  {{- end }}
  {{- if $podValues.priority }}
  priority: {{ $podValues.priority }}
  {{- end }}
  {{- if $podValues.priorityClassName }}
  priorityClassName: {{ $podValues.priorityClassName }}
  {{- end }}
  {{- if $podValues.readinessGates }}
  readinessGates: {{ $podValues.readinessGates | toYaml | nindent 2 }}
  {{- end }}
  {{- if $podValues.runtimeClassName }}
  runtimeClassName: {{ $podValues.runtimeClassName }}
  {{- end }}
  {{- if $podValues.securityContext }}
  securityContext: {{ $podValues.securityContext | toYaml | nindent 4 }}
  {{- else }}
  securityContext:
    runAsNonRoot: true
    {{- if not $.Values.useLegacyPodSecurityContextDefault }}
    seccompProfile:
      type: RuntimeDefault
    {{- end }}
  {{- end }}
  {{- if $podValues.serviceAccountName }}
  serviceAccountName: {{ $podValues.serviceAccountName }}
  {{- end }}
  {{- if $podValues.setHostnameAsFQDN }}
  setHostnameAsFQDN: {{ $podValues.setHostnameAsFQDN }}
  {{- end }}
  {{- if $podValues.shareProcessNamespace }}
  shareProcessNamespace: {{ $podValues.shareProcessNamespace }}
  {{- end }}
  {{- if $podValues.subdomain }}
  subdomain: {{ $podValues.subdomain }}
  {{- end }}
  {{- if $podValues.terminationGracePeriodSeconds }}
  terminationGracePeriodSeconds: {{ $podValues.terminationGracePeriodSeconds }}
  {{- end }}
  {{- $_ := set $podValues "restartPolicy" ($podValues.restartPolicy | default "Always") }}
  restartPolicy: {{ $podValues.restartPolicy }}
  {{- if $podValues.schedulerName }}
  schedulerName: {{ $podValues.schedulerName }}
  {{- end }}
  {{- if $podValues.volumes }}
  volumes: {{- $podValues.volumes | toYaml | nindent 2 }}
  {{- end }}
{{- end }}

{{/*
Container definition
*/}}
{{- define "elCicdResources.containers" }}
{{- $ := index . 0 }}
{{- $containers := index . 1 }}
{{- range $containerVals := $containers }}
- name: {{ $containerVals.appName }}
  image: {{ $containerVals.image | default $.Values.global.defaultImage }}
 {{- if $containerVals.activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ $containerVals.activeDeadlineSeconds | toYaml | nindent 2 }}
  {{- end }}
  {{- if $containerVals.args }}
  args: {{ $containerVals.args | toYaml | nindent 2 }}
  {{- end }}
  {{- if $containerVals.command }}
  command: {{ $containerVals.command | toYaml | nindent 2 }}
  {{- end }}
  imagePullPolicy: {{ $containerVals.imagePullPolicy | default $.Values.global.defaultImagePullPolicy }}
  {{- if $containerVals.env }}
  env: {{ $containerVals.env | toYaml | nindent 2 }}
  {{- end }}
  {{- if $containerVals.envFrom }}
  envFrom: {{ $containerVals.envFrom | toYaml | nindent 2 }}
  {{- end }}
  {{- if $containerVals.lifecycle }}
  lifecycle: {{ $containerVals.lifecycle | toYaml | nindent 4 }}
  {{- end }}
  {{- if $containerVals.livenessProbe }}
  livenessProbe: {{ $containerVals.livenessProbe | toYaml | nindent 4 }}
  {{- end }}
  {{- if or $containerVals.ports $containerVals.port $.Values.global.defaultPort $containerVals.usePrometheus }}
  ports:
    {{- if and $containerVals.ports $containerVals.port }}
      {{- fail "A Container cannot define both port and ports values!" }}
    {{- end }}
    {{- if $containerVals.ports }}
      {{- $containerVals.ports | toYaml | nindent 2 }}
    {{- else if or $containerVals.port $.Values.global.defaultPort }}
  - name: default-port
    containerPort: {{ $containerVals.port | default $.Values.global.defaultPort }}
    protocol: {{ $containerVals.protocol | default $.Values.global.defaultProtocol }}
    {{- end }}
    {{- if or ($containerVals.prometheus).port (and $containerVals.usePrometheus $.Values.global.defaultPrometheusPort) }}
  - name: prometheus-port
    containerPort: {{ ($containerVals.prometheus).port | default $.Values.global.defaultPrometheusPort }}
    protocol: {{ ($containerVals.prometheus).protocol | default ($.Values.global.defaultPrometheusProtocol | default $.Values.global.defaultProtocol) }}
    {{- end }}
  {{- end }}
  {{- if $containerVals.readinessProbe }}
  readinessProbe: {{ $containerVals.readinessProbe | toYaml | nindent 4 }}
  {{- end }}
  resources:
    limits:
      cpu: {{ $containerVals.limitsCpu | default (($containerVals.resources).limits).cpu | default $.Values.global.defaultLimitsCpu }}
      memory: {{ $containerVals.limitsMemory | default (($containerVals.resources).limits).memory | default $.Values.global.defaultLimitsMemory }}
      {{- range $limit, $value := ($containerVals.resources).limits }}
        {{- if and (ne $limit "cpu") (ne $limit "memory") }}
      {{ $limit }}: {{ $value }}
        {{- end }}
      {{- end }}
    requests:
      cpu: {{ $containerVals.requestsCpu | default (($containerVals.resources).requests).cpu | default $.Values.global.defaultRequestsCpu }}
      memory: {{ $containerVals.requestsMemory | default (($containerVals.resources).requests).memory | default $.Values.global.defaultRequestsMemory }}
      {{- range $limit, $value := ($containerVals.resources).requests }}
        {{- if and (ne $limit "cpu") (ne $limit "memory") }}
      {{ $limit }}: {{ $value }}
        {{- end }}
      {{- end }}
  {{- if $containerVals.securityContext }}
  securityContext: {{ $containerVals.securityContext | toYaml | nindent 4 }}
  {{- else }}
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
      - ALL
  {{- end }}
  {{- if $containerVals.startupProbe }}
  startupProbe: {{ $containerVals.startupProbe | toYaml | nindent 4 }}
  {{- end }}
  {{- if $containerVals.stdin }}
  stdin: {{ $containerVals.stdin }}
  {{- end }}
  {{- if $containerVals.stdinOnce }}
  stdinOnce: {{ $containerVals.stdinOnce }}
  {{- end }}
  {{- if $containerVals.terminationMessagePath }}
  terminationMessagePath: {{ $containerVals.terminationMessagePath }}
  {{- end }}
  {{- if $containerVals.terminationMessagePolicy }}
  terminationMessagePolicy: {{ $containerVals.terminationMessagePolicy }}
  {{- end }}
  {{- if $containerVals.tty }}
  tty: {{ $containerVals.tty }}
  {{- end }}
  {{- if $containerVals.volumeDevices }}
  volumeDevices: {{ $containerVals.volumeDevices | toYaml | nindent 2 }}
  {{- end }}
  {{- if $containerVals.volumeMounts }}
  volumeMounts: {{ $containerVals.volumeMounts | toYaml | nindent 2 }}
  {{- end }}
  {{- if or $containerVals.workingDir $containerVals.defaultWorkingDir }}
  workingDir: {{ $containerVals.workingDir | default $containerVals.defaultWorkingDir }}
  {{- end }}
  {{- if $containerVals.supplemental }}
    {{- $containerVals.supplemental | toYaml | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Service Prometheus Annotations definition
*/}}
{{- define "elCicdResources.svcPrometheusAnnotations" }}
  {{- $ := index . 0 }}
  {{- $svcValues := index . 1 }}
  {{- $_ := set $svcValues "annotations" ($svcValues.annotations | default dict) }}

  {{- if or ($svcValues.prometheus).path $.Values.global.defaultPrometheusPath }}
    {{- $_ := set $svcValues.annotations "prometheus.io/path" ($svcValues.prometheus.path | default $.Values.global.defaultPrometheusPath) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).port $.Values.global.defaultPrometheusPort }}
    {{- $_ := set $svcValues.annotations "prometheus.io/port" ($svcValues.prometheus.port | default $svcValues.port) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).scheme $.Values.global.defaultPrometheusScheme }}
    {{- $_ := set $svcValues.annotations "prometheus.io/scheme" ($svcValues.prometheus.scheme | default $.Values.global.defaultPrometheusScheme) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).scrape $.Values.global.defaultPrometheusScrape }}
    {{- $_ := set $svcValues.annotations "prometheus.io/scrape" ($svcValues.prometheus.scrape | default $.Values.global.defaultPrometheusScrape) }}
  {{- end }}
{{- end }}

{{/*
Service Prometheus 3Scale definition
*/}}
{{- define "elCicdResources.3ScaleAnnotations" }}
  {{- $ := index . 0 }}
  {{- $svcValues := index . 1 }}
  {{- $_ := set $svcValues "annotations" ($svcValues.annotations | default dict) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/path" ($svcValues.threeScale.port | default $svcValues.port | default $.Values.global.defaultPort) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/port" ($svcValues.threeScale.path | default $.Values.global.default3ScalePath) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/scheme" ($svcValues.threeScale.scheme | default $.Values.global.default3ScaleScheme) }}
{{- end }}