{{- define "elCicdChart.mergeProfileDefs" }}
  {{- $ := index . 0 }}
  {{- $profileDefs := index . 1 }}
  {{- $elcicdDefs := index . 2 }}

  {{- $appName := $profileDefs.appName }}

  {{- if $appName }}
    {{- include "elCicdChart.mergeMapInto" (list $ $profileDefs.elcicdDefs $elcicdDefs) }}
  {{- end }}

  {{- range $profile := $.Values.profiles }}
    {{- $profileDefs := get $profileDefs (printf "elcicdDefs-%s" $profile) }}
    {{- include "elCicdChart.mergeMapInto" (list $ $profileDefs $elcicdDefs) }}
  {{- end }}

  {{- if $appName }}
    {{- $appNameDefsKey := printf "elcicdDefs-%s" $appName }}
    {{- $appNameDefs := tuple (deepCopy (get $.Values $appNameDefsKey)) (get $profileDefs $appNameDefsKey ) }}
    {{- range $appNameDefs := $appNameDefs }}
      {{- include "elCicdChart.mergeMapInto" (list $ $appNameDefs $elcicdDefs) }}
    {{- end }}

    {{- range $profile := $.Values.profiles }}
      {{- $profileDefs := get $profileDefs (printf "elcicdDefs-%s-%s" $appName $profile) }}
      {{- include "elCicdChart.mergeMapInto" (list $ $profileDefs $elcicdDefs) }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.processAppnames" }}
  {{- $allTemplates := list }}
  {{- range $template := $.Values.templates  }}
    {{- if $template.appNames }}
      {{- include "elCicdChart.processTemplateAppnames" (list $ $template) }}
      {{- range $appName := $template.appNames }}
        {{- $newTemplate := deepCopy $template }}
        {{- $_ := set $newTemplate "appName" $appName }}
        {{- $allTemplates = append $allTemplates $newTemplate }}
      {{- end }}
    {{- else }}
      {{- $allTemplates = append $allTemplates $template }}
    {{- end }}
  {{- end }}
  {{ $_ := set $.Values "allTemplates" $allTemplates }}
{{- end }}

{{- define "elCicdChart.processTemplateAppnames" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  {{- if kindIs "string" $template.appNames }}
    {{- $appNames := $template.appNames }}
    {{- $matches := regexFindAll $.Values.PARAM_REGEX $appNames -1 }}
    {{- range $paramRef := $matches }}
      {{- $param := regexReplaceAll $.Values.PARAM_REGEX $paramRef "${1}" }}

      {{- $paramVal := get $.Values.elcicdDefs $param }}
      {{ if or (kindIs "string" $paramVal) }}
        {{- $appNames = replace $paramRef (toString $paramVal) $appNames }}
      {{- end }}
      {{- $appNames = $paramVal }}
    {{- end }}

    {{- $_ := set $template "appNames" $appNames }}
    {{- include "elCicdChart.processTemplateAppnames" . }}
  {{- else if not (kindIs "slice" $template.appNames) }}
    {{- fail (printf "appNames must be either a variable or a list: %s" $template.appNames )}}
  {{- end }}
{{- end }}

{{- define "elCicdChart.processTemplates" }}
  {{- $ := index . 0 }}
  {{- $templates := index . 1 }}
  {{- $elcicdDefs := index . 2 }}
  
  {{- $_ := set $elcicdDefs "RELEASE_NAMESPACE" $.Release.Namespace }}

  {{- range $template := $templates }}
    {{- $_ := required "elCicdChart must define template.appName or $.Values.appName!" ($template.appName | default $.Values.appName) }}
    {{- $_ := set $template "appName" ($template.appName | default $.Values.appName) }}
    {{- $templateDefs := deepCopy $elcicdDefs }}
    {{- $_ := set $templateDefs "APP_NAME" ($templateDefs.APP_NAME | default $template.appName) }}

    {{- include "elCicdChart.mergeMapInto" (list $ $template.elcicdDefs $templateDefs) }}
    {{- include "elCicdChart.mergeProfileDefs" (list $ $template $templateDefs) }}

    {{- include "elCicdChart.processMap" (list $ $template $templateDefs) }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.processMap" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $elcicdDefs := index . 2 }}

  {{- range $key, $value := $map }}
    {{- if not $value }}
      {{- $_ := set $map $key dict }}
    {{- else }}
      {{- $args := (list $ $map $key $elcicdDefs) }}
      {{- if (kindIs "map" $value) }}
        {{- include "elCicdChart.processMap" (list $ $value $elcicdDefs) }}
      {{- else if (kindIs "slice" $value) }}
        {{- include "elCicdChart.processSlice" (list $ $map $key $elcicdDefs) }}
      {{- else if (kindIs "string" $value) }}
          {{- include "elCicdChart.processMapValue" (list $ $map $key $elcicdDefs) }}
      {{- end  }}

      {{- if (get $map $key) }}
        {{- include "elCicdChart.processMapKey" (list $ $map $key $elcicdDefs) }}
      {{- else }}
        {{- $_ := unset $map $key }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.processMapValue" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $elcicdDefs := index . 3 }}

  {{- $value := get $map $key }}
  {{- $matches := regexFindAll $.Values.PARAM_REGEX $value -1 }}
  {{- range $paramRef := $matches }}
    {{- $param := regexReplaceAll $.Values.PARAM_REGEX $paramRef "${1}" }}

    {{- $paramVal := get $elcicdDefs $param }}
    {{ if (kindIs "string" $paramVal) }}
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
        {{- include "elCicdChart.processMap" (list $ $value $elcicdDefs) }}
      {{- else if (kindIs "slice" $value) }}
        {{- include "elCicdChart.processSlice" (list $ $map $key $elcicdDefs) }}
      {{- else if (kindIs "string" $value) }}
        {{- include "elCicdChart.processMapValue" (list $ $map $key $elcicdDefs) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.processMapKey" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $elcicdDefs := index . 3 }}

  {{- $value := get $map $key }}
  {{- $oldKey := $key }}
  {{- $matches := regexFindAll $.Values.PARAM_REGEX $key -1 }}
  {{- range $paramRef := $matches }}
    {{- $param := regexReplaceAll $.Values.PARAM_REGEX $paramRef "${1}" }}
    {{- $paramVal := get $elcicdDefs $param }}
    {{ $_ := unset $map $key }}
    {{- $key = replace $paramRef (toString $paramVal) $key }}
  {{- end }}
  {{- if ne $oldKey $key }}
    {{- $_ := unset $map $oldKey }}
  {{- end }}
  {{- if and $matches (ne $oldKey $key) $key }}
    {{- $_ := set $map $key $value }}
    {{- include "elCicdChart.processMapKey" (list $ $map $key $elcicdDefs) }}
  {{- end }}
{{- end }}

{{- define "elCicdChart.processSlice" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $elcicdDefs := index . 3 }}

  {{- $list := get $map $key }}
  {{- $newList := list }}
  {{- range $element := $list }}
    {{- if and (kindIs "map" $element) }}
      {{- include "elCicdChart.processMap" (list $ $element $elcicdDefs) }}
    {{- else if (kindIs "string" $element) }}
      {{- $matches := regexFindAll $.Values.PARAM_REGEX $element -1 }}
      {{- range $paramRef := $matches }}
        {{- $param := regexReplaceAll $.Values.PARAM_REGEX $paramRef "${1}" }}
        {{- $paramVal := get $elcicdDefs $param }}
        {{- if (kindIs "string" $paramVal) }}
          {{- $element = replace $paramRef (toString $paramVal) $element }}
        {{- else if and (kindIs "map" $paramVal) }}
          {{- include "elCicdChart.processMap" (list $ $paramVal $elcicdDefs) }}
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
