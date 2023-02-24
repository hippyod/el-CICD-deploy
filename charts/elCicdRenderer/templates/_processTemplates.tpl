# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elCicdRenderer.generateAllTemplates" }}
  {{- $ := . }}
  
  {{- range $key, $value := $.Values }}
    {{- if hasPrefix "elCicdTemplates-" $key }}
      {{- $_ := set $.Values "elCicdTemplates" (concat $.Values.elCicdTemplates (get $.Values $key)) }}
    {{- end }}
  {{- end }}

  {{- include "elCicdRenderer.filterTemplates" $ }}

  {{- $allTemplates := list }}
  {{- $_ := set $.Values "appNameTemplates" list }}
  {{- $_ := set $.Values "namespaceTemplates" list }}
  {{- range $template := $.Values.renderingTemplates  }}
    {{- if $template.appName }}
      {{- if eq $template.appName "${APP_NAME}" }}
        {{- $failMsgTpl := "templateName %s appName: ${APP_NAME}: APP_NAME IS RESERVED; use different variable name or elCicdDefaults.appName" }}
        {{- fail (printf $failMsgTpl $template.templateName) }}
      {{- end }}
    {{- end }}
  
    {{- if $template.appNames }}
      {{- include "elCicdRenderer.processTemplateGenerator" (list $ $template "appNames") }}
      {{- include "elCicdRenderer.processTplAppNames" (list $ $template) }}
    {{- else }}
      {{- $_ := set $template "appName" ($template.appName | default $.Values.elCicdDefaults.appName) }}
      {{- $_ := required "elCicdRenderer must define template.appName or elCicdDefaults.appName!" $template.appName }}
    {{- end }}

    {{- if $template.namespaces }}
      {{- include "elCicdRenderer.processTemplateGenerator" (list $ $template "namespaces") }}
      {{- include "elCicdRenderer.processTplNamespaces" (list $ $template) }}
    {{- end }}

    {{- if not (or $template.appNames $template.namespaces) }}
      {{- $allTemplates = append $allTemplates $template }}
    {{- end }}
  {{- end }}

  {{- $_ := set $.Values "allTemplates" (concat $allTemplates $.Values.appNameTemplates $.Values.namespaceTemplates) }}
{{- end }}

