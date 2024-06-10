# SPDX-License-Identifier: LGPL-2.1-or-later

{{/*
  ======================================
  elcicd-renderer.generateAllTemplates
  ======================================

  PARAMETERS LIST:
    $ -> root of chart
    $templates -> list of elCicdTemplates defined in *values.yaml

  ======================================

  Generates the complete list of el-CICD templates to be rendered based on each template's optional objNames
  and namespaces lists.  objNames are processed first, and namespaces afterwards.

  The final list of templates to be rendered is set to $.Values.allTemplates
*/}}
{{- define "elcicd-renderer.generateAllTemplates" }}
  {{- $ := index . 0 }}
  {{- $templates := index . 1 }}

  {{- $allTemplates := list }}
  {{- $_ := set $.Values "objNameTemplates" list }}
  {{- $_ := set $.Values "namespaceTemplates" list }}
  {{- range $template := $templates }}
    {{- if $template.objName }}
      {{- if eq $template.objName "$<OBJ_NAME>" }}
        {{- $failMsgTpl := "templateName %s objName: $<OBJ_NAME>: OBJ_NAME IS RESERVED; use different variable name or elCicdDefaults.objName" }}
        {{- fail (printf $failMsgTpl $template.templateName) }}
      {{- end }}
    {{- end }}

    {{- if $template.objNames }}
      {{- include "elcicd-renderer.processObjNamesMatrix" (list $ $template $.Values.elCicdDefs) }}
    {{- else }}
      {{- $_ := set $template "objName" ($template.objName | default $.Values.elCicdDefaults.objName) }}
    {{- end }}

    {{- if $template.namespaces }}
      {{- include "elcicd-renderer.processNamespacesMatrix" (list $ $template $.Values.elCicdDefs) }}
    {{- end }}

    {{- if not (or $template.objNames $template.namespaces) }}
      {{- $allTemplates = append $allTemplates $template }}
    {{- end }}
  {{- end }}

  {{- $_ := set $.Values "allTemplates" (concat $allTemplates $.Values.objNameTemplates $.Values.namespaceTemplates) }}
{{- end }}


