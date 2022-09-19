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
  {{- if or $metadataValues.annotations $.Values.global.defaultAnnotations }}
  annotations:
    {{- if $metadataValues.annotations }}
      {{- range $key, $value := $metadataValues.annotations }}
    {{ $key }}: {{ $value | quote }}
      {{- end }}
    {{- end }}
    {{- if $.Values.global.defaultAnnotations}}
      {{- $.Values.global.defaultAnnotations | toYaml | nindent 4 }}
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
    {{- range $key, $value := $.Values.global.defaultLabels }}
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
Scale3 Annotations
*/}}
{{- define "elCicdResources.scale3Annotations" -}}
discovery.3scale.net/path: {{ .threeScale.path }}
discovery.3scale.net/port: {{ .threeScale.port }}
discovery.3scale.net/scheme: {{ .threeScale.scheme }}
{{- end }}

{{/*
Scale3 Labels
*/}}
{{- define "elCicdResources.scale3Labels" -}}
discovery.3scale.net: {{ .threeScale.scheme }}
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