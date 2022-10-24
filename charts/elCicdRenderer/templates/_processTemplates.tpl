# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elCicdRenderer.processAppNames" }}
  {{- $ := . }}

  {{- $allTemplates := list }}
  {{- range $template := $.Values.elCicdTemplates  }}
    {{- include "elCicdRenderer.profileRenderingCheck" (list $ $template) }}
    
    {{- if $template.shouldRender }}
      {{- if $template.appNames }}
        {{- include "elCicdRenderer.processTemplateAppnames" (list $ $template) }}
        {{- range $index, $appName := $template.appNames }}
          {{- $newTemplate := deepCopy $template }}
          {{- $_ := set $newTemplate "appName" ($newTemplate.appName | default "") }}
          {{- if or (contains "${}" $newTemplate.appName) (contains "${INDEX}" $newTemplate.appName) }}
            {{- $_ := set $newTemplate "elCicdDefs" ($newTemplate.elCicdDefs | default dict) }}
            {{- $_ := set $newTemplate.elCicdDefs "BASE_APP_NAME" $appName }}
            {{- $appName = replace "${}" $appName $newTemplate.appName }}
            {{- $appName = replace "${INDEX}" (add $index 1 | toString) $appName }}
          {{- end }}
          {{- $_ := set $newTemplate "appName" $appName }}
          {{- $allTemplates = append $allTemplates $newTemplate }}
        {{- end }}
      {{- else }}
        {{- $allTemplates = append $allTemplates $template }}
      {{- end }}
    {{- end }}
    {{ $_ := set $.Values "allTemplates" $allTemplates }}
  {{- end }}
{{- end }}

