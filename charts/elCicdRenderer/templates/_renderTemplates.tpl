# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elCicdRenderer.render" }}
  {{- $ := . }}
  
  {{- $_ := set $.Values "EL_CICD_DEPLOYMENT_TIME" (now | date "Mon Jan 2 15:04:05 MST 2006") }}

  {{- include "elCicdRenderer.initElCicdRenderer" . }}

  {{- include "elCicdRenderer.createNamespaces" . }}

  {{- include "elCicdRenderer.mergeProfileDefs" (list $ $.Values $.Values.elCicdDefs) }}

  {{- include "elCicdRenderer.processMap" (list $ $.Values.elCicdDefaults $.Values.elCicdDefs) }}

  {{- include "elCicdRenderer.generateAllTemplates" . }}

  {{- include "elCicdRenderer.processTemplates" (list $ $.Values.allTemplates $.Values.elCicdDefs) }}

  {{- $skippedList := list }}
  {{- range $template := $.Values.allTemplates  }}
    {{- $templateName := $template.templateName }}
    {{- if not (contains "." $templateName) }}
      {{- $templateName = printf "%s.%s" $.Values.elCicdDefaults.templatesChart $template.templateName }}
    {{- end }}
---
    {{- include $templateName (list $ $template) }}
# Rendered -> {{ $template.templateName }} {{ $template.appName }}
  {{- end }}

  {{- range $yamlMapKey, $rawYamlValue := $.Values }}
    {{- if and (hasPrefix "elCicdRawYaml" $yamlMapKey) (kindIs "map" $rawYamlValue) }}
      {{- range $yamlKey, $rawYaml := $rawYamlValue }}
---
{{ $rawYaml }}
# Rendered From {{ $yamlMapKey }} -> {{ $yamlKey }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if $.Values.renderValuesForKust }}
---
# __VALUES_START__
{{ $.Values | toYaml }}
# __VALUES_END__
  {{- end }}
---
# Profiles: {{ $.Values.profiles }}
  {{- range $skippedTemplate := $.Values.skippedTemplates }}
    {{- include "elCicdRenderer.skippedTemplateLog" $skippedTemplate }}
  {{- end }}
{{- end }}
