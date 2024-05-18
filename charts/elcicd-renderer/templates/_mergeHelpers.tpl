# SPDX-License-Identifier: LGPL-2.1-or-later
{{/*
  ======================================
  elcicd-renderer.mergeElCicdDefs
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
{{- end }}

{{/*
  ======================================
  elcicd-renderer.deepCopyDict
  ======================================

  Recursively copies keys and values of a source dictionary into destination dictionary.
*/}}
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