
{{/*
Iniitialize elCicdResources chart
*/}}
{{- define "elCicdResources.initElCicdResources" }}
  {{- $ := . }}
  
  {{- $_ := set $.Values "elCicdDefaults" ($.Values.elCicdDefaults | default dict) }}
  
  {{- $_ := set $.Values.elCicdDefaults "deploymentRevisionHistoryLimit" ($.Values.elCicdDefaults.deploymentRevisionHistoryLimit | default 0) }}

  {{- $_ := set $.Values.elCicdDefaults "imagePullPolicy" ($.Values.elCicdDefaults.imagePullPolicy | default "Always") }}

  {{- $_ := set $.Values.elCicdDefaults "port" ($.Values.elCicdDefaults.port | default "8080") }}
  {{- $_ := set $.Values.elCicdDefaults "protocol" ($.Values.elCicdDefaults.protocol | default "TCP") }}

  {{- $_ := set $.Values.elCicdDefaults "limitsCpu" ($.Values.elCicdDefaults.limitsCpu | default "200m") }}
  {{- $_ := set $.Values.elCicdDefaults "limitsMemory" ($.Values.elCicdDefaults.limitsMemory | default "500Mi") }}

  {{- $_ := set $.Values.elCicdDefaults "requestsCpu" ($.Values.elCicdDefaults.requestsCpu | default "100m") }}
  {{- $_ := set $.Values.elCicdDefaults "requestsMemory" ($.Values.elCicdDefaults.requestsMemory | default "50Mi") }}

  {{- $_ := set $.Values.elCicdDefaults "ingressRulePath" ($.Values.elCicdDefaults.ingressRulePath | default "/") }}
  {{- $_ := set $.Values.elCicdDefaults "ingressRulePathType" ($.Values.elCicdDefaults.ingressRulePathType | default "Prefix") }}

  {{- $_ := set $.Values.elCicdDefaults "prometheusPort" ($.Values.elCicdDefaults.prometheusPort | default "9090") }}
  {{- $_ := set $.Values.elCicdDefaults "prometheusPath" ($.Values.elCicdDefaults.prometheusPath | default "/metrics") }}
  {{- $_ := set $.Values.elCicdDefaults "prometheusScheme" ($.Values.elCicdDefaults.prometheusScheme | default "https") }}
  {{- $_ := set $.Values.elCicdDefaults "prometheusScrape" ($.Values.elCicdDefaults.prometheusScrape | default "false") }}
  {{- $_ := set $.Values.elCicdDefaults "prometheusProtocol" ($.Values.elCicdDefaults.prometheusProtocol | default "TCP") }}

  {{- $_ := set $.Values.elCicdDefaults "3ScaleScheme" ((get $.Values.elCicdDefaults "3ScaleScheme") | default "https") }}
{{- end }}



{{/*
General Metadata Template
*/}}
{{- define "elCicdResources.apiObjectHeader" }}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
apiVersion: {{ $template.apiVersion }}
kind: {{ $template.kind }}
{{- $_ := set $.Values "currentTemplateKind"  $template.kind }}
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
    {{ $_ := set $metadataValues "labels" (mergeOverwrite ($metadataValues.labels | default dict) $.Values.defaultLabels) }}
    {{- include "elCicdResources.labels" . | indent 4 }}
    {{- range $key, $value := $metadataValues.labels }}
    {{ $key }}: {{ $value | toString }}
    {{- end }}
  name: {{ required (printf "Unnamed apiObject Name in template: %s!" $metadataValues.templateName) $metadataValues.appName }}
  namespace: {{ $metadataValues.namespace | default $.Release.Namespace }}
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
{{- if $.Chart.Version }}
app.kubernetes.io/version: {{ $.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
app.kubernetes.io/instance: {{ $.Release.Name }}
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

  {{- if or ($svcValues.prometheus).path $.Values.elCicdDefaults.prometheusPath }}
    {{- $_ := set $svcValues.annotations "prometheus.io/path" ($svcValues.prometheus.path | default $.Values.elCicdDefaults.prometheusPath) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).port $.Values.elCicdDefaults.prometheusPort }}
    {{- $_ := set $svcValues.annotations "prometheus.io/port" ($svcValues.prometheus.port | default $svcValues.port) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).scheme $.Values.elCicdDefaults.prometheusScheme }}
    {{- $_ := set $svcValues.annotations "prometheus.io/scheme" ($svcValues.prometheus.scheme | default $.Values.elCicdDefaults.prometheusScheme) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).scrape $.Values.elCicdDefaults.prometheusScrape }}
    {{- $_ := set $svcValues.annotations "prometheus.io/scrape" ($svcValues.prometheus.scrape | default $.Values.elCicdDefaults.prometheusScrape) }}
  {{- end }}
{{- end }}

{{/*
Service Prometheus 3Scale definition
*/}}
{{- define "elCicdResources.3ScaleAnnotations" }}
  {{- $ := index . 0 }}
  {{- $svcValues := index . 1 }}
  {{- $_ := set $svcValues "annotations" ($svcValues.annotations | default dict) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/path" ($svcValues.threeScale.port | default $svcValues.port | default $.Values.elCicdDefaults.port) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/port" ($svcValues.threeScale.path | default $.Values.default3ScalePath) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/scheme" ($svcValues.threeScale.scheme | default (get $.Values.elCicdDefaults "3ScaleScheme")) }}
{{- end }}

{{- define "elCicdResources.outputToYaml" }}
  {{- $ := index . 0 }}
  {{- $templateVals := index . 1 }}
  {{- $whiteList := index . 2 }}
  
  {{- include "elCicdResources.setTemplateDefaultValue" . }}
  
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

{{- define "elCicdResources.setTemplateDefaultValue" }}
  {{- $ := index . 0 }}
  {{- $templateVals := index . 1 }}
  {{- $defaultKeysList := index . 2 }}
  
  {{- $elCicdDefaultMapNames := list "elCicdDefaults" }}
  {{- range $profile := $.Values.profiles }}
    {{- $elCicdDefaultMapNames = prepend $elCicdDefaultMapNames (printf "elCicdDefaults-%s" $profile) }}
  {{- end }}
  {{- $elCicdDefaultMapNames := prepend $elCicdDefaultMapNames (printf "elCicdDefaults-%s" $.Values.currentTemplateKind) }}
  {{- range $profile := $.Values.profiles }}
    {{- $elCicdDefaultMapNames = prepend $elCicdDefaultMapNames (printf "elCicdDefaults-%s-%s"  $.Values.currentTemplateKind $profile) }}
  {{- end }}
  
  {{- range $key := $defaultKeysList }}
    {{- if not (get $templateVals $key) }}
      {{- range $defaultMapName := $elCicdDefaultMapNames }}
        {{- $defaultMap := get $.Values $defaultMapName }}
        {{- if and $defaultMap (not (get $templateVals $key)) }}
          {{- $value := get $defaultMap $key }}
          {{- if $value }}
            {{- $_ := set $templateVals $key $value }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}