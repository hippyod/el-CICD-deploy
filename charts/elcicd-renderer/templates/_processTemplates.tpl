# SPDX-License-Identifier: LGPL-2.1-or-later

{{/*
  ======================================
  elcicd-renderer.generateAllTemplates
  ======================================

  Merges all elCicdDefs dictionaries based on profiles and object names to create a
  dictionary of variables that will be used before finally rendering the el-CICD template.

  Order of precedence in ascending order is as follows dictionaries:

    1. elCicdDefsMap
      i. Source map submitted for merging.
          a. If merging variable definitions a the top level, this will be a copy of Values.elCicdDefs
          b. If merging variable definitions for a template, this will be a copy of the fully merged, top level elCicdDefs map.
    2. elCicdDefs-<profile>
      i. Following Helm standard, in order of listed profiles
    3. elCicdDefs-<baseObjName>
      i. baseObjName is the raw name of the object to be created before modification
      ii. Use this form if all permutations of a template should recieve the values defined in this map
    4. elCicdDefs-<objName>
      i. objName is the final name of the resource being generated from the el-CICD template
      ii. Use this form if only a specific permutation of a template should recieve the values defined in this map
    5. elCicdDefs-<profile>-<baseObjName>
      i. Same as elCicdDefs-<baseObjName>, but only for a specific profile
    6. elCicdDefs-<profile>-<objName>
      i. Same as elCicdDefs-<objName>, but only for a specific profile

    Merged results are returned in destElCicdDefs.
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

  If a objNames key is defined on an el-CICD template, generate a copy of the template per value
  in the objName list and append and add to the list of templates to render. The baseObjName will
  be equivalent to the value in the list.  objName will will by default be equal to the baseObjName
  unless otherwise templated with text.

  Example objName template:
    objName: <text>-$<>-<more text>-$<#>

    objName values will replace the pattern `$<>` with the baseObjName
    objName values will replace the pattern `$<#>` index of the baseObjName in the matrix
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

  If a namespaces key is defined on an el-CICD template, generate a copy of the template per value
  in the namespace list and append and add to the list of templates to render.  The baseNamespace will
  be equivalent to the value in the list.  namespace for the template will by default be equal to the
  baseNamespace unless otherwise templated with text.

  Example objName template:
    namespace: <text>-$<>-<more text>-$<#>

    namespace values will replace the pattern `$<>` with the baseNamespace
    namespace values will replace the pattern `$<#>` index of the baseNamespace in the matrix
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

  Checks matrixKey (e.g. namespaces or objNames) on the el-CICD template.  If it's a variable,
  it dereferences it.  Verifies end result is a string.
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

  Process all el-CICD templates in the template list before rendering.  This means building the template
  specific dictionary of el-CICD Chart variables, and then adding or replacing all variable references in
  el-CICD Chart template with values.

  Process a template has the following steps:

  1. Create a copy of the globally defined dictionary of el-CICD variables
  2. Copy the template specific, general (elCicdDefs) el-CICD variables into the copy of the global variable dictionary
    i. This dictionary represents the sum total of non-profile or object name specific variables
  3. Merge globally defined baseObjName and objName specific variables into the template variable dictionary
  4. Merge template defined baseObjName and objName specific variables into the template variable dictionary
  5. Add key/values pairs from config files (donoted as $<FILE|path>) into the dictionary
  6. Inject default el-CICD variables into final dictionary
    i. EL_CICD_DEPLOYMENT_TIME_NUM: deployment time in milliseconds
    ii. EL_CICD_DEPLOYMENT_TIME: human readable deployment time
  iii. BASE_OBJ_NAME: baseObjName of template
    iv. OBJ_NAME: objName of template
    v. BASE_NAME_SPACE: base name of namespace final resource will be deployed to
    vi. NAME_SPACE: namespace the final resource will be deployed to
  7. Copy the elCicdDefaults dictionary onto the template
  8. Replace all el-CICD variable references in the template with values in the final
     el-CICD template variable dictionary (elcicd-renderer.replaceVarRefsInMap)
*/}}
{{- define "elcicd-renderer.processTemplates" }}
  {{- $ := index . 0 }}
  {{- $templates := index . 1 }}

  {{- include "elcicd-renderer.preProcessTemplatesElCicdDefs" (list $ $.Values $.Values.elCicdDefs) }}  
  {{- range $template := $templates }}
    {{- $tplElCicdDefs := dict }}    
    {{- include "elcicd-renderer.deepCopyDict" (list $.Values.elCicdDefs $tplElCicdDefs) }}
    {{- include "elcicd-renderer.deepCopyDict" (list $template.elCicdDefs $tplElCicdDefs) }}
    
    {{- include "elcicd-renderer.preProcessTemplatesElCicdDefs" (list $ $template $tplElCicdDefs) }}  
    
    {{- include "elcicd-renderer.mergeElCicdDefs" (list $ $.Values $tplElCicdDefs $template.baseObjName $template.objName) }}
    {{- include "elcicd-renderer.mergeElCicdDefs" (list $ $template $tplElCicdDefs $template.baseObjName $template.objName) }}
    {{- include "elcicd-renderer.preProcessFilesAndConfig" (list $ $tplElCicdDefs) }}
    {{- include "elcicd-renderer.mergeElCicdDefs" (list $ $template $tplElCicdDefs $template.baseObjName $template.objName) }}
    
    {{- $_ := set $tplElCicdDefs "EL_CICD_DEPLOYMENT_TIME_NUM" $.Values.EL_CICD_DEPLOYMENT_TIME_NUM }}
    {{- $_ := set $tplElCicdDefs "EL_CICD_DEPLOYMENT_TIME" $.Values.EL_CICD_DEPLOYMENT_TIME }}

    {{- $_ := set $tplElCicdDefs "BASE_OBJ_NAME" ($template.baseObjName | default $template.objName) }}
    {{- $_ := set $tplElCicdDefs "OBJ_NAME" $template.objName }}

    {{- $_ := set $template "namespace" ($template.namespace | default $.Release.Namespace) }}
    {{- $_ := set $tplElCicdDefs "BASE_NAME_SPACE" ($template.baseNamespace | default $template.namespace) }}
    {{- $_ := set $tplElCicdDefs "NAME_SPACE" $template.namespace }}

    {{- $_ := set $template "elCicdDefaults" dict }}
    {{- include "elcicd-renderer.deepCopyDict" (list $.Values.elCicdDefaults $template.elCicdDefaults) }}

    {{- include "elcicd-renderer.replaceVarRefsInMap" (list $ $template $tplElCicdDefs list dict) }}
    
    {{- $_ := set $template "tplElCicdDefs" $tplElCicdDefs }}
  {{- end }}
{{- end }}

