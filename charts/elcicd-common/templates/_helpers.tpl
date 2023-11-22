{{/*
  Initialize elcicd-common
*/}}

{{/*
General Metadata Template
*/}}
{{- define "elcicd-common.apiObjectHeader" }}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
apiVersion: {{ $template.apiVersion }}
kind: {{ $template.kind }}
{{- include "elcicd-common.apiMetadata" . }}
{{- end }}

{{- define "elcicd-common.apiMetadata" }}
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
    {{- include "elcicd-common.labels" . | indent 4 }}
  name: {{ required (printf "Unnamed apiObject Name in template: %s!" $metadataValues.templateName) $metadataValues.objName }}
  {{- if $metadataValues.namespace }}
  namespace: {{ $metadataValues.namespace }}
  {{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "elcicd-common.labels" -}}
{{- $ := index . 0 }}
{{- $metadataValues := index . 1 }}
helm.sh/chart: {{ include "elcicd-common.chart" $ }}
{{- if $.Chart.AppVersion }}
app.kubernetes.io/version: {{ $.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
app.kubernetes.io/instance: {{ $.Release.Name }}
{{- include "elcicd-common.elcicdLabels" . -}}
{{- if $metadataValues.labels }}
{{ $metadataValues.labels | toYaml }}
{{- end }}
{{- end }}

{{/*
el-CICD label
*/}}
{{- define "elcicd-common.elcicdLabels" -}}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
{{- $selector := $template.elcicdSelector | default (regexReplaceAll "[^\\w-.]" $template.objName "-") }}
{{- if (gt (len $selector) 63 ) }}
  {{- $selector = $selector | trunc 48 | trimSuffix "-"}}
  {{- $selectorSuffix := derivePassword 1 "long" $selector $selector "elcicd.org"  }}
  {{- $selectorSuffix = (regexReplaceAll "[^\\w-.]"  $selectorSuffix  "_" )}}
  {{- $selectorSuffix = (regexReplaceAll "[-_.]$"  $selectorSuffix  "Z" )}}
  {{- $selector = printf "%s-%s" $selector $selectorSuffix }}
{{- end }}
el-cicd.io/selector: {{ $selector }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "elcicd-common.chart" -}}
{{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
This is a catch-all that renders all extraneous resource values that don't have helper structures.
Checks the template values for each resource's whitelist, and if it exists renders it properly.
*/}}
{{- define "elcicd-common.outputToYaml" }}
  {{- $ := index . 0 }}
  {{- $templateVals := index . 1 }}
  {{- $whiteList := index . 2 }}
  {{- $checkIndent := append . 2 }}
  {{- $indent := index $checkIndent 3 | int }} 
  
  {{- include "elcicd-common.setTemplateDefaultValue" . }}
  
  {{- range $key, $value := $templateVals }}
    {{- if or (has $key $whiteList) (empty $whiteList)}}
      {{- if or (kindIs "slice" $value) (kindIs "map" $value) }}
  {{- $key | nindent $indent}}:
    {{- $value | toYaml | nindent 4 }}
      {{- else }}
  {{- $key | nindent $indent }}: {{ $value }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Support function for the outputToYaml function.  Assigns a value for anything in the whitelist 
that is empty and a default value has been defined.
*/}}
{{- define "elcicd-common.setTemplateDefaultValue" }}
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