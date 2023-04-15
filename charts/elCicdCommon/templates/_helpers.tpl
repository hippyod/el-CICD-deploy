{{/*
  Initialize elCicdCommon
*/}}

{{/*
General Metadata Template
*/}}
{{- define "elCicdCommon.apiObjectHeader" }}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
apiVersion: {{ $template.apiVersion }}
kind: {{ $template.kind }}
{{- include "elCicdCommon.apiMetadata" . }}
{{- end }}

{{- define "elCicdCommon.apiMetadata" }}
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
  name: {{ required (printf "Unnamed apiObject Name in template: %s!" $metadataValues.templateName) $metadataValues.appName }}
  {{- if $metadataValues.namespace }}
  namespace: {{ $metadataValues.namespace }}
  {{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "elCicdCommon.labels" -}}
{{- $ := index . 0 }}
{{- $metadataValues := index . 1 }}
helm.sh/chart: {{ include "elCicdCommon.chart" $ }}
{{- if $.Chart.AppVersion }}
app.kubernetes.io/version: {{ $.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
app.kubernetes.io/instance: {{ $.Release.Name }}
{{- if ($.Values.elCidDefaults).commonLabels }}
  {{- if $metadataValues.labels }}
    {{ $_ := set $metadataValues "labels" (mergeOverwrite $metadataValues.labels $.Values.elCidDefaults.commonLabels) }}
  {{- else }}
    {{- $_ := set $metadataValues "labels" $.Values.elCidDefaults.commonLabels }}
  {{- end }}
{{- end }}
{{- if $metadataValues.labels }}
  {{- $metadataValues.labels | toYaml }}
{{- end }}
{{- end }}

{{/*
el-CICD Selector
*/}}
{{- define "elCicdCommon.selector" }}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
matchExpressions:
{{- if $template.matchExpressions }}
  {{- $template.matchExpressions | toYaml }}
{{- end }}
matchLabels:
{{- if ($.Values.elCidDefaults).commonLabels }}
  {{- $.Values.elCidDefaults.commonLabels | toYaml }}
{{- end }}
{{- if $template.matchlabels }}
  {{- $template.matchlabels | toYaml | indent 2 }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "elCicdCommon.chart" -}}
{{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
This is a catch-all that renders all extraneous resource values that don't have helper structures.
Checks the template values for each resource's whitelist, and if it exists renders it properly.
*/}}
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

{{/*
Support function for the outputToYaml function.  Assigns a value for anything in the whitelist 
that is empty and a default value has been defined.
*/}}
{{- define "elCicdCommon.setTemplateDefaultValue" }}
  {{- $ := index . 0 }}
  {{- $templateVals := index . 1 }}
  {{- $whiteList := index . 2 }}
  
  {{- range $key := $whiteList }}
    {{- if not (get $templateVals $key) }}
      {{- $defaultValue := get $.Values.elCicdDefaults $key }}
      {{- if $defaultValue }}
        {{- $_ := set $templateVals $key $defaultValue }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}