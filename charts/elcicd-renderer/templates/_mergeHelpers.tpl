# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elcicd-renderer.mergeProfileDefs" }}
  {{- $ := index . 0 }}
  {{- $elCicdDefsMap := index . 1 }}
  {{- $destElCicdDefs := index . 2 }}
  {{- $baseObjName := index . 3 }}
  {{- $objName := index . 4 }}
  
  {{- range $profile := $.Values.elCicdProfiles }}
    {{- $profileDefs := get $elCicdDefsMap (printf "elCicdDefs-%s" $profile) }}
    {{- include "elcicd-renderer.deepCopyMap" (list $profileDefs $destElCicdDefs) }}
  {{- end }}

  {{- if ne $baseObjName $objName }}
    {{- $baseObjNameDefs := get $elCicdDefsMap (printf "elCicdDefs-%s" $baseObjName) }}
    {{- include "elcicd-renderer.deepCopyMap" (list $baseObjNameDefs $destElCicdDefs) }}
  {{- end }}

  {{- if $objName }}
    {{- $objNameDefs := get $elCicdDefsMap (printf "elCicdDefs-%s" $objName) }}
    {{- include "elcicd-renderer.deepCopyMap" (list $objNameDefs $destElCicdDefs) }}
  {{- end }}
    
  {{- range $profile := $elCicdDefsMap.elCicdProfiles }}
    {{- if ne $baseObjName $objName }}
      {{- $baseObjNameDefs := get $elCicdDefsMap (printf "elCicdDefs-%s-%s" $baseObjName $profile) }}
      {{- include "elcicd-renderer.deepCopyMap" (list $baseObjNameDefs $destElCicdDefs) }}
    {{- end }}

    {{- if $objName }}
      {{- $objNameDefs := get $elCicdDefsMap (printf "elCicdDefs-%s-%s" $objName $profile) }}
      {{- include "elcicd-renderer.deepCopyMap" (list $objNameDefs $destElCicdDefs) }}
    {{- end }}
  {{- end }}
    
  {{- include "elcicd-renderer.processMap" (list $ $.Values.elCicdDefaults $destElCicdDefs) }}
{{- end }}

{{- define "elcicd-renderer.deepCopyMap" }}
  {{- $srcMap := index . 0 }}
  {{- $destMap := index . 1 }}

  {{- if $srcMap }}
    {{- range $key, $value := $srcMap }}
      {{- if (kindIs "map" $value) }}
        {{- $newValue := dict }}
        {{- include "elcicd-renderer.deepCopyMap" (list $value $newValue) }}
        {{- $value = $newValue }}
      {{- end }}
      {{- $_ := set $destMap $key ($value | default "") }}
    {{- end }}
  {{- end }}
{{- end }}