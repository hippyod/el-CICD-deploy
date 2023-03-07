{{- define "elCicdK8s.copyResource" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  
  {{- if or $.Release.IsUpgrade $.Release.IsInstall }}  
    {{- $resource := (lookup ($template.apiVersion | default "v1") 
                              $template.kind 
                              $template.fromNamespace
                              ($template.srcMetadataName | default $template.appName)) }}
    
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
      {{- $_ := set $newResource.metadata  "labels" (deepCopy $resource.metadata.labels) }}
    {{- else }}
      {{- $_ := set $newResource.metadata  "labels" dict }}
    {{- end }}
    
    {{- if $template.copyAnnotations }}
      {{- $_ := set $newResource.metadata "annotations" dict }}
      {{- range $annKey, $annValue := $resource.metadata.annotations }}
        {{- if not (contains "meta.helm.sh" $annKey) }}
          {{- $_ := set $newResource.metadata.annotations $annKey $annValue }}
        {{- end }}
      {{- end }}
    {{- end }}
    
    {{- if $template.labels }}
      {{- $_ := mergeOverwrite $newResource.metadata.labels  $template.labels }}
    {{- end }}
    
    {{- if $template.annotations }}
      {{- $_ := mergeOverwrite $newResource.metadata.annotations  $template.annotations }}
    {{- end }}
    
    {{- if $resource.spec }}
      {{- $_ := set $newResource "spec" (deepCopy $resource.spec) }}
    {{- end }}
    
    {{- if $resource.data }}
      {{- $_ := set $newResource "data" (deepCopy $resource.data) }}
    {{- end }}
    
    {{- if $resource.dataBinary }}
      {{- $_ := set $newResource "dataBinary" (deepCopy $resource.dataBinary) }}
    {{- end }}
    
    {{- if $resource.type }}
      {{- $_ := set $newResource "type" $resource.type }}
    {{- end }}

    {{- $newResource | toYaml }}
  {{- end }}
{{- end }}