{{- define "elCicdRenderer.processTemplateAppnames" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  {{- if kindIs "string" $template.appNames }}
    {{- $appNames := $template.appNames }}
    {{- $matches := regexFindAll $.Values.ELCICD_PARAM_REGEX $appNames -1 }}
    {{- range $elCicdRef := $matches }}
      {{- $elCicdDef := regexReplaceAll $.Values.ELCICD_PARAM_REGEX $elCicdRef "${1}" }}

      {{- $paramVal := get $.Values.elCicdDefs $elCicdDef }}
      {{- if not $paramVal }}
        {{- fail (printf "appNames cannot be empty [undefined variable reference]: %s" $elCicdDef) }}
      {{- else if or (kindIs "string" $paramVal) }}
        {{- $appNames = replace $elCicdRef (toString $paramVal) $appNames }}
      {{- end }}
      {{- $appNames = $paramVal }}
    {{- end }}

    {{- $_ := set $template "appNames" $appNames }}
    {{- include "elCicdRenderer.processTemplateAppnames" . }}
  {{- else if not (kindIs "slice" $template.appNames) }}
    {{- fail (printf "appNames must be either a variable or a list: %s" $template.appNames )}}
  {{- end }}
{{- end }}

{{- define "elCicdRenderer.processTemplates" }}
  {{- $ := index . 0 }}
  {{- $templates := index . 1 }}
  {{- $elCicdDefs := index . 2 }}

  {{- range $template := $templates }}
    {{- $templateDefs := deepCopy $elCicdDefs }}
    {{- $_ := set $template "appName" ($template.appName | default $templateDefs.APP_NAME) }}
    {{- $_ := required "elCicdRenderer must define template.appName or elCicdDefs.APP_NAME!" $template.appName }}
    {{- $_ := set $templateDefs "APP_NAME" $template.appName }}

    {{- include "elCicdRenderer.mergeMapInto" (list $ $template.elCicdDefs $templateDefs) }}
    {{- include "elCicdRenderer.mergeProfileDefs" (list $ $template $templateDefs) }}

    {{- include "elCicdRenderer.processMap" (list $ $template $templateDefs) }}
  {{- end }}
{{- end }}

{{- define "elCicdRenderer.processMap" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $elCicdDefs := index . 2 }}

  {{- range $key, $value := $map }}
    {{- if not $value }}
      {{- $_ := set $map $key dict }}
    {{- else }}
      {{- $args := (list $ $map $key $elCicdDefs) }}
      {{- if (kindIs "map" $value) }}
        {{- include "elCicdRenderer.processMap" (list $ $value $elCicdDefs) }}
      {{- else if (kindIs "slice" $value) }}
        {{- include "elCicdRenderer.processSlice" (list $ $map $key $elCicdDefs) }}
      {{- else if (kindIs "string" $value) }}
          {{- include "elCicdRenderer.processMapValue" (list $ $map $key $elCicdDefs list 0) }}
      {{- end  }}

      {{- if (get $map $key) }}
        {{- include "elCicdRenderer.processMapKey" (list $ $map $key $elCicdDefs list 0) }}
      {{- else }}
        {{- $_ := unset $map $key }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdRenderer.processMapValue" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $elCicdDefs := index . 3 }}
  {{- $processDefList := index . 4}}
  {{- $depth := index . 5 }}
  
  {{- $value := get $map $key }}
  {{- if gt $depth (int $.Values.MAX_RECURSION) }}
    {{- fail (printf "ERROR: Potential circular reference?\nelCicdDefs Found [%s]: %s\n%s: %s " $elCicdDefs.APP_NAME $processDefList $key $value) }}
  {{- end }}
  {{- $depth := add $depth 1 }}
  
  {{- if (hasPrefix $.Values.FILE_PREFIX $value) }}
    {{- $filePath := ( $value | trimPrefix $.Values.FILE_PREFIX | trimSuffix "}") }} 
    {{- $value = $.Files.Get $filePath }}
  {{- else if  (hasPrefix $.Values.CONFIG_FILE_PREFIX $value) }}
    {{- $filePath := ( $value | trimPrefix $.Values.CONFIG_FILE_PREFIX | trimSuffix "}") }} 
    {{- $value = $.Files.AsConfig $filePath }}
  {{- end }}
  {{- $_ := set $map $key $value }}
  
  {{- $matches := regexFindAll $.Values.ELCICD_PARAM_REGEX $value -1 | uniq }}
  {{- range $elCicdRef := $matches }}
    {{- $elCicdDef := regexReplaceAll $.Values.ELCICD_PARAM_REGEX $elCicdRef "${1}" }}
    {{- $processDefList = append $processDefList $elCicdDef }}

    {{- $paramVal := get $elCicdDefs $elCicdDef }}
    
    {{ if (kindIs "string" $paramVal) }}
      {{- $value = replace $elCicdRef (toString $paramVal) $value }}
    {{- else }}
      {{- if (kindIs "map" $paramVal) }}
        {{- $paramVal = deepCopy $paramVal }}
      {{- else if (kindIs "slice" $paramVal) }}
        {{- if (kindIs "map" (first $paramVal)) }}
          {{- $newList := list }}
          {{- range $element := $paramVal }}
            {{- $newList = append $newList (deepCopy $element) }}
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
        {{- include "elCicdRenderer.processMap" (list $ $value $elCicdDefs) }}
      {{- else if (kindIs "slice" $value) }}
        {{- include "elCicdRenderer.processSlice" (list $ $map $key $elCicdDefs) }}
      {{- else if (kindIs "string" $value) }}
        {{- include "elCicdRenderer.processMapValue" (list $ $map $key $elCicdDefs $processDefList $depth) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdRenderer.processMapKey" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $elCicdDefs := index . 3 }}
  {{- $processDefList := index . 4}}

  {{- $value := get $map $key }}
  {{- $oldKey := $key }}
  {{- $matches := regexFindAll $.Values.ELCICD_PARAM_REGEX $key -1 }}
  {{- range $elCicdRef := $matches }}
    {{- $elCicdDef := regexReplaceAll $.Values.ELCICD_PARAM_REGEX $elCicdRef "${1}" }}
    {{- include "elCicdRenderer.circularReferenceCheck" (list $value $key $elCicdRef $elCicdDef $processDefList) }}
    {{- $processDefList = append $processDefList $elCicdDef }}
    
    {{- $paramVal := get $elCicdDefs $elCicdDef }}
    {{ $_ := unset $map $key }}
    {{- $key = replace $elCicdRef (toString $paramVal) $key }}
  {{- end }}
  {{- if ne $oldKey $key }}
    {{- $_ := unset $map $oldKey }}
  {{- end }}
  {{- if and $matches (ne $oldKey $key) $key }}
    {{- $_ := set $map $key $value }}
    {{- include "elCicdRenderer.processMapKey" (list $ $map $key $elCicdDefs $processDefList) }}
  {{- end }}
{{- end }}

{{- define "elCicdRenderer.processSlice" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $elCicdDefs := index . 3 }}

  {{- $list := get $map $key }}
  {{- $newList := list }}
  {{- range $element := $list }}
    {{- if and (kindIs "map" $element) }}
      {{- include "elCicdRenderer.processMap" (list $ $element $elCicdDefs) }}
    {{- else if (kindIs "string" $element) }}
      {{- $matches := regexFindAll $.Values.ELCICD_PARAM_REGEX $element -1 }}
      {{- range $elCicdRef := $matches }}
        {{- $elCicdDef := regexReplaceAll $.Values.ELCICD_PARAM_REGEX $elCicdRef "${1}" }}
        {{- $paramVal := get $elCicdDefs $elCicdDef }}
        {{- if (kindIs "string" $paramVal) }}
          {{- $element = replace $elCicdRef (toString $paramVal) $element }}
        {{- else if and (kindIs "map" $paramVal) }}
          {{- include "elCicdRenderer.processMap" (list $ $paramVal $elCicdDefs) }}
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