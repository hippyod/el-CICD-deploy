# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elcicd-renderer.generateAllTemplates" }}
  {{- $ := . }}

  {{- include "elcicd-renderer.filterTemplates" $ }}

  {{- $allTemplates := list }}
  {{- $_ := set $.Values "objNameTemplates" list }}
  {{- $_ := set $.Values "namespaceTemplates" list }}
  {{- range $template := $.Values.renderingTemplates  }}
    {{- if $template.objName }}
      {{- if eq $template.objName "${OBJ_NAME}" }}
        {{- $failMsgTpl := "templateName %s objName: $<OBJ_NAME>: OBJ_NAME IS RESERVED; use different variable name or elCicdDefaults.objName" }}
        {{- fail (printf $failMsgTpl $template.templateName) }}
      {{- end }}
    {{- end }}

    {{- if $template.objNames }}
      {{- include "elcicd-renderer.processTemplateGenerator" (list $ $template "objNames") }}
      {{- include "elcicd-renderer.processTplObjNames" (list $ $template) }}
    {{- else }}
      {{- $_ := set $template "objName" ($template.objName | default $.Values.elCicdDefaults.objName) }}
    {{- end }}

    {{- if $template.namespaces }}
      {{- include "elcicd-renderer.processTemplateGenerator" (list $ $template "namespaces") }}
      {{- include "elcicd-renderer.processTplNamespaces" (list $ $template $.Values.elCicdDefs) }}
    {{- end }}

    {{- if not (or $template.objNames $template.namespaces) }}
      {{- $allTemplates = append $allTemplates $template }}
    {{- end }}
  {{- end }}

  {{- $_ := set $.Values "allTemplates" (concat $allTemplates $.Values.objNameTemplates $.Values.namespaceTemplates) }}
{{- end }}

{{- define "elcicd-renderer.processTemplateGenerator" }}
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
        {{- fail (printf "%s cannot be empty [undefined variable reference]: %s" $generatorName $elCicdDef) }}
      {{- end }}
      {{- $generatorVal = $paramVal }}
    {{- end }}

    {{- $_ := set $template $generatorName $generatorVal }}
    {{- if $matches }}
      {{- include "elcicd-renderer.processTemplateGenerator" (list $ $template $generatorName) }}
    {{- end }}
  {{- else if not (kindIs "slice" $generatorVal) }}
    {{- fail (printf "%s must be either a variable or a list: %s" $generatorName $generatorVal )}}
  {{- end }}
{{- end }}

