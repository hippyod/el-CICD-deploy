{{/*
General Metadata Template
*/}}
{{- define "elCicdChart.apiObjectHeader" }}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
apiVersion: {{ $template.apiVersion }}
kind: {{ $template.kind }}
{{- include "elCicdChart.apiMetadata" . }}
{{- end }}

{{- define "elCicdChart.apiMetadata" }}
{{- $ := index . 0 }}
{{- $metadataValues := index . 1 }}
metadata:
  {{- if or $metadataValues.annotations $.Values.defaultAnnotations }}
  annotations:
    {{- if $metadataValues.annotations }}
      {{- range $key, $value := $metadataValues.annotations }}
    {{ $key }}: "{{ $value }}"
      {{- end }}
    {{- end }}
    {{- if $.Values.defaultAnnotations}}
      {{- $.Values.defaultAnnotations | toYaml | nindent 4 }}
    {{- end }}
  {{- end }}
  labels:
    {{- include "elCicdChart.labels" $ | nindent 4 }}
    app: {{ $metadataValues.appName }}
    {{- if $metadataValues.labels}}{{- $metadataValues.labels | indent 4 }}{{- end }}
    {{- if $.Values.labels}}{{- $.Values.labels | indent 4 }}{{- end }}
    {{- if $.Values.defaultLabels}}{{- $.Values.defaultLabels | toYaml | indent 4 }}{{- end }}
  name: {{ required "Unnamed apiObject Name!" $metadataValues.appName }}
  namespace: {{ $.Values.namespace | default $.Release.Namespace}}
{{- end }}

{{/*
el-CICD Selector
*/}}
{{- define "elCicdChart.selector" }}
{{- $ := index . 0 }}
{{- $appName := index . 1 }}
matchExpressions:
- key: app
  operator: Exists
matchLabels:
  {{- include "elCicdChart.selectorLabels" $appName | nindent 2 }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "elCicdChart.name" -}}
{{- default $.Chart.Name $.Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "elCicdChart.chart" -}}
{{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "elCicdChart.labels" -}}
{{ include "elCicdChart.selectorLabels" $appName }}
helm.sh/chart: {{ include "elCicdChart.chart" $ }}
{{- if $.Chart.AppVersion }}
app.kubernetes.io/version: {{ $.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "elCicdChart.selectorLabels" -}}
app: {{ . }}
{{- end }}

{{/*
Scale3 Annotations
*/}}
{{- define "elCicdChart.scale3Annotations" -}}
discovery.3scale.net/path: {{ .threeScale.path }}
discovery.3scale.net/port: {{ .threeScale.port }}
discovery.3scale.net/scheme: {{ .threeScale.scheme }}
{{- end }}

{{/*
Scale3 Labels
*/}}
{{- define "elCicdChart.scale3Labels" -}}
discovery.3scale.net: {{ .threeScale.scheme }}
{{- end }}