{{/*
  ======================================
  elcicd-renderer.processObjNamesMatrix
  ======================================

  PARAMETERS LIST:
    $ -> root of chart
    $template -> template defined in *values.yaml to be processed
    $elCicdDefs -> final chart level elCicdDefs

  ======================================


  First evaluate the objNames value for any el-CICD variables and dereference them.  Only chart-level variable definitions will be
  considered.  Next, generate a copy of the template per value in the list and append and add to the list of templates to render.

  If the objName key has a value with $<> in it, it will be replaced with the baseObjName (i.e the value in the objNames list).
  If the objName key has a value with $<#> in it, it will be replaced with the index of baseObjName in the objNames list.
*/}}
{{- define "elcicd-renderer.processObjNamesMatrix" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  {{- $elCicdDefs := index . 2 }}

  {{- include "elcicd-renderer.processTemplateMatrixValue" (list $ $template "objNames") }}

  {{- $resultDict := dict }}
  {{- $resultKey := uuidv4 }}
  {{- $objNameTemplates := list }}
  {{- range $index, $objName := $template.objNames }}
    {{- $newTemplate := deepCopy $template }}
    {{- $_ := set $newTemplate "objName" ($newTemplate.objName | default $objName) }}
    {{- $_ := set $newTemplate "baseObjName" $objName }}

    {{- $objName = replace "$<>" $objName $newTemplate.objName }}
    {{- $objName = replace "$<#>" (add $index 1 | toString) $objName }}

    {{- include "elcicd-renderer.processValue" (list $ $objName $elCicdDefs list $resultDict $resultKey) }}
    {{- $objName := get $resultDict $resultKey }}
    {{- $_ := unset $resultDict $resultKey }}

    {{- $_ := set $newTemplate "objName" ($objName | toString) }}
    {{- $objNameTemplates = append $objNameTemplates $newTemplate }}
  {{- end }}

  {{- $_ := set $.Values "objNameTemplates" (concat $.Values.objNameTemplates $objNameTemplates) }}
{{- end }}

{{/*
  ======================================
  elcicd-renderer.processNamespacesMatrix
  ======================================

  PARAMETERS LIST:
    $ -> root of chart
    $template -> template defined in *values.yaml to be processed
    $elCicdDefs -> final chart level elCicdDefs

  ======================================


  First evaluate the namespaces value for any el-CICD variables and dereference them.  Only chart-level variable definitions will be
  considered.  Next, generate a copy of the template per value in the list and append and add to the list of templates to render.

  If the namespace key has a value with $<> in it, it will be replaced with the baseObjName (i.e the value in the namespaces list).
  If the namespace key has a value with $<#> in it, it will be replaced with the index of baseObjName in the namespaces list.
*/}}
{{- define "elcicd-renderer.processNamespacesMatrix" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  {{- $elCicdDefs := index . 2 }}

  {{- include "elcicd-renderer.processTemplateMatrixValue" (list $ $template "namespaces") }}

  {{- $resultDict := dict }}
  {{- $resultKey := uuidv4 }}
  {{- $namespaceTemplates := list }}
  {{- range $index, $namespace := $template.namespaces }}
    {{- $newTemplate := deepCopy $template }}
    {{- $_ := set $newTemplate "namespace" ($newTemplate.namespace | default $namespace) }}
    {{- $_ := set $newTemplate "baseNamespace" $newTemplate.namespace }}
    {{- $_ := set $template "elCicdDefs" ($newTemplate.elCicdDefs | default dict) }}

    {{- $namespace = replace "$<>" $namespace $newTemplate.namespace }}
    {{- $namespace = replace "$<#>" (add $index 1 | toString) $namespace }}

    {{- include "elcicd-renderer.processValue" (list $ $namespace $elCicdDefs list $resultDict $resultKey) }}
    {{- $namespace := get $resultDict $resultKey }}
    {{- $_ := unset $resultDict $resultKey }}

    {{- $_ := set $newTemplate "namespace" $namespace }}
    {{- $namespaceTemplates = append $namespaceTemplates $newTemplate }}
  {{- end }}

  {{- $_ := set $.Values "namespaceTemplates" (concat $.Values.namespaceTemplates $namespaceTemplates) }}
{{- end }}

{{/*
  ======================================
  elcicd-renderer.processTemplateMatrixValue
  ======================================

  PARAMETERS LIST:
    $ -> root of chart
    $template -> template to operate on.
    $matrixKey -> currently only "namespaces" or "objNames" is supported

  ======================================

  Dereferences any el-CICD variables references in a matrices list; e.g. the objNames or namespaces list.
*/}}
{{- define "elcicd-renderer.processTemplateMatrixValue" }}
  {{- $ := index . 0 }}
  {{- $template := index . 1 }}
  {{- $matrixKey := index . 2 }}

  {{- $generatorVal := get $template $matrixKey }}

  {{- $resultDict := dict }}
  {{- $resultKey := uuidv4 }}
  {{- include "elcicd-renderer.processValue" (list $ $generatorVal $.Values.elCicdDefs list $resultDict $resultKey) }}

  {{- $generatorVal := (get $resultDict $resultKey) | default list }}
  {{- if $generatorVal }}
    {{- if not (kindIs "slice" $generatorVal) }}
      {{- fail (printf "%s must evaluate to nil or a list: %s" $matrixKey (get $template $matrixKey)) }}
    {{- end }}
  {{- end }}

  {{- $_ := set $template $matrixKey $generatorVal }}
{{- end }}

{{/*
  ======================================
  elcicd-renderer.processTemplates
  ======================================

  PARAMETERS LIST:
    $ -> root of chart
    $templates -> list of elCicdTemplates defined in *values.yaml

  ======================================

  Process all el-CICD templates in the template list before rendering.  This means realizing the final
  elCicdDefs for ht

  Process a template has the following steps:

  1. Process all **chart's** el-CICD variable definition maps of the form elCicdDefs-*  (i.e. all .Values.elCicdDefs-*)
     for el-CICD variables using the **chart's** elCicdDefs map (i.e. .Values.elCicdDefs).
     (elcicd-renderer.preProcessElCicdDefsMapNames)
     
  For each template to be rendered:
  
  1. Copy the .Values.elCicdDefs into $tplElCicdDefs (template specific variable defintions). (elcicd-renderer.deepCopyDict)
  2. Copy the $template.elCicdDefs onto $tplElCicdDefs (elcicd-renderer.deepCopyDict)
  3. Process all **template's** el-CICD variable definition maps of the form elCicdDefs-*  (i.e. all $template.elCicdDefs-*)
     for el-CICD variables using the **template's** elCicdDefs map (i.e. $template.elCicdDefs). 
     (elcicd-renderer.preProcessElCicdDefsMapNames)
  4. Merge the different **chart's** elCicdDefs-<baseObjName>-<profile> maps into the $tplElCicdDefs. (elcicd-renderer.mergeElCicdDefs)
  5. Merge the different **templates's** elCicdDefs-<baseObjName>-<profile> maps into the $tplElCicdDefs. (elcicd-renderer.mergeElCicdDefs)
  6. Load any file variable references into the variable values (elcicd-renderer.preProcessFilesAndConfig); e.g.
     elCicdDefs:
      SOME_VAR: $<FILE|file-to-be-loaded.ext> -> loads file-to-be-loaded.ext as text into as the value of SOME_VAR
      SOME_VAR: $<CONFIG|file-to-be-loaded> -> loads an env/properties/conf line delimited file of key/values pairs
                defined by key=value as a map and assigns to the variable SOME_VAR
  7. Sets default/el-CICD built-in values to the template elCicdDefs including:
     - EL_CICD_DEPLOYMENT_TIME_NUM - time of deployment in nanoseconds
     - EL_CICD_DEPLOYMENT_TIME - human readable date and time 
     - BASE_OBJ_NAME - value the objName was derived from if defined
     - OBJ_NAME - name of template; typically translates to metadata.name
     - BASE_NAME_SPACE - value the namespace was derived from if defined
     - NAME_SPACE - namespace the template is being deployed to
     - HELM_RELEASE_NAME - .Release.Name
     - HELM_RELEASE_NAMESPACE - .Release.Namespace
     NOTE: templates that do not have or use namespaces can safely ignore those values.
  8. Adds the el-CICD defaults to the template.
  9. Recursively walks the template realizing the values of all el-CICD variable references in
     keys or values.
     NOTE: variables that realized as empty keys or empty **string** values will be removed from
           the template.
 10. For debugging/documentation purposes, $tplElCicdDefs is added to the template.    
*/}}
{{- define "elcicd-renderer.processTemplates" }}
  {{- $ := index . 0 }}
  {{- $templates := index . 1 }}

  {{- include "elcicd-renderer.preProcessElCicdDefsMapNames" (list $ $.Values $.Values.elCicdDefs) }}
  {{- range $template := $templates }}
    {{- $tplElCicdDefs := dict }}
    {{- include "elcicd-renderer.deepCopyDict" (list $.Values.elCicdDefs $tplElCicdDefs) }}
    {{- include "elcicd-renderer.deepCopyDict" (list $template.elCicdDefs $tplElCicdDefs) }}

    {{- include "elcicd-renderer.preProcessElCicdDefsMapNames" (list $ $template $tplElCicdDefs) }}

    {{- include "elcicd-renderer.mergeElCicdDefs" (list $ $.Values $tplElCicdDefs $template.baseObjName $template.objName) }}
    {{- include "elcicd-renderer.mergeElCicdDefs" (list $ $template $tplElCicdDefs $template.baseObjName $template.objName) }}
    {{- include "elcicd-renderer.preProcessFilesAndConfig" (list $ $tplElCicdDefs) }}

    {{- $_ := set $tplElCicdDefs "EL_CICD_DEPLOYMENT_TIME_NUM" $.Values.__EL_CICD_DEPLOYMENT_TIME_NUM }}
    {{- $_ := set $tplElCicdDefs "EL_CICD_DEPLOYMENT_TIME" $.Values.__EL_CICD_DEPLOYMENT_TIME }}

    {{- $_ := set $tplElCicdDefs "BASE_OBJ_NAME" ($template.baseObjName | default $template.objName) }}
    {{- $_ := set $tplElCicdDefs "OBJ_NAME" $template.objName }}

    {{- $_ := set $template "namespace" ($template.namespace | default $.Release.Namespace) }}
    {{- $_ := set $tplElCicdDefs "BASE_NAME_SPACE" ($template.baseNamespace | default $template.namespace) }}
    {{- $_ := set $tplElCicdDefs "NAME_SPACE" $template.namespace }}

    {{- $_ := set $tplElCicdDefs "HELM_RELEASE_NAME" $.Release.Name }}
    {{- $_ := set $tplElCicdDefs "HELM_RELEASE_NAMESPACE" $.Release.Namespace }}

    {{- $_ := set $template "elCicdDefaults" dict }}
    {{- include "elcicd-renderer.deepCopyDict" (list $.Values.elCicdDefaults $template.elCicdDefaults) }}

    {{- include "elcicd-renderer.replaceVarRefsInMap" (list $ $template $tplElCicdDefs list dict) }}

    {{- $_ := set $template "tplElCicdDefs" $tplElCicdDefs }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  elcicd-renderer.processTemplates
  ======================================

  PARAMETERS LIST:
    $parentMap -> map containing all elCicdDefs
    $elCicdDefs -> el-CICD variable defintiions

  ======================================
  
  Preprocess all elCicdDefs-* maps for el-CICD variables; e.g.:
  
    elCicdDefs:
      SOME_VAR: some-obj-name
      
    elCicdDefs-$<SOME_VAR>:
      VAR_DEF: var-def
    
  result in:
    
    elCicdDefs-some-obj-name:
      VAR_DEF: var-def
  
  And VAR_DEF will be defined for use for any template with the objName "some-obj-name".  Chart level el-CICD maps will
  only use the base elCicdDefs map for processing.  Each template will be evaluated will a map derived from all el-CICD
  variable definitions NOT of the form elCicdDefs-* ATTACHED DIRECTLY TO THE TEMPLATE.
  */}}
{{- define "elcicd-renderer.preProcessElCicdDefsMapNames" }}
  {{- $parentMap := index . 0 }}
  {{- $elCicdDefs := index . 1 }}

  {{- $resultDict := dict }}
  {{- $resultKey := uuidv4 }}
  {{ range $key, $value := $parentMap }}
    {{- if hasPrefix "elCicdDefs-" $key }}
      {{- include "elcicd-renderer.replaceRefsInMapKey" (list $ $parentMap $key $elCicdDefs $resultDict $resultKey) }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  elcicd-renderer.replaceVarRefsInMap
  ======================================

  PARAMETERS LIST:
    $map -> the map to process for el-CICD variable references.
    $elCicdDefs -> el-CICD variable defintiions
    $processedVarsList -> list of variables for tracking recursive depth of processing
    $resultDict -> dctionary for retrieving values from other Helm templates called in this Helm template

  ======================================

  Walk the given dictionary and replace any el-CICD variable references with their values.  Each value will be processed. 
  If the value is an non-empty string, map, or slice then process the key for el-CICD variables; otherwise, remove the 
  key/value pair.
*/}}
{{- define "elcicd-renderer.replaceVarRefsInMap" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $elCicdDefs := index . 2 }}
  {{- $processedVarsList := index . 3 }}
  {{- $resultDict := index . 4 }}

  {{- $resultKey := uuidv4 }}
  {{- range $key, $value := $map }}
    {{- include "elcicd-renderer.processValue" (list $ $value $elCicdDefs $processedVarsList $resultDict $resultKey) }}
    {{- $newValue := get $resultDict $resultKey }}
    {{- $_ := unset $resultDict $resultKey }}

    {{ if or $newValue (kindIs "map" $newValue) (kindIs "slice" $newValue) }}
      {{- $_ := set $map $key $newValue }}
      {{- include "elcicd-renderer.replaceRefsInMapKey" (list $ $map $key $elCicdDefs $resultDict $resultKey) }}
    {{- else }}
      {{- $_ := unset $map $key }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  elcicd-renderer.replaceRefsInMapKey
  ======================================

  PARAMETERS LIST:
    $map -> the map being processed for el-CICD variable references.
    $key -> the key to evaluate for el-CICD variable references.
    $elCicdDefs -> el-CICD variable definitions
    $resultDict -> dctionary for retrieving values from other Helm templates called in this Helm template
    $resultKey -> key used to store and retrieve results from the result dictionary

  ======================================

  Walk the given dictionary and replace any el-CICD variable references with their values.  Each value will be processed. 
  If the value is an empty string, remove the key/value pair; otherwise, process the key for el-CICD variables.  If the key
  is an empty string, remove the key/value pair.  Note that keys MUST resolve to strings, or an error will be raised by Helm.
*/}}
{{- define "elcicd-renderer.replaceRefsInMapKey" }}
  {{- $ := index . 0 }}
  {{- $map := index . 1 }}
  {{- $key := index . 2 }}
  {{- $elCicdDefs := index . 3 }}
  {{- $resultDict := index . 4 }}
  {{- $resultKey := index . 5 }}

  {{- $value := get $map $key }}

  {{- include "elcicd-renderer.processValue" (list $ $key $elCicdDefs list $resultDict $resultKey) }}
  {{- $newKey := get $resultDict $resultKey }}
  {{- $_ := unset $resultDict $resultKey }}

  {{- $_ := unset $map $key }}
  {{- if $newKey }}
    {{- $_ := set $map $newKey $value }}
  {{- end }}
{{- end }}

{{- define "elcicd-renderer.replaceVarRefsInSlice" }}
  {{- $ := index . 0 }}
  {{- $slice := index . 1 }}
  {{- $elCicdDefs := index . 2 }}
  {{- $processedVarsList := index . 3 }}
  {{- $resultDict := index . 4 }}
  {{- $parentResultKey := index . 5 }}

  {{- $newSlice := list }}
  {{- $resultKey := uuidv4 }}
  {{- range $element := $slice }}
    {{- include "elcicd-renderer.processValue" (list $ $element $elCicdDefs $processedVarsList $resultDict $resultKey) }}
    {{- $newElement := get $resultDict $resultKey }}
    {{- $_ := unset $resultDict $resultKey }}

    {{ $newSlice = append $newSlice $newElement }}
  {{- end }}

  {{- $_ := set $resultDict $parentResultKey $newSlice }}
{{- end }}

{{- define "elcicd-renderer.processValue" }}
  {{- $ := index . 0 }}
  {{- $value := index . 1 }}
  {{- $elCicdDefs := index . 2 }}
  {{- $processedVarsList := index . 3 }}
  {{- $resultDict := index . 4 }}
  {{- $resultKey := index . 5 }}

  {{- $depth := add1 (get $resultDict $.Values.__EL_CICD_DEPTH | default 0) }}
  {{- if eq $depth 1 }}
    {{- $_ := set $resultDict $.Values.__EL_CICD_ORIG_VALUE_KEY (substr 0 120 (toString $value)) }}
  {{- end }}

  {{- if (kindIs "map" $value) }}
    {{- include "elcicd-renderer.replaceVarRefsInMap" (list $ $value $elCicdDefs $processedVarsList $resultDict) }}
    {{- $_ := set $resultDict $resultKey $value }}
  {{- else }}
    {{- if (kindIs "slice" $value) }}
      {{- include "elcicd-renderer.replaceVarRefsInSlice" (list $ $value $elCicdDefs $processedVarsList $resultDict $resultKey) }}
    {{- else if (kindIs "string" $value) }}
      {{- $processedVarsKey := uuidv4 }}
      {{- include "elcicd-renderer.replaceVarRefsInString" (list $ $value $elCicdDefs $processedVarsList $resultDict $resultKey $processedVarsKey) }}
      {{- $processedVarsList = get $resultDict $processedVarsKey }}
      {{- $_ := unset $resultDict $processedVarsKey }}
    {{- else }}
      {{- $_ := set $resultDict $resultKey $value }}
    {{- end  }}

    {{- $newValue := get $resultDict $resultKey }}
    {{- if and $newValue (ne (toYaml $value) (toYaml $newValue)) }}
      {{- $_ := set $resultDict $.Values.__EL_CICD_DEPTH $depth }}
      {{- if gt $depth $.Values.__EL_CICD_MAX_DEPTH }}
        {{- $origValue := get $resultDict $.Values.__EL_CICD_ORIG_VALUE_KEY }}
        {{- fail (print "Stack depth (" $.Values.__EL_CICD_MAX_DEPTH ") exceeded: \nVAR STACK: " (join " -> " $processedVarsList) "\nvalues.yaml REF: " $origValue) }}
      {{- end }}
      {{- include "elcicd-renderer.processValue" (list $ $newValue $elCicdDefs $processedVarsList $resultDict $resultKey) }}
    {{- end }}
    {{- $_ := set $resultDict $.Values.__EL_CICD_DEPTH (sub $depth 1) }}
  {{- end  }}

  {{- $value := get $resultDict $resultKey }}
  {{- if and (kindIs "string" $value) (eq $depth 1) }}
    {{- $_ := set $resultDict $resultKey (regexReplaceAll $.Values.__EL_CICD_ESCAPED_REGEX $value $.Values.__EL_CICD_UNESCAPED_REGEX) }}
  {{- end }}
{{- end }}

{{- define "elcicd-renderer.replaceVarRefsInString" }}
  {{- $ := index . 0 }}
  {{- $value := index . 1 }}
  {{- $elCicdDefs := index . 2 }}
  {{- $processedVarsList := index . 3 }}
  {{- $resultDict := index . 4 }}
  {{- $resultKey := index . 5 }}
  {{- $processedVarsKey := index . 6 }}

  {{- $matches := regexFindAll $.Values.__EL_CICD_PARAM_REGEX $value -1 }}
  {{- $localProcessedVars := list }}
  {{- range $elCicdRef := $matches }}
    {{- $elCicdVarName := regexReplaceAll $.Values.__EL_CICD_PARAM_REGEX $elCicdRef "${1}" }}
    {{ if not (has $elCicdRef $localProcessedVars) }}
      {{- $localProcessedVars = append $localProcessedVars $elCicdVarName }}
      {{- $varValue := get $elCicdDefs $elCicdVarName }}

      {{- if (kindIs "string" $varValue) }}
        {{- if not (hasPrefix "$" $elCicdRef) }}
          {{- $elCicdRef = substr 1 (len $elCicdRef) $elCicdRef }}
        {{- end }}
        {{- if contains "\n" $varValue }}
          {{- $indentRegex := printf "%s%s" ".*" (replace "$" "[$]" $elCicdRef) }}
          {{- $indentation := regexFindAll $indentRegex $value 1 | first | replace $elCicdRef "" }}
          {{- if $indentation }}
            {{- $indentation = printf "%s%s" "\n" (repeat (len $indentation) " ") }}
            {{- $varValue = replace "\n" $indentation $varValue }}
          {{- end }}
        {{- end }}
        {{- $value = replace $elCicdRef (toString $varValue) $value }}
      {{- else }}
        {{- if gt (len $matches) 1 }}
          {{- fail (print "Attempting multiple, non-string objects into value: \nSOURCE: " $value "\nVARIABLE(" $elCicdVarName "):" (toYaml $varValue)) }}
        {{- end }}

        {{- if (kindIs "map" $varValue) }}
          {{- $varValue = deepCopy $varValue }}
        {{- else if (kindIs "slice" $varValue) }}
          {{- $newList := list }}
          {{- range $element := $varValue }}
            {{- if (kindIs "map" $element) }}
              {{- $element = deepCopy $element }}
            {{- end }}
            {{- $newList = append $newList $element }}
          {{- end }}
          {{- $varValue = $newList }}
        {{- end }}

        {{- $value = $varValue }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- $_ := set $resultDict $processedVarsKey (concat $processedVarsList ($localProcessedVars | uniq)) }}

  {{- $_ := set $resultDict $resultKey $value }}
{{- end }}