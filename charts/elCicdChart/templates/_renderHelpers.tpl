{{- $_ := set $.Values "PARAM_REGEX" "[\\$][\\{]([\\w]+?)[\\}]" }}

{{- define "elCicdChart.mergeProfileParameters" }}
  {{- $ := index . 0 }}
  {{- $profileParamMaps := index . 1 }}
  {{- $parameters := index . 2 }}
  
  {{- $appName := $profileParamMaps.appName }}
  
  {{- if $appName }}
    {{- include "elCicdChart.mergeMapInto" (list $ $profileParamMaps.parameters $parameters) }}
  {{- end }}
  
  {{- range $profile := $.Values.profiles }}    
    {{- $profileParameters := get $profileParamMaps (printf "parameters-%s" $profile) }}
    {{- include "elCicdChart.mergeMapInto" (list $ $profileParameters $parameters) }}
  {{- end }}
    
  {{- if $appName }}
    {{- $appNameParamMapName := printf "parameters-%s" $appName }}
    {{- $appNameParamMaps := tuple (deepCopy (get $.Values $appNameParamMapName)) (get $profileParamMaps $appNameParamMapName ) }}
    {{- range $appNameParameters := $appNameParamMaps }}
      {{- include "elCicdChart.mergeMapInto" (list $ $appNameParameters $parameters) }}
    {{- end }}
    
    {{- range $profile := $.Values.profiles }}    
      {{- $profileParameters := get $profileParamMaps (printf "parameters-%s-%s" $appName $profile) }}
      {{- include "elCicdChart.mergeMapInto" (list $ $profileParameters $parameters) }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.hydrateTemplates" }}
  {{- $ := index . 0 }}
  {{- $templates := index . 1 }}
  {{- $parameters := index . 2 }}
  
  {{- range $template := $templates }}
    {{- $_ := required "elCicdChart must define template.appName or $.Values.appName!" ($template.appName | default $.Values.appName) }}
    {{- $_ := set $template "appName" ($template.appName | default $.Values.appName) }}
    {{- $templateParams := deepCopy $parameters }}
    {{- $_ := set $templateParams "APP_NAME" ($templateParams.APP_NAME | default $template.appName) }}
    
    {{- include "elCicdChart.mergeMapInto" (list $ $template.parameters $templateParams) }}
    {{- include "elCicdChart.mergeProfileParameters" (list $ $template $templateParams) }}
    
    {{- include "elCicdChart.hydrateMap" (list $ $template $templateParams) }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.hydrateMap" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $parameters := index . 2 }}
  
  {{- range $key, $value := $map }}
    {{- if not $value }}
      {{- $_ := set $map $key dict }}
    {{- else }}
      {{- $args := (list $ $map $key $parameters) }}
      {{- if (kindIs "map" $value) }}
        {{- include "elCicdChart.hydrateMap" (list $ $value $parameters) }}
      {{- else if (kindIs "slice" $value) }}
        {{- include "elCicdChart.hydrateSlice" (list $ $map $key $parameters) }}
      {{- else if (kindIs "string" $value) }}
          {{- include "elCicdChart.hydrateValue" (list $ $map $key $parameters) }}
      {{- end  }}
      
      {{- if (get $map $key) }}
        {{- include "elCicdChart.hydrateKey" (list $ $map $key $parameters) }}
      {{- else }}
        {{- $_ := unset $map $key }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.hydrateValue" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $parameters := index . 3 }}
  
  {{- $value := get $map $key }}
  {{- $matches := regexFindAll $.Values.PARAM_REGEX $value -1 }}
  {{- range $paramRef := $matches }}
    {{- $param := regexReplaceAll $.Values.PARAM_REGEX $paramRef "${1}" }}
    
    {{- $paramVal := get $parameters $param }}
    {{ if or (kindIs "string" $paramVal) }}
      {{- $value = replace $paramRef (toString $paramVal) $value }}
    {{- else }}
      {{- if (kindIs "map" $paramVal) }}
        {{- $paramVal = deepCopy $paramVal }}
      {{- else if (kindIs "slice" $paramVal) }}
        {{- if (kindIs "map" (first $paramVal)) }}
          {{- $newList := list }}
          {{- range $el := $paramVal }}
            {{- $newList = append $newList (deepCopy $el) }}
          {{- end }}
          {{- $paramVal = $newList }}
        {{- end }}
      {{- end }}
      
      {{- $value = $paramVal }}
    {{- end }}
  {{- end }}
  
  {{- if $matches }}
    {{- $_ := set $map $key $value }}
    {{- if $value }}
      {{- if or (kindIs "map" $value) }}
        {{- include "elCicdChart.hydrateMap" (list $ $value $parameters) }}
      {{- else if (kindIs "slice" $value) }}
        {{- include "elCicdChart.hydrateSlice" (list $ $map $key $parameters) }}
      {{- else if (kindIs "string" $value) }}
        {{- include "elCicdChart.hydrateValue" (list $ $map $key $parameters) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.hydrateKey" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $parameters := index . 3 }}
  
  {{- $value := get $map $key }}
  {{- $oldKey := $key }}
  {{- $matches := regexFindAll $.Values.PARAM_REGEX $key -1 }}
  {{- range $paramRef := $matches }}
    {{- $param := regexReplaceAll $.Values.PARAM_REGEX $paramRef "${1}" }}
    {{- $paramVal := get $parameters $param }}
    {{ $_ := unset $map $key }}
    {{- $key = replace $paramRef (toString $paramVal) $key }}
  {{- end }}
  {{- if ne $oldKey $key }}
    {{- $_ := unset $map $oldKey }}
  {{- end }}
  {{- if and $matches (ne $oldKey $key) $key }}
    {{- $_ := set $map $key $value }}
    {{- include "elCicdChart.hydrateKey" (list $ $map $key $parameters) }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.hydrateSlice" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $parameters := index . 3 }}
  
  {{- $list := get $map $key }}
  {{- $newList := list }}
  {{- range $element := $list }}
    {{- if and (kindIs "map" $element) }}
      {{- include "elCicdChart.hydrateMap" (list $ $element $parameters) }}
    {{- else if (kindIs "string" $element) }}
      {{- $matches := regexFindAll $.Values.PARAM_REGEX $element -1 }}
      {{- range $paramRef := $matches }}
        {{- $param := regexReplaceAll $.Values.PARAM_REGEX $paramRef "${1}" }}
        {{- $paramVal := get $parameters $param }}
        {{- if (kindIs "string" $paramVal) }}
          {{- $element = replace $paramRef (toString $paramVal) $element }}
        {{- else if and (kindIs "map" $paramVal) }}
          {{- include "elCicdChart.hydrateMap" (list $ $paramVal $parameters) }}
          {{- $element = $paramVal }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- if $element }}
      {{- $newList = append $newList $element }}
    {{- end }}
  {{- end }}
  
  {{- if eq $key "anyProfiles" }}
# Rendered -> list {{ $list }}
# Rendered -> newList {{ $newList }}
  {{- end }}
  {{- $_ := set $map $key $newList }}
{{- end }}

{{- define "elCicdChart.mergeMapInto" }}
  {{- $ := index . 0 }}
  {{- $srcMap := index . 1 }}
  {{- $destMap := index . 2 }}
  
  {{- if $srcMap }}
    {{- range $key, $value := $srcMap }}
      {{- $_ := set $destMap $key $value }}
    {{- end }}
  {{- end }}
{{- end }}

{{ define "elCicdChart.skippedTemplate" }}
# EXCLUDED BY PROFILES: {{ index . 1 }} -> {{ index . 2 }}
{{- end }}
