# SPDX-License-Identifier: LGPL-2.1-or-later

{{/*
  ======================================
  elcicd-renderer.mergeElCicdDefs
  ======================================

  Merges all elCicdDefs dictionaries based on profiles and object names to create a
  dictionary of variable definitions that will be used before finally rendering the el-CICD template.
  This template is called twice for the overall chart (in case 

  Order of precedence in ascending order:

    1. elCicdDefsMap
       i. Source map submitted for merging.
          a. If merging variable definitions a the top level, this will be a copy of Values.elCicdDefs
          b. If merging variable definitions for a template, this will be a copy of the fully merged, top level elCicdDefs map.
    2. elCicdDefs-<profile>
       i. Following Helm standard, in order of listed profiles
    3. elCicdDefs-<baseObjName>
       i. baseObjName is the raw name from the objNames list before modification
    4. elCicdDefs-<objName>
       i. objName is the final, processed name of the resource being generated from the objNames list
    5. elCicdDefs-<baseObjName>-<profile>
       i. Same as elCicdDefs-<baseObjName>, but only for a specific profile
    6. elCicdDefs-<objName>-<profile>
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

  Recursively copies keys and values of a source dictionary into a destination dictionary.
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