{{- define "elCicdRenderer.processTemplateGenerator" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  {{- $generatorName := index . 2 }}

  {{- $generatorVal := get $template $generatorName  }}
  {{- if kindIs "string" $generatorVal }}
    {{- $matches := regexFindAll $.Values.ELCICD_PARAM_REGEX $generatorVal -1 }}
    {{- range $elCicdRef := $matches }}
      {{- $elCicdDef := regexReplaceAll $.Values.ELCICD_PARAM_REGEX $elCicdRef "${1}" }}

      {{- $paramVal := get $.Values.elCicdDefs $elCicdDef }}
      {{- if not $paramVal }}
        {{- fail (printf "%s cannot be empty [undefined parameter reference]: %s" $generatorName $elCicdDef) }}
      {{- end }}
      {{- $generatorVal = $paramVal }}
    {{- end }}

    {{- $_ := set $template $generatorName $generatorVal }}
    {{- if $matches }}
      {{- include "elCicdRenderer.processTemplateGenerator" (list $ $template $generatorName) }}
    {{- end }}
  {{- else if not (kindIs "slice" $generatorVal) }}
    {{- fail (printf "%s must be either a parameter or a list: %s" $generatorName $generatorVal )}}
  {{- end }}
{{- end }}

{{- define "elCicdRenderer.processTplAppNames" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}

  {{- $appNameTemplates := list }}
  {{- range $index, $appName := $template.appNames }}
    {{- $newTemplate := deepCopy $template }}
    {{- $_ := set $newTemplate "appName" ($newTemplate.appName | default "") }}
    {{- if or (contains "${}" $newTemplate.appName) (contains "${#}" $newTemplate.appName) }}
      {{- $_ := set $newTemplate "elCicdDefs" ($newTemplate.elCicdDefs | default dict) }}
      {{- $_ := set $newTemplate.elCicdDefs "BASE_APP_NAME" $appName }}
      {{- $appName = replace "${}" $appName $newTemplate.appName }}
      {{- $appName = replace "${#}" (add $index 1 | toString) $appName }}
    {{- end }}
    {{- $_ := set $newTemplate "appName" $appName }}
    {{- $appNameTemplates = append $appNameTemplates $newTemplate }}
  {{- end }}

  {{- $_ := set $.Values "appNameTemplates" (concat $.Values.appNameTemplates $appNameTemplates) }}
{{- end }}

{{- define "elCicdRenderer.processTplNamespaces" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}

  {{- $namespaceTemplates := list }}
  {{- range $index, $namespace := $template.namespaces }}
    {{- $newTemplate := deepCopy $template }}
    {{- $_ := set $newTemplate "namespace" ($newTemplate.namespace | default "") }}
    {{- if or (contains "${}" $newTemplate.namespace) (contains "${#}" $newTemplate.namespace) }}
      {{- $_ := set $newTemplate "elCicdDefs" ($newTemplate.elCicdDefs | default dict) }}
      {{- $_ := set $newTemplate.elCicdDefs "BASE_NAME_SPACE" $namespace }}
      {{- $namespace = replace "${}" $namespace $newTemplate.namespace }}
      {{- $namespace = replace "${#}" (add $index 1 | toString) $namespace }}
    {{- end }}
    {{- $_ := set $newTemplate "namespace" $namespace }}
    {{- $namespaceTemplates = append $namespaceTemplates $newTemplate }}
  {{- end }}

  {{- $_ := set $.Values "namespaceTemplates" (concat $.Values.namespaceTemplates $namespaceTemplates) }}
{{- end }}

{{- define "elCicdRenderer.processTemplates" }}
  {{- $ := index . 0 }}
  {{- $templates := index . 1 }}
  {{- $elCicdDefs := index . 2 }}

  {{- range $template := $templates }}
    {{- $templateDefs := deepCopy $elCicdDefs }}
    {{- include "elCicdRenderer.mergeMapInto" (list $ $template.elCicdDefs $templateDefs) }}
    {{- include "elCicdRenderer.mergeProfileDefs" (list $ $template $templateDefs) }}
    {{- include "elCicdRenderer.preProcessFilesAndConfig" (list $ $templateDefs) }}

    {{- $_ := set $.Values.elCicdDefs "EL_CICD_DEPLOYMENT_TIME" $.Values.EL_CICD_DEPLOYMENT_TIME }}
    {{- $_ := set $templateDefs "APP_NAME" $template.appName }}
    {{- $_ := set $templateDefs "BASE_APP_NAME" ($templateDefs.BASE_APP_NAME | default $templateDefs.APP_NAME) }}
    {{- $_ := set $templateDefs "NAME_SPACE" $template.namespace }}
    {{- $_ := set $templateDefs "BASE_NAME_SPACE" ($templateDefs.BASE_NAME_SPACE | default $templateDefs.NAME_SPACE) }}

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

  {{- $matches := regexFindAll $.Values.ELCICD_PARAM_REGEX $value -1 | uniq }}
  {{- include "elCicdRenderer.replaceParamRefs" (list $ $map $key $elCicdDefs $matches) }}
  {{- $value := get $map $key }}

  {{- $processDefList = (concat $processDefList $matches | uniq)  }}
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

{{- define "elCicdRenderer.replaceParamRefs" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $elCicdDefs := index . 3 }}
  {{- $matches := index . 4 }}

  {{- $value := get $map $key }}
  {{- range $elCicdRef := $matches }}
    {{- $elCicdDef := regexReplaceAll $.Values.ELCICD_PARAM_REGEX $elCicdRef "${1}" }}

    {{- $paramVal := get $elCicdDefs $elCicdDef }}

    {{- if (kindIs "string" $paramVal) }}
      {{- if not (hasPrefix $elCicdRef "$" ) }}
        {{- $elCicdRef = substr 1 (len $elCicdRef) $elCicdRef }}
      {{- end }}
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

  {{- $_ := set $map $key $value }}
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
    {{- $_ := unset $map $key }}
    {{- if not (hasPrefix $elCicdRef "$" ) }}
      {{- $elCicdRef = substr 1 (len $elCicdRef) $elCicdRef }}
    {{- end }}
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
          {{- if not (hasPrefix $elCicdRef "$" ) }}
            {{- $elCicdRef = substr 1 (len $elCicdRef) $elCicdRef }}
          {{- end }}
          {{- $element = replace $elCicdRef (toString $paramVal) $element }}
        {{- else }}
          {{- if (kindIs "map" $paramVal) }}
            {{- include "elCicdRenderer.processMap" (list $ $paramVal $elCicdDefs) }}
          {{- end }}
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