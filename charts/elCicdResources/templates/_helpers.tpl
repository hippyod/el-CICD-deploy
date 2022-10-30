
{{/*
Iniitialize elCicdResources chart
*/}}
{{- define "elCicdResources.initElCicdResources" }}
  {{- $ := . }}
  
  {{- $_ := set $.Values "defaultDeploymentRevisionHistoryLimit" ($.Values.defaultDeploymentRevisionHistoryLimit | default 0) }}

  {{- $_ := set $.Values "defaultImagePullPolicy" ($.Values.defaultDeploymentRevisionHistoryLimit | default "Always") }}

  {{- $_ := set $.Values "defaultPort" ($.Values.defaultDeploymentRevisionHistoryLimit | default "8080") }}
  {{- $_ := set $.Values "defaultProtocol" ($.Values.defaultDeploymentRevisionHistoryLimit | default "TCP") }}

  {{- $_ := set $.Values "defaultLimitsCpu" ($.Values.defaultDeploymentRevisionHistoryLimit | default "200m") }}
  {{- $_ := set $.Values "defaultLimitsMemory" ($.Values.defaultDeploymentRevisionHistoryLimit | default "500Mi") }}

  {{- $_ := set $.Values "defaultRequestsCpu" ($.Values.defaultDeploymentRevisionHistoryLimit | default "100m") }}
  {{- $_ := set $.Values "defaultRequestsMemory" ($.Values.defaultDeploymentRevisionHistoryLimit | default "50Mi") }}

  {{- $_ := set $.Values "defaultIngressRulePath" ($.Values.defaultDeploymentRevisionHistoryLimit | default "/") }}
  {{- $_ := set $.Values "defaultIngressRulePathType" ($.Values.defaultDeploymentRevisionHistoryLimit | default "Prefix") }}

  {{- $_ := set $.Values "defaultPvReclaimPolicy" ($.Values.defaultDeploymentRevisionHistoryLimit | default "Reclaim") }}
  {{- $_ := set $.Values "defaultPvAccessMode" ($.Values.defaultDeploymentRevisionHistoryLimit | default "ReadWriteOnce") }}

  {{- $_ := set $.Values "defaultPrometheusPort" ($.Values.defaultDeploymentRevisionHistoryLimit | default "9090") }}
  {{- $_ := set $.Values "defaultPrometheusPath" ($.Values.defaultDeploymentRevisionHistoryLimit | default "/metrics") }}
  {{- $_ := set $.Values "defaultPrometheusScheme" ($.Values.defaultDeploymentRevisionHistoryLimit | default "https") }}
  {{- $_ := set $.Values "defaultPrometheusScrape" ($.Values.defaultDeploymentRevisionHistoryLimit | default "false") }}
  {{- $_ := set $.Values "defaultPrometheusProtocol" ($.Values.defaultDeploymentRevisionHistoryLimit | default "TCP") }}

  {{- $_ := set $.Values "default3ScaleScheme" ($.Values.defaultDeploymentRevisionHistoryLimit | default "https") }}
{{- end }}



{{/*
General Metadata Template
*/}}
{{- define "elCicdResources.apiObjectHeader" }}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
apiVersion: {{ $template.apiVersion }}
kind: {{ $template.kind }}
{{- include "elCicdResources.apiMetadata" . }}
{{- end }}

{{- define "elCicdResources.apiMetadata" }}
{{- $ := index . 0 }}
{{- $metadataValues := index . 1 }}
metadata:
  {{- if or $metadataValues.annotations $.Values.defaultAnnotations }}
  annotations:
    {{- if $metadataValues.annotations }}
      {{- range $key, $value := $metadataValues.annotations }}
    {{ $key }}: {{ $value | quote }}
      {{- end }}
    {{- end }}
    {{- if $.Values.defaultAnnotations}}
      {{- $.Values.defaultAnnotations | toYaml | nindent 4 }}
    {{- end }}
  {{- end }}
  labels:
    {{- include "elCicdResources.labels" . | indent 4 }}
    {{- range $key, $value := $metadataValues.labels }}
    {{ $key }}: "{{ $value }}"
    {{- end }}
    {{- range $key, $value := $.Values.labels }}
    {{ $key }}: "{{ $value }}"
    {{- end }}
    {{- range $key, $value := $.Values.defaultLabels }}
    {{ $key }}: "{{ $value }}"
    {{- end }}
  name: {{ required "Unnamed apiObject Name!" $metadataValues.appName }}
  {{- if $metadataValues.namespace }}
  namespace: {{ $metadataValues.namespace }}
  {{- end }}
{{- end }}

{{/*
el-CICD Selector
*/}}
{{- define "elCicdResources.selector" }}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
matchExpressions:
- key: app
  operator: Exists
{{- if $template.matchExpressions }}
  {{- $template.matchExpressions | toYaml }}
{{- end }}
matchLabels:
  {{- include "elCicdResources.selectorLabels" . | indent 2 }}
{{- if $template.matchLabels }}
  {{- $template.matchLabels | toYaml | indent 2 }}
{{- end }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "elCicdResources.name" -}}
{{- default $.Chart.Name $.Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "elCicdResources.chart" -}}
{{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "elCicdResources.labels" -}}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
{{- include "elCicdResources.selectorLabels" . }}
helm.sh/chart: {{ include "elCicdResources.chart" $ }}
{{- if $.Chart.AppVersion }}
app.kubernetes.io/version: {{ $.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "elCicdResources.selectorLabels" -}}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
app: {{ $template.appName }}
{{- end }}

{{/*
Service Prometheus Annotations definition
*/}}
{{- define "elCicdResources.prometheusAnnotations" }}
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
{{- define "elCicdResources.3ScaleAnnotations" }}
  {{- $ := index . 0 }}
  {{- $svcValues := index . 1 }}
  {{- $_ := set $svcValues "annotations" ($svcValues.annotations | default dict) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/path" ($svcValues.threeScale.port | default $svcValues.port | default $.Values.defaultPort) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/port" ($svcValues.threeScale.path | default $.Values.default3ScalePath) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/scheme" ($svcValues.threeScale.scheme | default $.Values.default3ScaleScheme) }}
{{- end }}

{{- define "elCicdResources.outputToYaml" }}
  {{- $templateVals := index . 0 }}
  {{- $whiteList := index . 1 }}
  {{- range $key, $value := $templateVals }}
    {{- if or (has $key $whiteList) (empty $whiteList)}}
      {{- if or (kindIs "slice" $value) (kindIs "map" $value) }}
  {{ $key }}:
    {{- $value | toYaml | nindent 4 }}
      {{- else }}
  {{ $key }}: {{ $value }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}