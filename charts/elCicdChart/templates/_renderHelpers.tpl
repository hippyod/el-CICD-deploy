{{- define "elCicdChart.initParameters" }}
  {{- $ := . }}
  
  {{- if kindIs "slice" $.Values.profiles }}
    {{- $sdlcEnv := first $.Values.profiles }}
    {{- $_ := set $.Values.parameters "SDLC_ENV" $sdlcEnv }}
    {{- include "elCicdChart.mergeProfileParameters" (list $ $.Values $.Values.parameters) }}
  {{- end }}
  
  {{- if $.Values.projectId }}
    {{- $_ := set $.Values.parameters "PROJECT_ID" $.Values.projectId }}
  {{- end }}
  {{- if $.Values.microService }}
    {{- $_ := set $.Values.parameters "MICROSERVICE_NAME" $.Values.microService }}
  {{- end }}
  {{- if $.Values.imageRepository }}
    {{- $_ := set $.Values.parameters "IMAGE_REPOSITORY" $.Values.imageRepository }}
  {{- end }}
  {{- if $.Values.imageTag }}
    {{- $_ := set $.Values.parameters "IMAGE_TAG" $.Values.imageRepository }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.mergeProfileParameters" }}
  {{- $ := index . 0 }}
  {{- $profileParamMaps := index . 1 }}
  {{- $parameters := index . 2 }}
  
  {{- range $profile := $.Values.profiles }}
    {{- $profileParameters := get $profileParamMaps (printf "parameters-%s" $profile) }}
    {{- include "elCicdChart.mergeMapInto" (list $ $profileParameters $parameters) }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.interpolateTemplates" }}
  {{- $ := index . 0 }}
  {{- $templates := index . 1 }}
  {{- $parameters := index . 2 }}
  
  {{- range $template := $templates }}
    {{- $_ := set $template "appName" ($template.appName | default $.Values.microService) }}
    {{- $_ := set $parameters "APP_NAME" ($parameters.APP_NAME | default $template.appName) }}
    {{- $templateParams := deepCopy $parameters }}
    
    {{- include "elCicdChart.mergeMapInto" (list $ $template.parameters $templateParams) }}
    {{- include "elCicdChart.mergeProfileParameters" (list $ $template $templateParams) }}
    {{- include "elCicdChart.interpolateMap" (list $ $template $templateParams) }}
    {{- $_ := unset $parameters "APP_NAME" }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.interpolateMap" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $parameters := index . 2 }}
  
  {{- range $key, $value := $map }}
    {{- if not $value }}
      {{- $_ := set $map $key dict }}
    {{- else }}
      {{- $args := (list $ $map $key $parameters) }}
      {{- if (kindIs "map" $value) }}
        {{- include "elCicdChart.interpolateMap" (list $ $value $parameters) }}
      {{- else if (kindIs "slice" $value) }}
        {{- include "elCicdChart.interpolateSlice" (list $ $map $key $parameters) }}
      {{- else if (kindIs "string" $value) }}
          {{- include "elCicdChart.interpolateValue" (list $ $map $key $parameters) }}
      {{- end  }}
      
      {{- if (get $map $key) }}
        {{- include "elCicdChart.interpolateKey" (list $ $map $key $parameters) }}
      {{- else }}
        {{- $_ := unset $map $key }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.interpolateValue" }}
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
        {{- include "elCicdChart.interpolateMap" (list $ $value $parameters) }}
      {{- else if (kindIs "slice" $value) }}
        {{- include "elCicdChart.interpolateSlice" (list $ $map $key $parameters) }}
      {{- else if (kindIs "string" $value) }}
        {{- include "elCicdChart.interpolateValue" (list $ $map $key $parameters) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.interpolateKey" }}
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
    {{- include "elCicdChart.interpolateKey" (list $ $map $key $parameters) }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.interpolateSlice" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $parameters := index . 3 }}
  
  {{- $list := get $map $key }}
  {{- $newList := list }}
  {{- range $element := $list }}
    {{- if and (kindIs "map" $element) }}
      {{- include "elCicdChart.interpolateMap" (list $ $element $parameters) }}
    {{- else if (kindIs "string" $element) }}
      {{- $matches := regexFindAll $.Values.PARAM_REGEX $element -1 }}
      {{- range $paramRef := $matches }}
        {{- $param := regexReplaceAll $.Values.PARAM_REGEX $paramRef "${1}" }}
        {{- $paramVal := get $parameters $param }}
        {{- if (kindIs "string" $paramVal) }}
          {{- $element = replace $paramRef (toString $paramVal) $element }}
        {{- else if and (kindIs "map" $paramVal) }}
          {{- include "elCicdChart.interpolateMap" (list $ $paramVal $parameters) }}
          {{- $element = $paramVal }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- if $element }}
      {{- $newList = append $newList $element }}
    {{- end }}
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
