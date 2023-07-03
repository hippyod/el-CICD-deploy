# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elCicdRenderer.mergeProfileDefs" }}
  {{- $ := index . 0 }}
  {{- $destElCicdDefs := index . 1 }}
  {{- $baseObjName := index . 2 }}
  {{- $objName := index . 3 }}
  
  {{- range $profile := $.Values.elCicdProfiles }}
    {{- $profileDefs := get $.Values (printf "elCicdDefs-%s" $profile) }}
    {{- include "elCicdRenderer.mergeMapInto" (list $ $profileDefs $destElCicdDefs) }}
  {{- end }}

  {{- if ne $baseObjName $objName }}
    {{- $baseObjNameDefs := get $.Values (printf "elCicdDefs-%s" $baseObjName) }}
    {{- include "elCicdRenderer.mergeMapInto" (list $ $baseObjNameDefs $destElCicdDefs) }}
  {{- end }}

  {{- if $objName }}
    {{- $objNameDefs := get $.Values (printf "elCicdDefs-%s" $objName) }}
    {{- include "elCicdRenderer.mergeMapInto" (list $ $objNameDefs $destElCicdDefs) }}
  {{- end }}
    
  {{- range $profile := $.Values.elCicdProfiles }}
    {{- if ne $baseObjName $objName }}
      {{- $baseObjNameDefs := get $.Values (printf "elCicdDefs-%s-%s" $baseObjName $profile) }}
      {{- include "elCicdRenderer.mergeMapInto" (list $ $baseObjNameDefs $destElCicdDefs) }}
    {{- end }}

    {{- if $objName }}
      {{- $objNameDefs := get $.Values (printf "elCicdDefs-%s-%s" $objName $profile) }}
      {{- include "elCicdRenderer.mergeMapInto" (list $ $objNameDefs $destElCicdDefs) }}
    {{- end }}
  {{- end }}
    
  {{- include "elCicdRenderer.processMap" (list $ $.Values.elCicdDefaults $destElCicdDefs) }}
{{- end }}

{{- define "elCicdRenderer.mergeMapInto" }}
  {{- $ := index . 0 }}
  {{- $srcMap := index . 1 }}
  {{- $destMap := index . 2 }}

  {{- if $srcMap }}
    {{- range $key, $value := $srcMap }}
      {{- $_ := set $destMap $key ($value | default "") }}
    {{- end }}
  {{- end }}
{{- end }}