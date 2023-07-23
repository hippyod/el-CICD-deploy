# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elCicdRenderer.mergeProfileDefs" }}
  {{- $ := index . 0 }}
  {{- $destElCicdDefs := index . 1 }}
  {{- $baseObjName := index . 2 }}
  {{- $objName := index . 3 }}
  
  {{- range $profile := $.Values.elCicdProfiles }}
    {{- $profileDefs := deepCopy (get $.Values (printf "elCicdDefs-%s" $profile)) }}
    {{- if $profileDefs }}
      {{- $destElCicdDefs = mergeOverwrite $destElCicdDefs $profileDefs }}
    {{- end }}
  {{- end }}

  {{- if ne $baseObjName $objName }}
    {{- $baseObjNameDefs := deepCopy (get $.Values (printf "elCicdDefs-%s" $baseObjName)) }}
    {{- if $baseObjNameDefs }}
      {{- $destElCicdDefs = mergeOverwrite $destElCicdDefs $baseObjNameDefs }}
    {{- end }}
  {{- end }}

  {{- if $objName }}
    {{- $objNameDefs := deepCopy (get $.Values (printf "elCicdDefs-%s" $objName)) }}
    {{- if $objNameDefs }}
      {{- $destElCicdDefs = mergeOverwrite $destElCicdDefs $objNameDefs }}
    {{- end }}
  {{- end }}
    
  {{- range $profile := $.Values.elCicdProfiles }}
    {{- if ne $baseObjName $objName }}
      {{- $baseObjNameDefs := deepCopy (get $.Values (printf "elCicdDefs-%s-%s" $baseObjName $profile)) }}
      {{- if $baseObjNameDefs }}
        {{- $destElCicdDefs = mergeOverwrite $destElCicdDefs $baseObjNameDefs }}
      {{- end }}
    {{- end }}

    {{- if $objName }}
      {{- $objNameDefs := deepCopy (get $.Values (printf "elCicdDefs-%s-%s" $objName $profile)) }}
      {{- if $objNameDefs }}
        {{- $destElCicdDefs = mergeOverwrite $destElCicdDefs $objNameDefs }}
      {{- end }}
    {{- end }}
  {{- end }}
    
  {{- include "elCicdRenderer.processMap" (list $ $.Values.elCicdDefaults $destElCicdDefs) }}
{{- end }}