{{- define "elcicd-renderer.processTplObjNames" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}

  {{- $resultMap := dict }}
  {{- $objNameTemplates := list }}
  {{- range $index, $objName := $template.objNames }}
    {{- $newTemplate := deepCopy $template }}
    {{- $_ := set $newTemplate "objName" ($newTemplate.objName | default $objName) }}
    {{- $_ := set $newTemplate "baseObjName" $objName }}

    {{- $objName = replace "$<>" $objName $newTemplate.objName }}
    {{- $objName = replace "$<#>" (add $index 1 | toString) $objName }}

    {{- $_ := set $resultMap $.Values.PROCESS_STRING_VALUE ($objName | toString) }}
    {{- include "elcicd-renderer.processString" (list $ $resultMap  $.Values.elCicdDefs) }}
    {{- $objName = get $resultMap $.Values.PROCESS_STRING_VALUE }}

    {{- $_ := set $newTemplate "objName" ($objName | toString) }}
    {{- $objNameTemplates = append $objNameTemplates $newTemplate }}
  {{- end }}

  {{- $_ := set $.Values "objNameTemplates" (concat $.Values.objNameTemplates $objNameTemplates) }}
{{- end }}

{{- define "elcicd-renderer.processTplNamespaces" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  {{- $elCicdDefs := index . 2 }}

  {{- $resultMap := dict }}
  {{- $namespaceTemplates := list }}
  {{- range $index, $namespace := $template.namespaces }}
    {{- $newTemplate := deepCopy $template }}
    {{- $_ := set $newTemplate "namespace" ($newTemplate.namespace | default $namespace) }}
    {{- $_ := set $newTemplate "baseNamespace" $newTemplate.namespace }}
    {{- $_ := set $template "elCicdDefs" ($newTemplate.elCicdDefs | default dict) }}

    {{- $namespace = replace "$<>" $namespace $newTemplate.namespace }}
    {{- $namespace = replace "$<#>" (add $index 1 | toString) $namespace }}

    {{- $_ := set $resultMap $.Values.PROCESS_STRING_VALUE ($namespace | toString) }}
    {{- include "elcicd-renderer.processString" (list $ $resultMap $elCicdDefs) }}
    {{- $namespace = get $resultMap $.Values.PROCESS_STRING_VALUE }}

    {{- $_ := set $newTemplate "namespace" $namespace }}
    {{- $namespaceTemplates = append $namespaceTemplates $newTemplate }}
  {{- end }}

  {{- $_ := set $.Values "namespaceTemplates" (concat $.Values.namespaceTemplates $namespaceTemplates) }}
{{- end }}

{{- define "elcicd-renderer.processTemplates" }}
  {{- $ := index . 0 }}
  {{- $templates := index . 1 }}

  {{- range $template := $templates }}
    {{- $tplElCicdDefs := dict }}
    {{- include "elcicd-renderer.deepCopyDict" (list $.Values.elCicdDefs $tplElCicdDefs) }}
    {{- include "elcicd-renderer.deepCopyDict" (list $template.elCicdDefs $tplElCicdDefs) }}
    {{- include "elcicd-renderer.mergeElCicdDefs" (list $ $.Values $tplElCicdDefs $template.baseObjName $template.objName) }}
    {{- include "elcicd-renderer.mergeElCicdDefs" (list $ $template $tplElCicdDefs $template.baseObjName $template.objName) }}
    {{- include "elcicd-renderer.preProcessFilesAndConfig" (list $ $tplElCicdDefs) }}

    {{- $_ := set $tplElCicdDefs "EL_CICD_DEPLOYMENT_TIME" $.Values.EL_CICD_DEPLOYMENT_TIME }}
    {{- $_ := set $tplElCicdDefs "EL_CICD_DEPLOYMENT_TIME_NUM" $.Values.EL_CICD_DEPLOYMENT_TIME_NUM }}
    {{- $_ := set $tplElCicdDefs "OBJ_NAME" $template.objName }}
    {{- $_ := set $tplElCicdDefs "BASE_OBJ_NAME" ($template.baseObjName | default $template.objName) }}
    {{- $_ := set $tplElCicdDefs "NAME_SPACE" $template.namespace }}
    {{- $_ := set $tplElCicdDefs "BASE_NAME_SPACE" ($template.baseNamespace | default $template.namespace) }}

    {{- include "elcicd-renderer.processMap" (list $ $template $tplElCicdDefs) }}
  {{- end }}
{{- end }}

{{- define "elcicd-renderer.processMap" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $elCicdDefs := index . 2 }}

  {{- range $key, $value := $map }}
    {{- if not $value }}
      {{- $_ := set $map $key dict }}
    {{- else }}
      {{- $args := (list $ $map $key $elCicdDefs) }}
      {{- if (kindIs "map" $value) }}
        {{- include "elcicd-renderer.processMap" (list $ $value $elCicdDefs) }}
      {{- else if (kindIs "slice" $value) }}
        {{- include "elcicd-renderer.processSlice" (list $ $map $key $elCicdDefs) }}
      {{- else if (kindIs "string" $value) }}
        {{- include "elcicd-renderer.processMapValue" (list $ $map $key $elCicdDefs list 0) }}
      {{- end  }}

      {{- if (get $map $key) }}
        {{- include "elcicd-renderer.processMapKey" (list $ $map $key $elCicdDefs list 0) }}
      {{- else }}
        {{- $_ := unset $map $key }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elcicd-renderer.processMapValue" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $elCicdDefs := index . 3 }}
  {{- $processDefList := index . 4}}
  {{- $depth := index . 5 }}

  {{- $value := get $map $key }}
  {{- if gt $depth (int $.Values.MAX_RECURSION) }}
    {{- $formatMsg := "\nPotential circular reference? Exceeded %s recursions!" }}
    {{- $formatMsg = (cat $formatMsg "\nelCicdDefs.OBJ_NAME: %s\nkey: %s\n---\n== Value ==\n%s\n---\n== processDefList ==\n%s\n---\n== elCicdDefs ==\n%s\n---") }}
    {{- fail (printf $formatMsg (toString $.Values.MAX_RECURSION) $elCicdDefs.OBJ_NAME $key $value $processDefList $elCicdDefs) }}
  {{- end }}
  {{- $depth := add $depth 1 }}

  {{- $matches := regexFindAll $.Values.ELCICD_PARAM_REGEX $value -1 | uniq }}
  {{- include "elcicd-renderer.replaceParamRefs" (list $ $map $key $elCicdDefs $matches) }}
  {{- $processDefList = (concat $processDefList $matches | uniq)  }}

  {{- $value := get $map $key }}
  {{- if and $matches $value }}
    {{- if (kindIs "map" $value) }}
      {{- include "elcicd-renderer.processMap" (list $ $value $elCicdDefs) }}
    {{- else if (kindIs "slice" $value) }}
      {{- include "elcicd-renderer.processSlice" (list $ $map $key $elCicdDefs) }}
    {{- else if (kindIs "string" $value) }}
      {{- include "elcicd-renderer.processMapValue" (list $ $map $key $elCicdDefs $processDefList $depth) }}

      {{- $value = get $map $key }}
    {{- end }}
  {{- end }}
  
  {{- if (kindIs "string" $value) }}
    {{- $_ := set $map $key (regexReplaceAll $.Values.ELCICD_ESCAPED_REGEX $value $.Values.ELCICD_UNESCAPED_REGEX) }}
  {{- end }}
{{- end }}

{{- define "elcicd-renderer.replaceParamRefs" }}
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
      {{- if not (hasPrefix "$" $elCicdRef ) }}
        {{- $elCicdRef = substr 1 (len $elCicdRef) $elCicdRef }}
      {{- end }}
      {{- if contains "\n" $paramVal }}
        {{- $indentRegex := printf "%s%s" ".*" (replace "$" "[$]" $elCicdRef) }}
        {{- $indentation := regexFindAll $indentRegex $value 1 | first | replace $elCicdRef "" }}
        {{- if $indentation }}
          {{- $indentation = printf "%s%s" "\n" (repeat (len $indentation) " ") }}
          {{- $paramVal = replace "\n" $indentation $paramVal }}
        {{- end }}
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

{{- define "elcicd-renderer.processMapKey" }}
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
    {{- include "elcicd-renderer.circularReferenceCheck" (list $value $key $elCicdRef $elCicdDef $processDefList) }}
    {{- $processDefList = append $processDefList $elCicdDef }}

    {{- $paramVal := get $elCicdDefs $elCicdDef }}
    {{- $_ := unset $map $key }}
    {{- if not (hasPrefix "$" $elCicdRef ) }}
      {{- $elCicdRef = substr 1 (len $elCicdRef) $elCicdRef }}
    {{- end }}
    {{- $key = replace $elCicdRef (toString $paramVal) $key }}
  {{- end }}
  {{- if ne $oldKey $key }}
    {{- $_ := unset $map $oldKey }}
  {{- end }}
  {{- if and $matches (ne $oldKey $key) $key }}
    {{- $oldKey = $key }}
    {{- $_ := set $map $key $value }}
    {{- include "elcicd-renderer.processMapKey" (list $ $map $key $elCicdDefs $processDefList) }}
  {{- end }}
  
  {{- $key := regexReplaceAll $.Values.ELCICD_ESCAPED_REGEX $key $.Values.ELCICD_UNESCAPED_REGEX }}
  {{- if ne $oldKey $key }}
    {{- $_ := unset $map $oldKey }}
    {{- $_ := set $map $key $value }}
  {{- end }}
{{- end }}

{{- define "elcicd-renderer.processSlice" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $elCicdDefs := index . 3 }}

  {{- $list := get $map $key }}
  {{- $newList := list }}
  {{- $resultMap := dict }}
  {{- range $element := $list }}
    {{- if and (kindIs "map" $element) }}
      {{- include "elcicd-renderer.processMap" (list $ $element $elCicdDefs) }}
    {{- else if (kindIs "string" $element) }}
      {{- $_ := set $resultMap $.Values.PROCESS_STRING_VALUE ($element | toString) }}
      {{- include "elcicd-renderer.processString" (list $ $resultMap $elCicdDefs) }}
      {{- $element = get $resultMap $.Values.PROCESS_STRING_VALUE }}
    {{- end }}

    {{- if $element }}
      {{- $newList = append $newList $element }}
    {{- end }}
  {{- end }}

  {{- $_ := set $map $key $newList }}
{{- end }}

{{- define "elcicd-renderer.processString" }}
  {{- $ := index . 0 }}
  {{- $resultMap := index . 1 }}
  {{- $elCicdDefs := index . 2 }}

  {{- $element := get $resultMap $.Values.PROCESS_STRING_VALUE }}
  {{- $matches := regexFindAll $.Values.ELCICD_PARAM_REGEX $element -1 }}
  {{- range $elCicdRef := $matches }}
    {{- $elCicdDef := regexReplaceAll $.Values.ELCICD_PARAM_REGEX $elCicdRef "${1}" }}
    {{- $paramVal := get $elCicdDefs $elCicdDef }}
    {{- if (kindIs "string" $paramVal) }}
      {{- if not (hasPrefix "$" $elCicdRef ) }}
        {{- $elCicdRef = substr 1 (len $elCicdRef) $elCicdRef }}
      {{- end }}
      {{- if contains "\n" $paramVal }}
        {{- $indentRegex := printf "%s%s" ".*" (replace "$" "[$]" $elCicdRef) }}
        {{- $indentation := regexFindAll $indentRegex $element 1 | first | replace $elCicdRef "" }}
        {{- if $indentation }}
          {{- $paramVal = replace "\n" (cat "\n" $indentation) $paramVal }}
        {{- end }}
      {{- end }}
      {{- $element = replace $elCicdRef (toString $paramVal) $element }}
    {{- else }}
      {{- if (kindIs "map" $paramVal) }}
        {{- include "elcicd-renderer.processMap" (list $ $paramVal $elCicdDefs) }}
      {{- end }}
      {{- $element = $paramVal }}
    {{- end }}
  {{- end }}

  {{- if $matches }}
    {{- $_ := set $resultMap $.Values.PROCESS_STRING_VALUE $element }}
    {{- if (kindIs "string" $element) }}
      {{- include "elcicd-renderer.processString" (list $ $resultMap $elCicdDefs) }}
    {{- end }}
  {{- end }}
{{- end }}