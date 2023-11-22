{{/*
CronJob
*/}}
{{- define "elcicd-kubernetes.cronjob" }}
{{- $ := index . 0 }}
{{- $cjValues := index . 1 }}
{{- $_ := set $cjValues "kind" "CronJob" }}
{{- $_ := set $cjValues "apiVersion" "batch/v1" }}
{{- include "elcicd-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "concurrencyPolicy"	
                         "failedJobsHistoryLimit"	
                         "startingDeadlineSeconds"	
                         "successfulJobsHistoryLimit"	
                         "parallelism"	
                         "ttlSecondsAfterFinished" }}
  schedule: "{{ $cjValues.schedule}}"
  {{- include "elcicd-common.outputToYaml" (list $ $cjValues $whiteList) }}
  jobTemplate: {{ include "elcicd-kubernetes.jobTemplate" . | indent 4 }}
{{- end }}

{{/*
Deployment
*/}}
{{- define "elcicd-kubernetes.deployment" }}
{{- $ := index . 0 }}
{{- $deployValues := index . 1 }}
{{- $_ := set $deployValues "kind" "Deployment" }}
{{- $_ := set $deployValues "apiVersion" "apps/v1" }}
{{- include "elcicd-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "minReadySeconds"	
                         "progressDeadlineSeconds"
                         "replicas" }}
  {{- include "elcicd-common.outputToYaml" (list $ $deployValues $whiteList) }}
  revisionHistoryLimit: {{ ($deployValues.revisionHistoryLimit | default $.Values.elCicdDefaults.deploymentRevisionHistoryLimit) | int }}
  {{- include "elcicd-kubernetes.podSelector" . | indent 2 }}
  {{- if $deployValues.strategyType }}
  strategy:
    {{- if (eq $deployValues.strategyType "RollingUpdate") }}
    rollingUpdate:
      maxSurge: {{ $deployValues.rollingUpdateMaxSurge | default $.Values.elCicdDefaults.rollingUpdateMaxSurge }}
      maxUnavailable: {{ $deployValues.rollingUpdateMaxUnavailable | default $.Values.elCicdDefaults.rollingUpdateMaxUnavailable }}
    {{- end }}
    type: {{ $deployValues.strategyType }}
  {{- end }}
  template: {{ include "elcicd-kubernetes.podTemplate" (list $ $deployValues) | indent 4 }}
{{- end }}

{{/*
HorizontalPodAutoscaler
*/}}
{{- define "elcicd-kubernetes.horizontalPodAutoscaler" }}
{{- $ := index . 0 }}
{{- $hpaValues := index . 1 }}
{{- $_ := set $hpaValues "kind" "HorizontalPodAutoscaler" }}
{{- $_ := set $hpaValues "apiVersion" "autoscaling/v2" }}
{{- include "elcicd-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "behavior"	
                         "maxReplicas"	
                         "minReplicas" }}
  {{- include "elcicd-common.outputToYaml" (list $ $hpaValues $whiteList) }}
  {{- if $hpaValues.metrics }}
  metrics:
    {{- $whiteList := list "name"	
                           "container"	
                           "metric"
                           "describedObject"
                           "target" }}
    {{- range $metric := $hpaValues.metrics }}
    {{- $metricType := $metric.type }}
  - type: {{ title $metricType }}
    {{ $metricType }}: {{ include "elcicd-common.outputToYaml" (list $ $metric $whiteList) | indent 4 }}
    {{- end }}
  {{- end }}
  scaleTargetRef:
    apiVersion: {{ ($hpaValues.scaleTargetRef).apiVersion | default "apps/v1"  }}
    kind: {{ ($hpaValues.scaleTargetRef).kind | default "Deployment" }}
    name: {{ ($hpaValues.scaleTargetRef).name | default $hpaValues.objName }}
{{- end }}

{{/*
Job
*/}}
{{- define "elcicd-kubernetes.job" }}
{{- $ := index . 0 }}
{{- $jobValues := index . 1 }}
{{- $_ := set $jobValues "kind" "Job" }}
{{- $_ := set $jobValues "apiVersion" "batch/v1" }}
{{- include "elcicd-common.apiObjectHeader" . }}
{{- include "elcicd-kubernetes.jobSpec" . }}
{{- end }}

{{/*
Stateful Set
*/}}
{{- define "elcicd-kubernetes.statefulset" }}
{{- $ := index . 0 }}
{{- $stsValues := index . 1 }}
{{- if ($stsValues.createService | default true) }}
  {{- $_ := set $stsValues "clusterIP" "None" }}
  {{- include "elcicd-kubernetes.service" $stsValues }}
{{- end }}
{{- $_ := set $stsValues "kind" "StatefulSet" }}
{{- $_ := set $stsValues "apiVersion" "apps/v1" }}
{{- include "elcicd-common.apiObjectHeader" . }}
spec:
  {{- $whiteList := list "minReadySeconds"	
                         "persistentVolumeClaimRetentionPolicy" 
                         "podManagementPolicy" 
                         "replicas" 
                         "revisionHistoryLimit" 
                         "updateStrategy" 
                         "volumeClaimTemplates" }}
  {{- include "elcicd-common.outputToYaml" (list $ $stsValues $whiteList) }}
  {{- include "elcicd-kubernetes.podSelector" . | indent 2 }}
  template:
  {{- include "elcicd-kubernetes.podTemplate" (list $ $stsValues) | indent 4 }}
{{- end }}