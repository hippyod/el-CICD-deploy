

{{/*
General Metadata Template
*/}}
{{- define "elCicdCommon.apiObjectHeader" }}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
apiVersion: {{ $template.apiVersion }}
kind: {{ $template.kind }}
{{- $_ := set $.Values "currentTemplateKind"  $template.kind }}
{{- include "elCicdK8s.apiMetadata" . }}
{{- end }}

{{- define "elCicdK8s.apiMetadata" }}
{{- $ := index . 0 }}
{{- $metadataValues := index . 1 }}
metadata:
  {{- $_ := set $metadataValues "annotations" (mergeOverwrite ($metadataValues.annotations | default dict) $.Values.elCicdDefaults.annotations) }}
  {{- if $metadataValues.annotations }}
  annotations:
    {{- range $key, $value := $metadataValues.annotations }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
  {{- end }}
  {{- $_ := set $metadataValues "labels" (mergeOverwrite ($metadataValues.labels | default dict) $.Values.elCicdDefaults.labels) }}
  labels:
    {{- include "elCicdCommon.labels" . | indent 4 }}
    {{- if $metadataValues.labels }}
      {{- range $key, $value := $metadataValues.labels }}
    {{ $key }}: {{ $value | quote }}
      {{- end }}
    {{- end }}
  name: {{ required (printf "Unnamed apiObject Name in template: %s!" $metadataValues.templateName) $metadataValues.appName }}
  {{- if $metadataValues.namespace }}
  namespace: {{ $metadataValues.namespace }}
  {{- end }}
{{- end }}

{{/*
el-CICD Selector
*/}}
{{- define "elCicdCommon.selector" }}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
matchExpressions:
- key: app
  operator: Exists
{{- if $template.matchExpressions }}
  {{- $template.matchExpressions | toYaml }}
{{- end }}
matchLabels:
  {{- include "elCicdCommon.selectorLabels" . | indent 2 }}
{{- if $template.matchLabels }}
  {{- $template.matchLabels | toYaml | indent 2 }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "elCicdCommon.chart" -}}
{{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "elCicdCommon.labels" -}}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
{{- include "elCicdCommon.selectorLabels" . }}
helm.sh/chart: {{ include "elCicdCommon.chart" $ }}
{{- if $.Chart.AppVersion }}
app.kubernetes.io/version: {{ $.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
app.kubernetes.io/instance: {{ $.Release.Name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "elCicdCommon.selectorLabels" -}}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
app: {{ $template.appName }}
{{- end }}

{{- define "elCicdCommon.outputValues" }}
  {{- $ := . }}
---
# __VALUES_START__
{{ $.Values | toYaml }}
# __VALUES_END__
{{- end }}

{{- define "elCicdCommon.outputToYaml" }}
  {{- $ := index . 0 }}
  {{- $templateVals := index . 1 }}
  {{- $whiteList := index . 2 }}
  
  {{- include "elCicdCommon.setTemplateDefaultValue" . }}
  
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

{{- define "elCicdCommon.setTemplateDefaultValue" }}
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