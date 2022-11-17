{{- define "elCicdResources.copyResource" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  
  {{- if or $.Release.IsUpgrade $.Release.IsInstall }}  
    {{- $resource := (lookup ($template.apiVersion | default "v1") $template.kind $template.fromNamespace $template.appName) }}
    
    {{- if and (not $resource) (not $template.optional) }}
      {{- fail (printf "Cannot find %s %s in namespace %s" $template.kind $template.appName $template.fromNamespace) }}
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
    
    {{- if $resource.data }}
      {{- $_ := set $newResource "data" (deepCopy $resource.data) }}
    {{- else if $resource.spec }}
      {{- $_ := set $newResource "spec" (deepCopy $resource.spec) }}
    {{- end }}

    {{- $newResource | toYaml }}
  {{- end }}
  
{{- end }}