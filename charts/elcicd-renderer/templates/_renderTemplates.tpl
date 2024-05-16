# SPDX-License-Identifier: LGPL-2.1-or-later

#########################################
##
## ======================================
## elcicd-renderer.render
## ======================================
##
## elCicdProfiles
##   List of active profiles for rendering, Usually entered only on the command line
##   when rendering.
##
## elCicdDefs
## elCicdDefs-<profile>
## elCicdDefs-<objName>
##   Variables are defined under these dictionaries, where keys are variable names.
##   Variables may reference other variables, may be any type of valid YAML data,
##   and order is not important.  elCicdDefs with named profiles or objNames will
##   only be used when the profile is active or a template using that objName is being rendered.
##
##   Variables are referenced in templates in the following manner:
##
##     $<variableName>
##
##   Use a backslash to escape:
##
##     \$<variableName> # NOTE: backslashes will be removed post-rendering
##
## elCicdNamespaces
##   List of namespaces beyond the chart namespace to be created.
##
## elCicdTemplates
##   List of el-CICD chart template to render.  Order is not important.  Basic form is as follows:
##
##   - templateName: <template name>
##     resName: <resource name to be rendered>
##     objNames: <list of resource names to be rendered>
##     namespaces: <optional list of namespace(s)to deploy resource to>
##     elCicdDefs: <list of variables only applicable to this template>
##     elCicdDefs-<profile>: <list of variables only applicable to this template when profile is active>
##     elCicdDefs-<objectName>-<profile>: <list of variables only applicable to a template with objName when profile is active>
##     <template values to set>
##
##   objName and objNames are mutually exclusive.  Namespaces is optional and only needed
##   if the resource is to be rendered outside the chart's namepsace.  Variables can be used
##   in lieu of static text when defining specific template elCicdDefs.
##
## Description: ENTRY POINT template el-CICD Charts.  General rendering process:
##
## 1. Intialization of data for chart (elcicd-renderer.initElCicdRenderer)
## 2. If necessary, creates extra namespace (elcicd-renderer.createNamespaces)
## 3. Merge the global variable defintions based on the profiles (elcicd-renderer.mergeElCicdDefs)
## 4. If templates include a list of names or namespaces, creates a copy for
##    each one in the overall template list to be rendered.  Also filters out any
##    templates not matching the profile(s) (elcicd-renderer.generateAllTemplates)
## 5. Processing the templates means overriding the global variables with template specific ones,
##    replacing variable references with values, and then rendering the templates.
## 6. If the calculated values file is to be rendered for debugging purposes or resuse in a pre-rendered
##    deployment strategy, do so.  The values are NOT commented out.
## 7. Add comments describing which templates were rendered and which were skipped due to profile filtering.
##
## See the named Helm templates for more information.
##
#########################################
{{- define "elcicd-renderer.render" }}
  {{- $ := . }}

  {{- $_ := set $.Values "EL_CICD_DEPLOYMENT_TIME" (now | date "Mon Jan 2 15:04:05 MST 2006") }}

  {{- $_ := set $.Values "EL_CICD_DEPLOYMENT_TIME_NUM" (now | date "2006_01_02_15_04_05") }}

  {{- include "elcicd-renderer.initElCicdRenderer" . }}

  {{- include "elcicd-renderer.createNamespaces" . }}

  {{- include "elcicd-renderer.mergeElCicdDefs" (list $ $.Values $.Values.elCicdDefs "" "") }}

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
# EXCLUDED BY PROFILES: {{ index $skippedTemplate 0 }} -> {{ index $skippedTemplate 1 }}
    {{- end }}
  {{- end }}
{{- end }}
