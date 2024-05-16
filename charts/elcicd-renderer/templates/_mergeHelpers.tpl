# SPDX-License-Identifier: LGPL-2.1-or-later

#########################################
##
## ======================================
## elcicd-renderer.circularReferenceCheck
## ======================================
##
## Description: Merges all elCicdDefs dictionaries based on profiles and object names to create a
##              dictionary of variables that will be used before finally rendering the el-CICD template.
##
## Order of precedence of elCicdDefs(-*) dictionaries:
##
#########################################
{{- define "elcicd-renderer.mergeElCicdDefs" }}
  {{- $ := index . 0 }}
  {{- $elCicdDefsMap := index . 1 }}
  {{- $destElCicdDefs := index . 2 }}
  {{- $baseObjName := index . 3 }}
  {{- $objName := index . 4 }}
  
  {{- range $profile := $.Values.elCicdProfiles }}
    {{- $profileDefs := get $elCicdDefsMap (printf "elCicdDefs-%s" $profile) }}
    {{- include "elcicd-renderer.deepCopyDict" (list $profileDefs $destElCicdDefs) }}
  {{- end }}

  {{- if ne $baseObjName $objName }}
    {{- $baseObjNameDefs := get $elCicdDefsMap (printf "elCicdDefs-%s" $baseObjName) }}
    {{- include "elcicd-renderer.deepCopyDict" (list $baseObjNameDefs $destElCicdDefs) }}
  {{- end }}

  {{- if $objName }}
    {{- $objNameDefs := get $elCicdDefsMap (printf "elCicdDefs-%s" $objName) }}
    {{- include "elcicd-renderer.deepCopyDict" (list $objNameDefs $destElCicdDefs) }}
  {{- end }}
    
  {{- range $profile := $elCicdDefsMap.elCicdProfiles }}
    {{- if ne $baseObjName $objName }}
      {{- $baseObjNameDefs := get $elCicdDefsMap (printf "elCicdDefs-%s-%s" $baseObjName $profile) }}
      {{- include "elcicd-renderer.deepCopyDict" (list $baseObjNameDefs $destElCicdDefs) }}
    {{- end }}

    {{- if $objName }}
      {{- $objNameDefs := get $elCicdDefsMap (printf "elCicdDefs-%s-%s" $objName $profile) }}
      {{- include "elcicd-renderer.deepCopyDict" (list $objNameDefs $destElCicdDefs) }}
    {{- end }}
  {{- end }}
    
  {{- include "elcicd-renderer.processMap" (list $ $.Values.elCicdDefaults $destElCicdDefs) }}
{{- end }}

#########################################
##
## ======================================
## elcicd-renderer.deepCopyDict
## ======================================
##
## Description: Recursively copies keys and values of a source dictionary into destination dictionary.
##
#########################################
{{- define "elcicd-renderer.deepCopyDict" }}
  {{- $srcDict := index . 0 }}
  {{- $destDict := index . 1 }}

  {{- if $srcDict }}
    {{- range $key, $value := $srcDict }}
      {{- if (kindIs "map" $value) }}
        {{- $newValue := dict }}
        {{- include "elcicd-renderer.deepCopyDict" (list $value $newValue) }}
        {{- $value = $newValue }}
      {{- end }}
      {{- $_ := set $destDict $key ($value | default "") }}
    {{- end }}
  {{- end }}
{{- end }}