{{/*
  Defines templates for rendering Kubernetes workload resources, including:
  - CronJob
  - Deployment
  - HorizontalPodAutoscaler
  - Job
  - StatefulSet
*/}}

{{/*
  ======================================
  elcicd-kubernetes.cronjob
  ======================================

  PARAMETERS LIST:
    . -> should be root of chart
    $cjValues -> elCicd template

  ======================================

  HELPER KEYS:
    [spec]:
      schedule
      concurrencyPolicy
      failedJobsHistoryLimit
      startingDeadlineSeconds
      successfulJobsHistoryLimit
      parallelism
      ttlSecondsAfterFinished

  ======================================

  el-CICD SUPPORTING TEMPLATES:
    "elcicd-common.apiObjectHeader"
    spec:
      jobTemplate:
        "elcicd-kubernetes.jobTemplate"

  ======================================

  Defines a el-CICD template for a Kubernetes CronJob.
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
                         "parallelism"
                         "schedule"
                         "startingDeadlineSeconds"
                         "successfulJobsHistoryLimit"
                         "ttlSecondsAfterFinished" }}
  {{- include "elcicd-common.outputToYaml" (list $ $cjValues $whiteList) }}
  jobTemplate: {{ include "elcicd-kubernetes.jobTemplate" . | indent 4 }}
{{- end }}

{{/*
  ======================================
  elcicd-kubernetes.deployment
  ======================================

  PARAMETERS LIST:
    . -> should be root of chart
    $deployValues -> elCicd template for Deployment

  ======================================

  HELPER KEYS
  ---
  [spec]:
    revisionHistoryLimit -> .Values.elCicdDefaults.deploymentRevisionHistoryLimit
  ---
  [spec]:
    [strategy]:
      [type]: strategyType
      [rollingUpdate -> strategyType == "RollingUpdate"]:
        rollingUpdateMaxSurge -> .Values.elCicdDefaults.rollingUpdateMaxSurge
        rollingUpdateMaxUnavailable -> .Values.elCicdDefaults.rollingUpdateMaxUnavailable

  ======================================

  DEFAULT KEYS
  ---  
    [spec]:
      minReadySeconds
      progressDeadlineSeconds
      replicas

  ======================================

  el-CICD SUPPORTING TEMPLATES:
    "elcicd-common.apiObjectHeader"
    spec:
      template:
        "elcicd-kubernetes.podTemplate"

  ======================================

  Defines a el-CICD template for a Kubernetes Deployment.
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
  ======================================
  elcicd-kubernetes.horizontalPodAutoscaler
  ======================================

  PARAMETERS LIST:
    . -> should be root of chart
    $hpaValues -> elCicd template for HorizontalPodAutoscaler

  ======================================

  DEFAULT KEYS
  ---
    [spec]:
      behavior
      maxReplicas
      minReplicas
      scaleTargetRef
        apiVersion -> / "apps/v1"
        kind -> / "Deployment"
        name -> / $<OBJ_NAME>
    ---
    [spec]:
      [metrics]:
      - type:
        [<type>]:
          container
          describedObject
          name
          metric
          target

  ======================================

  el-CICD SUPPORTING TEMPLATES
  ---
    "elcicd-common.apiObjectHeader"

  ======================================

  Defines a el-CICD template for a Kubernetes HorizontalPodAutoscaler.
  
  Defining hpa metrics in the el-CICD template:
  
    metrics:
    - type: <type>
      name: <name>
      target:
        <target def per hpa>
  
  Will generate in the final YAML:
  
  spec:
    metrics:
    - type: <Type> # note the title case
      <type>:
        name: <name>
        target:
          <target def per hpa>
        
  The el-CICD template only require defining hpa the type, and el-CICD template will generate the correct
  YAML structure.        
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
    {{- $whiteList := list "container"
                           "describedObject"
                           "name"
                           "metric"
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
  ======================================
  elcicd-kubernetes.job
  ======================================

  PARAMETERS LIST:
    . -> should be root of chart
    $jobValues -> elCicd template for Job

  ======================================

  el-CICD SUPPORTING TEMPLATES
  ---
    "elcicd-common.apiObjectHeader"
    "elcicd-kubernetes.jobSpec"

  ======================================

  Defines a el-CICD template for a Kubernetes Job.
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
  ======================================
  elcicd-kubernetes.statefulset
  ======================================

  PARAMETERS LIST:
    . -> should be root of chart
    $deployValues -> elCicd template for StatefulSet

  ======================================

  DEFAULT KEYS:
  ---
   [spec]:
      minReadySeconds
      persistentVolumeClaimRetentionPolicy
      podManagementPolicy
      replicas
      revisionHistoryLimit
      updateStrategy
      volumeClaimTemplates

  ======================================

  el-CICD SUPPORTING TEMPLATES
  ---
    "elcicd-common.apiObjectHeader"
    spec:
      "elcicd-kubernetes.podSelector"
      template:
        "elcicd-kubernetes.podTemplate"

  ======================================

  Defines a el-CICD template for a Kubernetes Deployment.
*/}}
{{- define "elcicd-kubernetes.statefulset" }}
{{- $ := index . 0 }}
{{- $stsValues := index . 1 }}
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