{{/*
CronJob
*/}}
{{- define "elCicdResources.cronjob" }}
{{- $ := index . 0 }}
{{- $cjValues := index . 1 }}
{{- $_ := set $cjValues "kind" "CronJob" }}
{{- $_ := set $cjValues "apiVersion" "batch/v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
spec:
  {{- if $cjValues.concurrencyPolicy }}
  concurrencyPolicy: {{ $cjValues.concurrencyPolicy }}
  {{- end }}
  {{- if $cjValues.failedJobsHistoryLimit }}
  failedJobsHistoryLimit: {{ $cjValues.failedJobsHistoryLimit }}
  {{- end }}
  schedule: "{{ $cjValues.schedule }}"
  {{- if $cjValues.startingDeadlineSeconds }}
  startingDeadlineSeconds: {{ $cjValues.startingDeadlineSeconds }}
  {{- end }}
  {{- if $cjValues.successfulJobsHistoryLimit }}
  successfulJobsHistoryLimit: {{ $cjValues.successfulJobsHistoryLimit }}
  {{- end }}
  jobTemplate: {{ include "elCicdResources.jobTemplate" . | indent 4 }}
{{- end }}

{{/*
Deployment
*/}}
{{- define "elCicdResources.deployment" }}
{{- $ := index . 0 }}
{{- $deployValues := index . 1 }}
{{- $_ := set $deployValues "kind" "Deployment" }}
{{- $_ := set $deployValues "apiVersion" "apps/v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
spec:
  {{- if $deployValues.minReadySeconds }}
  minReadySeconds: {{ $deployValues.minReadySeconds }}
  {{- end }}
  {{- if $deployValues.progressDeadlineSeconds }}
  progressDeadlineSeconds: {{ $deployValues.progressDeadlineSeconds }}
  {{- end }}
  replicas: {{ $deployValues.replicas | default $.Values.global.defaultReplicas }}
  revisionHistoryLimit: {{ $deployValues.revisionHistoryLimit | default $.Values.global.defaultDeploymentRevisionHistoryLimit }}
  selector: {{ include "elCicdResources.selector" . | indent 4 }}
  {{- if $deployValues.strategyType }}
  strategy:
    {{- if (eq $deployValues.strategyType "RollingUpdate") }}
    rollingUpdate:
      maxSurge: {{ $deployValues.rollingUpdateMaxSurge | default $.Values.global.defaultRollingUpdateMaxSurge }}
      maxUnavailable: {{ $deployValues.rollingUpdateMaxUnavailable | default $.Values.global.defaultRollingUpdateMaxUnavailable }}
    {{- end }}
    type: {{ $deployValues.strategyType }}
  {{- end }}
  template: {{ include "elCicdResources.podTemplate" (list $ $deployValues) | indent 4 }}
{{- end }}

{{/*
HorizontalPodAutoscaler
*/}}
{{- define "elCicdResources.horizontalPodAutoscaler" }}
{{- $ := index . 0 }}
{{- $hpaValues := index . 1 }}
{{- $_ := set $hpaValues "kind" "HorizontalPodAutoscaler" }}
{{- $_ := set $hpaValues "apiVersion" "autoscaling/v2" }}
{{- include "elCicdResources.apiObjectHeader" . }}
spec:
  {{- if or $hpaValues.scaleDownBehavior $hpaValues.scaleDownUp }}
  behavior:
  {{- if or $hpaValues.scaleDownBehavior}}
    scaleDown: {{- $hpaValues.scaleDownBehavior | toYaml | nindent 6 }}
  {{- end }}
  {{- if or $hpaValues.scaleDownUp }}
    scaleUp: {{- $hpaValues.scaleDownUp | toYaml | nindent 6 }}
  {{- end }}
  {{- end }}
  maxReplicas: {{ required "Missing maxReplicas!" ($hpaValues.maxReplicas | default $.Values.global.defaultHpaMaxReplicas) }}
  {{- if $hpaValues.minReplicas }}
  minReplicas: {{ $hpaValues.minReplicas }}
  {{- end }}
  {{- if $hpaValues.metrics }}
  metrics:
  {{- range $metric := $hpaValues.metrics }}
  - type: {{ $metric.type }}
    {{ lower $metric.type }}:
      {{- if $metric.name }}
      name: {{ $metric.name }}
      {{- end }}
      {{- if $metric.container }}
      container: {{ $metric.container }}
      {{- end }}
      {{- if $metric.metric }}
      metric: {{- $metric.metric | toYaml | nindent 8 }}
      {{- end }}
      {{- if $metric.describedObject }}
      describedObject: {{- $metric.describedObject | toYaml | nindent 8 }}
      {{- end }}
      target: {{- $metric.target | toYaml | nindent 8 }}
  {{- end }}
  {{- end }}
  scaleTargetRef:
    {{- if ($hpaValues.scaleTargetRef).apiVersion }}
    apiVersion: {{ $hpaValues.scaleTargetRef.apiVersion }}
    {{- end }}
    kind: {{ ($hpaValues.scaleTargetRef).kind | default "Deployment" }}
    name: {{ ($hpaValues.scaleTargetRef).name | default $hpaValues.appName }}
{{- end }}

{{/*
Job
*/}}
{{- define "elCicdResources.job" }}
{{- $ := index . 0 }}
{{- $jobValues := index . 1 }}
{{- $_ := set $jobValues "kind" "Job" }}
{{- $_ := set $jobValues "apiVersion" "batch/v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
spec:
{{- include "elCicdResources.jobTemplate" . }}
{{- end }}

{{/*
Stateful Set
*/}}
{{- define "elCicdResources.statefulset" }}
{{- $ := index . 0 }}
{{- $stsValues := index . 1 }}
{{- if ($stsValues.createService | default true) }}
  {{- $_ := set $stsValues "clusterIP" "None" }}
  {{- include "elCicdResources.service" $stsValues }}
{{- end }}
{{- $_ := set $stsValues "kind" "StatefulSet" }}
{{- $_ := set $stsValues "apiVersion" "apps/v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
spec:
  {{- if $stsValues.minReadySeconds }}
  minReadySeconds: {{ $stsValues.minReadySeconds }}
  {{- end }}
  {{- if $stsValues.pvcRetentionPolicy }}
  persistentVolumeClaimRetentionPolicy: {{- $stsValues.pvcRetentionPolicy | toYaml | nindent 4 }}
  {{- end }}
  {{- if $stsValues.podManagementPolicy }}
  podManagementPolicy: {{ $stsValues.podManagementPolicy }}
  {{- end }}
  replicas: {{ $stsValues.replicas | default $.Values.global.defaultReplicas }}
  {{- if $stsValues.revisionHistoryLimit }}
  revisionHistoryLimit: {{ $stsValues.revisionHistoryLimit }}
  {{- end }}
  selector: {{ include "elCicdResources.selector" . | indent 4 }}
  serviceName: {{ $stsValues.appName }}
  template:
  {{- include "elCicdResources.selector" $stsValues.appName | indent 2 }}
  {{- include "elCicdResources.podTemplate" (list $ $stsValues) | indent 4 }}
  {{- if $stsValues.updateStrategy }}
  updateStrategy: {{- $stsValues.updateStrategy | toYaml | nindent 4 }}
  {{- end }}
  {{- if $stsValues.volumeClaimTemplates }}
  volumeClaimTemplates: {{- $stsValues.volumeClaimTemplates | toYaml | nindent 4 }}
  {{- end }}
{{- end }}