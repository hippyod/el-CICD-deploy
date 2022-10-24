# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elCicdRenderer.mergeProfileDefs" }}
  {{- $ := index . 0 }}
  {{- $profileDefs := index . 1 }}
  {{- $elCicdDefs := index . 2 }}

  {{- include "elCicdRenderer.mergeMapInto" (list $ $profileDefs.elCicdDefs $elCicdDefs) }}

  {{- range $profile := $.Values.profiles }}
    {{- $profileDefs := get $profileDefs (printf "elCicdDefs-%s" $profile) }}
    {{- include "elCicdRenderer.mergeMapInto" (list $ $profileDefs $elCicdDefs) }}
  {{- end }}

  {{- $appName := $profileDefs.appName }}
  {{- $baseAppName := ($profileDefs.elCicdDefs).BASE_APP_NAME }}
  {{- range $workingAppName := (tuple $baseAppName $appName) }}
    {{- $appNameDefsKey := printf "elCicdDefs-%s" $workingAppName }}
    {{- $appNameElcicdDefs := tuple (deepCopy (get $.Values $appNameDefsKey)) (get $profileDefs $appNameDefsKey ) }}
    {{- range $appNameDefs := $appNameElcicdDefs }}
      {{- include "elCicdRenderer.mergeMapInto" (list $ $appNameDefs $elCicdDefs) }}
    {{- end }}

    {{- range $profile := $.Values.profiles }}
      {{- $profileDefs := get $profileDefs (printf "elCicdDefs-%s-%s" $workingAppName $profile) }}
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
      {{- $_ := set $destMap $key $value }}
    {{- end }}
  {{- end }}
{{- end }}