{{- define "elcicd-renderer.preProcessTemplatesElCicdDefs" }}
  {{- $ := index . 0 }}
  {{- $elCicdDefsMap := index . 1 }}
  {{- $elCicdDefs := index . 2 }}

  {{- $resultDict := dict }}
  {{- $resultKey := uuidv4 }}
  {{ range $key, $value := $elCicdDefsMap }}
    {{- if hasPrefix "elCicdDefs" $key }}
      {{- include "elcicd-renderer.replaceRefsInMapKey" (list $ $elCicdDefsMap $key $elCicdDefs $resultDict $resultKey) }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  elcicd-renderer.replaceVarRefsInMap
  ======================================

  Walk the dictionary and replace any el-CICD variable references with their values.  Depending on
  the type and location of the variable reference, another Helm template will be called.  In particular,
  if a dict value is of type:
  - map -> elcicd-renderer.replaceVarRefsInMap (i.e. recursive call)
  - slice -> elcicd-renderer.replaceVarRefsInSlice
  - string -> elcicd-renderer.replaceVarRefsInMapValue

  And if a key in the map is a variable reference, call elcicd-renderer.replaceVarRefsInMapKey.
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

  {{- $depth := add1 (get $resultDict $.Values.__DEPTH | default 0) }}
  {{- if eq $depth 1 }}
    {{- $_ := set $resultDict $.Values.__ORIG_VALUE_KEY (substr 0 120 (toString $value)) }}
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
      {{- $_ := set $resultDict $.Values.__DEPTH $depth }}
      {{- if gt $depth $.Values.__MAX_DEPTH }}
        {{- $origValue := get $resultDict $.Values.__ORIG_VALUE_KEY }}
        {{- fail (print "Stack depth (" $.Values.__MAX_DEPTH ") exceeded: \nVAR STACK: " (join " -> " $processedVarsList) "\nvalues.yaml REF: " $origValue) }}
      {{- end }}
      {{- include "elcicd-renderer.processValue" (list $ $newValue $elCicdDefs $processedVarsList $resultDict $resultKey) }}
    {{- end }}
    {{- $_ := set $resultDict $.Values.__DEPTH (sub $depth 1) }}
  {{- end  }}

  {{- $value := get $resultDict $resultKey }}
  {{- if and (kindIs "string" $value) (eq $depth 1) }}
    {{- $_ := set $resultDict $resultKey (regexReplaceAll $.Values.ELCICD_ESCAPED_REGEX $value $.Values.ELCICD_UNESCAPED_REGEX) }}
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

  {{- $matches := regexFindAll $.Values.ELCICD_PARAM_REGEX $value -1 }}
  {{- $localProcessedVars := list }}
  {{- range $elCicdRef := $matches }}
    {{- $elCicdVarName := regexReplaceAll $.Values.ELCICD_PARAM_REGEX $elCicdRef "${1}" }}
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