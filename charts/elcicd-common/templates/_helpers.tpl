{{/*
  ======================================
  elcicd-kubernetes.apiObjectHeader
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $template -> elCicd template

  ======================================

  DEFAULT KEYS
    apiVersion
    kind
  
  ======================================

  el-CICD SUPPORTING TEMPLATES:
  "elcicd-common.metadata"
  
  ======================================
  
  General header for a Kubernetes compliant resource.
*/}}
{{- define "elcicd-common.apiObjectHeader" }}
{{- $ := index . 0 }}
{{- $template := index . 1 }}
apiVersion: {{ $template.apiVersion }}
kind: {{ $template.kind }}
{{- include "elcicd-common.metadata" . }}
{{- end }}

{{/*
  ======================================
  elcicd-kubernetes.apiMetadata
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $template -> elCicd template

  ======================================

  DEFAULT KEYS
    [metadata]:
      annotations
      labels
      name
      namespace
  
  ======================================

  el-CICD SUPPORTING TEMPLATES:
    "elcicd-common.labels"
  
  ======================================
  
  General header for a Kubernetes compliant resource metadata.
*/}}
{{- define "elcicd-common.metadata" }}
{{- $ := index . 0 }}
{{- $metadataValues := index . 1 }}
metadata:
  {{- $_ := set $metadataValues "annotations" (mergeOverwrite ($metadataValues.annotations | default dict) ($.Values.elCicdDefaults.annotations | default dict)) }}
  {{- if $metadataValues.annotations }}
  annotations:
    {{- range $key, $value := $metadataValues.annotations }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
  {{- end }}
  {{- $_ := set $metadataValues "labels" (mergeOverwrite ($metadataValues.labels | default dict) ($.Values.elCicdDefaults.labels | default dict)) }}
  labels:
    {{- include "elcicd-common.labels" . | indent 4 }}
  name: {{ required (printf "Unnamed apiObject Name in template: %s!" $metadataValues.templateName) $metadataValues.objName }}
  {{- if $metadataValues.namespace }}
  namespace: {{ $metadataValues.namespace }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  elcicd-kubernetes.labels
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $template -> elCicd template

  ======================================

  HELPER KEYS
  ---
    helm.sh/chart -> .Chart.Name-.Chart.Version
    app.kubernetes.io/instance -> .Release.Name
    app.kubernetes.io/managed-by -> .Release.Service
    app.kubernetes.io/version -> .Chart.AppVersion
    elcicdSelector -> $template.objName
  
  ======================================

  el-CICD SUPPORTING TEMPLATES:
    "elcicd-common.elcicdLabels"
  
  ======================================
  
  Generates some default labels for a Kubernetes compliant resource based on the values in Chart.yaml.
*/}}
{{- define "elcicd-common.labels" }}
{{- $ := index . 0 }}
{{- $metadataValues := index . 1 }}
app.kubernetes.io/instance: {{ $.Release.Name }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
{{- if $.Chart.AppVersion }}
app.kubernetes.io/version: {{ $.Chart.AppVersion | quote }}
{{- end }}
helm.sh/chart: {{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- include "elcicd-common.elcicdLabels" . }}
{{- if $metadataValues.labels }}
{{ $metadataValues.labels | toYaml }}
{{- end }}
{{- end }}

{{/*
  ======================================
  elcicd-kubernetes.elcicdLabels
  ======================================

  PARAMETERS LIST:
    . -> should always be root of chart
    $template -> elCicd template

  ======================================

  HELPER KEYS
  ---
    elcicdSelector -> $template.objName
  
  ======================================
  
  Generates a selector label, elcicd.io/selector.
*/}}
{{- define "elcicd-common.elcicdLabels" }}
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
elcicd.io/selector: {{ $selector }}
{{- end }}

{{/*
This is a catch-all that renders all extraneous key/values pairs that don't have helper keys or structures.
Checks the template values for each resource's whitelist, and if it exists renders it properly.
*/}}
{{- define "elcicd-common.outputToYaml" }}
  {{- $ := index . 0 }}
  {{- $templateVals := index . 1 }}
  {{- $whiteList := index . 2 }}

  {{- $defaultIndent := append . 2 }}
  {{- $indent := index $defaultIndent 3 | int }}
  
  {{- include "elcicd-common.setTemplateDefaultValue" . }}
  
  {{- range $key, $value := $templateVals }}
    {{- if or (has $key $whiteList) (empty $whiteList) }}
      {{- if (kindIs "map" $value) }}
        {{- $key | nindent $indent }}:
        {{- $value | toYaml | nindent (int (add $indent 2)) }}
      {{- else if (kindIs "slice" $value) }}
        {{- $key | nindent $indent }}:
        {{- $value | toYaml | nindent $indent }}
      {{- else if kindIs "string" $value }}
        {{- $key | nindent $indent }}: {{ $value | quote }}
      {{- else }}
        {{- $key | nindent $indent }}: {{ $value }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Support function for the outputToYaml function.  Assigns a value for anything in the whitelist 
that is empty and has n elCicdDefault value defined.
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