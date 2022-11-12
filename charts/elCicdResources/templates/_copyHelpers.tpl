
{{- define "elCicdResources.copySecret" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  
  {{ $_ := set $template "kind" "Secret" }}
  
  {{- include "elCicdResources.copyResource" . }}
{{- end }}

{{- define "elCicdResources.copyConfigMap" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  
  {{ $_ := set $template "kind" "ConfigMap" }}
  
  {{- include "elCicdResources.copyResource" . }}
{{- end }}

{{- define "elCicdResources.copyResource" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  {{- $kind := index . 1 }}
  
  {{- $resource := (lookup ($template.apiVersion | default "v1") $template.kind $template.fromNamespace $template.appName) }}
  
  {{- if and (not $resource) (not $template.optional) }}
    {{- fail "Cannot find % %s in namespace %s" $template.kind $template.appName $template.fromNamespace }}
  {{- end }}
  
  {{- $newResource := dict }}
  {{- $_ := set $newResource  "apiVersion" $resource.apiVersion }}
  {{- $_ := set $newResource  "kind" $resource.kind }}
  {{- $_ := set $newResource  "metadata" dict }}
  {{- $_ := set $newResource.metadata  "name" $resource.metadata.name }}
  {{- $_ := set $newResource.metadata  "namespace" $template.toNamespace }}
  
  {{- if $template.copyLabels }}
    {{ $_ := set $newResource.metadata  "labels" (deepCopy $resource.metadata.labels) }}
  {{- else }}
    {{ $_ := set $newResource.metadata  "labels" dict }}
  {{- end }}
  
  {{- if $template.labels }}
    {{ $_ := mergeOverwrite $newResource.metadata.labels  $template.labels }}
  {{- end }}
  
  {{- if $template.copyAnnotations }}
    {{ $_ := set $newResource.metadata  "annotations" (deepCopy $resource.metadata.annotations) }}
  {{- else }}
    {{ $_ := set $newResource.metadata  "annotations" dict }}
  {{- end }}
  
  {{- if $template.annotations }}
    {{ $_ := mergeOverwrite $newResource.metadata.annotations  $template.annotations }}
  {{- end }}
  
  {{- $_ := set $newResource "data" (deepCopy $resource.data) }}

  {{- $newResource | toYaml }}
  
{{- end }}