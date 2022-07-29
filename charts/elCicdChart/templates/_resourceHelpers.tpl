{{- $_ := set . "UNDEFINED" "undefined" -}}

{{/*
Deployment and Service combination
*/}}
{{- define "elCicdChart.deploymentService" }}
  {{- include "elCicdChart.deployment" . }}
  {{- include "elCicdChart.service" . }}
{{- end }}

{{/*
HorizontalPodAutoscaler Metrics
*/}}
{{- define "elCicdChart.hpaMetrics" }}
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
{{- define "elCicdChart.jobTemplate" }}
{{- $ := index . 0 }}
{{- $jobValues := index . 1 }}
{{- include "elCicdChart.apiMetadata" . }}
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
  template: {{ include "elCicdChart.podTemplate" (list $ $jobValues false) | indent 4 }}
  {{- if $jobValues.ttlSecondsAfterFinished }}
  ttlSecondsAfterFinished: {{ $jobValues.ttlSecondsAfterFinished }}
  {{- end }}
{{- end }}

{{/*
Pod Template
*/}}
{{- define "elCicdChart.podTemplate" }}
{{- $ := index . 0 }}
{{- $podValues := index . 1 }}
{{- include "elCicdChart.apiMetadata" . }}
spec:
  {{- if $podValues.activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ $podValues.activeDeadlineSeconds }}
  {{- end }}
  {{- if $podValues.affinity }}
  affinity: {{ $podValues.affinity | toYaml | nindent 4 }}
  {{- end }}
  {{- $_ := set $podValues "restartPolicy" ($podValues.restartPolicy | default "Always") }}
  restartPolicy: {{ $podValues.restartPolicy }}
  imagePullSecrets:
  - name: {{ $.Values.pullSecret }}
  {{- if $podValues.pullSecrets }}
  {{- range $secretName := $podValues.pullSecrets }}
  - name: {{ $secretName }}
  {{- end }}
  {{- end }}
  {{- if $podValues.ephemeralContainers }} 
  ephemeralContainers:
    {{- include "elCicdChart.ephemeralContainers" (list $ $podValues.ephemeralContainers false) | trim | nindent 2 }}
  {{- end }}
  {{- if $podValues.initContainers }} 
  initContainers:
    {{- include "elCicdChart.initContainers" (list $ $podValues.initContainers false) | trim | nindent 2 }}
  {{- end }}
  containers:
    {{- $containers := prepend ($podValues.sidecars | default list) $podValues }}
    {{- include "elCicdChart.containers" (list $ $containers) | trim | nindent 2 }}
  {{- if $podValues.volumes }}
  volumes: {{- $podValues.volumes | toYaml | nindent 2 }}
  {{- end }}
{{- end }}

{{/*
Container definition
*/}}
{{- define "elCicdChart.containers" }}
{{- $ := index . 0 }}
{{- $containers := index . 1 }}
{{- range $containerVals := $containers }}
- name: {{ $containerVals.appName }}
  image: {{ $containerVals.image | default (include "elCicdChart.microServiceImage" $) }}
 {{- if $containerVals.activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ $containerVals.activeDeadlineSeconds | toYaml | nindent 2 }}
  {{- end }}
  {{- if $containerVals.args }}
  args: {{ $containerVals.args | toYaml | nindent 2 }}
  {{- end }}
  {{- if $containerVals.command }}
  command: {{ $containerVals.command | toYaml | nindent 2 }}
  {{- end }}
  imagePullPolicy: {{ $containerVals.imagePullPolicy | default $.Values.defaultImagePullPolicy }}
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
  {{- if or $containerVals.ports $containerVals.port $.Values.defaultPort $containerVals.usePrometheus }}
  ports:
    {{- if and $containerVals.ports $containerVals.port }}
      {{- fail "A Container cannot define both port and ports values (perhaps a merge caused this?)!" }}
    {{- end }}
    {{- if $containerVals.ports }}
      {{- $containerVals.ports | toYaml | nindent 2 }}
    {{- else if or $containerVals.port $.Values.defaultPort }}
  - name: default-port
    containerPort: {{ $containerVals.port | default $.Values.defaultPort }}
    protocol: {{ $containerVals.protocol | default $.Values.defaultProtocol }}
    {{- end }}
    {{- if or ($containerVals.prometheus).port $.Values.defaultPrometheusPort }}
  - name: prometheus-port
    containerPort: {{ $containerVals.prometheus.port | default $.Values.defaultPrometheusPort }}
    protocol: {{ $containerVals.prometheus.protocol | default ($.Values.defaultPrometheusProtocol | default $.Values.defaultProtocol) }}
    {{- end }}
  {{- end }}
  {{- if $containerVals.readinessProbe }}
  readinessProbe: {{ $containerVals.readinessProbe | toYaml | nindent 4 }}
  {{- end }}
  resources:
    limits:
      cpu: {{ $containerVals.limitsCpu | default $.Values.defaultLimitsCpu }}
      memory: {{ $containerVals.limitsMemory | default $.Values.defaultLimitsMemory }}
    requests:
      cpu: {{ $containerVals.requestsCpu | default $.Values.defaultRequestsCpu }}
      memory: {{ $containerVals.requestsMemory | default $.Values.defaultRequestsMemory }}
  {{- if $containerVals.startupProbe }}
  startupProbe: {{ $containerVals.startupProbe | toYaml | nindent 4 }}
  {{- end }}
  {{- if $containerVals.stdin }}
  stdin: {{ $containerVals.stdin }}
  {{- end }}
  {{- if $containerVals.stdinOnce }}
  stdinOnce: {{ $containerVals.stdinOnce }}
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
Default image definition
*/}}
{{- define "elCicdChart.microServiceImage" }}
  {{- $.Values.imageRepository }}/{{- $.Values.projectId }}-{{- $.Values.microService }}:{{- $.Values.imageTag }}
{{- end }}

{{/*
Service Prometheus Annotations definition
*/}}
{{- define "elCicdChart.svcPrometheusAnnotations" }}
  {{- $ := index . 0 }}
  {{- $svcValues := index . 1 }}
  {{- $_ := set $svcValues "annotations" ($svcValues.annotations | default dict) }}

  {{- if or ($svcValues.prometheus).path $.Values.defaultPrometheusPath }}
    {{- $_ := set $svcValues.annotations "prometheus.io/path" ($svcValues.prometheus.path | default $.Values.defaultPrometheusPath) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).port $.Values.defaultPrometheusPort }}
    {{- $_ := set $svcValues.annotations "prometheus.io/port" ($svcValues.prometheus.port | default $svcValues.port) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).scheme $.Values.defaultPrometheusScheme }}
    {{- $_ := set $svcValues.annotations "prometheus.io/scheme" ($svcValues.prometheus.scheme | default $.Values.defaultPrometheusScheme) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).scrape $.Values.defaultPrometheusScrape }}
    {{- $_ := set $svcValues.annotations "prometheus.io/scrape" ($svcValues.prometheus.scrape | default $.Values.defaultPrometheusScrape) }}
  {{- end }}
{{- end }}

{{/*
Service Prometheus 3Scale definition
*/}}
{{- define "elCicdChart.3ScaleAnnotations" }}
  {{- $ := index . 0 }}
  {{- $svcValues := index . 1 }}
  {{- $_ := set $svcValues "annotations" ($svcValues.annotations | default dict) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/path" ($svcValues.threeScale.port | default $svcValues.port | default $.Values.defaultPort) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/port" ($svcValues.threeScale.path | default $.Values.default3ScalePath) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/scheme" ($svcValues.threeScale.scheme | default $.Values.default3ScaleScheme) }}
{{- end }}