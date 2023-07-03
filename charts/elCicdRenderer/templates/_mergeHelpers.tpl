# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elCicdRenderer.mergeProfileDefs" }}
  {{- $ := index . 0 }}
  {{- $profileDefs := index . 1 }}
  {{- $elCicdDefs := index . 2 }}

  {{- include "elCicdRenderer.mergeMapInto" (list $ $profileDefs.elCicdDefs $elCicdDefs) }}

  {{- range $profile := $.Values.elCicdProfiles }}
    {{- $profileDefs := get $profileDefs (printf "elCicdDefs-%s" $profile) }}
    {{- include "elCicdRenderer.mergeMapInto" (list $ $profileDefs $elCicdDefs) }}
  {{- end }}

  {{- $objName := $profileDefs.objName }}
  {{- $baseObjName := ($profileDefs.elCicdDefs).BASE_OBJ_NAME }}
  {{- range $workingObjName := (tuple $baseObjName $objName) }}
    {{- $objNameDefsKey := printf "elCicdDefs-%s" $workingObjName }}
    {{- $objNameElcicdDefs := tuple (deepCopy (get $.Values $objNameDefsKey | default dict)) (get $profileDefs $objNameDefsKey ) }}
    {{- range $objNameDefs := $objNameElcicdDefs }}
      {{- include "elCicdRenderer.mergeMapInto" (list $ $objNameDefs $elCicdDefs) }}
    {{- end }}

    {{- range $profile := $.Values.elCicdProfiles }}
      {{- $profileDefs := get $profileDefs (printf "elCicdDefs-%s-%s" $workingObjName $profile) }}
      {{- include "elCicdRenderer.mergeMapInto" (list $ $profileDefs $elCicdDefs) }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdRenderer.mergeMapInto" }}
  {{- $ := index . 0 }}
  {{- $srcMap := index . 1 }}
  {{- $destMap := index . 2 }}

  {{- if $srcMap }}
    {{- range $key, $value := $srcMap }}
      {{- if $value }}
        {{- $_ := set $destMap $key $value }}
      {{- else }}
        {{- $_ := set $destMap $key }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}