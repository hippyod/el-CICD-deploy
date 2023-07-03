# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elCicdRenderer.mergeProfileDefs" }}
  {{- $ := index . 0 }}
  {{- $destElCicdDefs := index . 1 }}
  {{- $baseObjName := index . 2 }}
  
  {{- range $profile := $.Values.elCicdProfiles }}
    {{- $profileDefs := get $.Values (printf "elCicdDefs-%s" $profile) }}
    {{- include "elCicdRenderer.mergeMapInto" (list $ $profileDefs $destElCicdDefs) }}
    
    {{- if $baseObjName }}
      {{- $baseObjNameDefs := get $.Values (printf "elCicdDefs-%s" $baseObjName) }}
      {{- include "elCicdRenderer.mergeMapInto" (list $ $baseObjNameDefs $destElCicdDefs) }}
    
      {{- $baseObjNameDefs := get $.Values (printf "elCicdDefs-%s-%s" $baseObjName $profile) }}
      {{- include "elCicdRenderer.mergeMapInto" (list $ $baseObjNameDefs $destElCicdDefs) }}
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