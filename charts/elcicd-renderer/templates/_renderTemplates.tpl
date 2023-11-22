# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elcicd-renderer.render" }}
  {{- $ := . }}
  
  {{- $_ := set $.Values "EL_CICD_DEPLOYMENT_TIME" (now | date "Mon Jan 2 15:04:05 MST 2006") }}

  {{- include "elcicd-renderer.initElCicdRenderer" . }}

  {{- include "elcicd-renderer.createNamespaces" . }}

  {{- include "elcicd-renderer.mergeProfileDefs" (list $ $.Values $.Values.elCicdDefs "" "") }}

  {{- include "elcicd-renderer.generateAllTemplates" . }}

  {{- include "elcicd-renderer.processTemplates" (list $ $.Values.allTemplates) }}
  
  {{- if (or $.Values.valuesYamlToStdOut $.Values.global.valuesYamlToStdOut) }}
    {{ $.Values | toYaml }}
  {{- else }}
    {{- $skippedList := list }}
    {{- range $template := $.Values.allTemplates  }}
      {{- $templateName := $template.templateName }}
      {{- if not (contains "." $templateName) }}
        {{- if eq $templateName "copyResource" }}
          {{- $templateName = "elcicd-renderer.copyResource" }}
        {{- else }}
          {{- $templateName = printf "%s.%s" $.Values.elCicdDefaults.templatesChart $template.templateName }}
        {{- end }}
      {{- end }}
---
      {{- include $templateName (list $ $template) }}
# Rendered -> {{ $template.templateName }} {{ $template.objName }}
    {{- end }}

    {{- $resultMap := dict }}
    {{- range $yamlMapKey, $rawYamlValue := $.Values }}
      {{- if and (hasPrefix "elCicdRawYaml" $yamlMapKey) (kindIs "map" $rawYamlValue) }}
        {{- range $yamlKey, $rawYaml := $rawYamlValue }}
          {{- $_ := set $resultMap $.Values.PROCESS_STRING_VALUE ($rawYaml | toString) }}
          {{- include "elcicd-renderer.processString" (list $ $resultMap $.Values.elCicdDefs) }}
          {{- $rawYaml = get $resultMap $.Values.PROCESS_STRING_VALUE }}
---
  {{ $rawYaml }}
# Rendered From {{ $yamlMapKey }} -> {{ $yamlKey }}
        {{- end }}
      {{- end }}
    {{- end }}
---
# Profiles: {{ $.Values.elCicdProfiles }}
    {{- range $skippedTemplate := $.Values.skippedTemplates }}
      {{- include "elcicd-renderer.skippedTemplateLog" $skippedTemplate }}
    {{- end }}
  {{- end }}
{{- end }}
