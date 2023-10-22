# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elCicdRenderer.initElCicdRenderer" }}
  {{- $ := . }}
  
  {{- $_ := set $.Values "global" ($.Values.global | default dict) }}

  {{- $_ := set $.Values "elCicdDefaults" ($.Values.elCicdDefaults | default dict) }}
  {{- $_ := set $.Values.elCicdDefaults "objName" ($.Values.elCicdDefaults.objName | default .Chart.Name) }}
  
  {{- $_ := set $.Values "elCicdDefs" ($.Values.elCicdDefs | default dict) }}
  {{- $_ := set $.Values "skippedTemplates" list }}
  
  {{- if or $.Values.elCicdProfiles $.Values.global.elCicdProfiles }}
    {{- $_ := set $.Values "elCicdProfiles" ($.Values.global.elCicdProfiles | default $.Values.elCicdProfiles | default list) }}
    {{- if not (kindIs "slice" $.Values.elCicdProfiles) }}
      {{- fail (printf "Profiles must be specified as an array: %s" $.Values.elCicdProfiles) }}
    {{- end }}
  {{- end }}

  {{- include "elCicdRenderer.gatherElCicdTemplates" $ }}

  {{- include "elCicdRenderer.gatherElCicdDefaults" $ }}

  {{- range $dep := $.Chart.Dependencies }}
    {{- if (eq $dep.Name "elCicdKubernetes") }}
      {{- include "elCicdKubernetes.init" $ }}
      {{- $_ := set $.Values.elCicdDefaults "templatesChart" ($.Values.elCicdDefaults.templatesChart | default "elCicdKubernetes") }}
    {{- end }}
  {{- end }}
  
  {{- $_ := set $.Values "PROCESS_STRING_VALUE" "PROCESS_STRING_VALUE" }}

  {{- $_ := set $.Values "MAX_RECURSION" (int 15) }}
  {{- $_ := set $.Values "FILE_PREFIX" "${FILE|" }}
  {{- $_ := set $.Values "CONFIG_PREFIX" "${CONFIG|" }}
  {{- $_ := set $.Values "ELCICD_ESCAPED_REGEX" "[\\\\][\\$][\\{]" }}
  {{- $_ := set $.Values "ELCICD_UNESCAPED_REGEX" "${" }}
  {{- $_ := set $.Values "ELCICD_PARAM_REGEX" "(?:^|[^\\\\])[\\$][\\{]([\\w]+?(?:[-][\\w]+?)*)[\\}]" }}
  {{- $_ := set $.Values.elCicdDefs "HELM_RELEASE_NAME" $.Release.Name }}
  {{- $_ := set $.Values.elCicdDefs "HELM_RELEASE_NAMESPACE" $.Release.Namespace }}
{{- end }}

{{- define "elCicdRenderer.gatherElCicdDefaults" }}
  {{- $ := . }}

  {{- $_ := set $.Values "elCicdDefaults" ($.Values.elCicdDefaults | default dict) }}

  {{- range $profile := $.Values.elCicdProfiles }}
    {{- $profileDefaultsMap := (get $.Values (printf "elCicdDefaults-%s" $profile)) }}
    {{- if $profileDefaultsMap }}
      {{- $_ set $.Values "elCicdProfiles"  (mergeOverwrite $.Values.elCicdDefaults) }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdRenderer.gatherElCicdTemplates" }}
  {{- $ := . }}

  {{- if $.Values.elCicdTemplates }}
    {{- if (not (kindIs "slice" $.Values.elCicdTemplates)) }}
        {{- fail "elCicdRenderer elCicdTemplates: must be defined" }}
    {{- end }}
  {{- end }}

  {{- range $key, $value := $.Values }}
    {{- if hasPrefix "elCicdTemplates-" $key }}
      {{- if $.Values.elCicdTemplates }}
        {{- $_ := set $.Values "elCicdTemplates" (concat $.Values.elCicdTemplates $value) }}
      {{- else }}
        {{- $_ := set $.Values "elCicdTemplates" $value }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- $_ := required "Missing elCicdTemplates: list" $.Values.elCicdTemplates }}
{{- end }}

{{- define "elCicdRenderer.filterTemplates" }}
  {{- $ := . }}
  {{- $_ := set $.Values "elCicdProfiles" ($.Values.elCicdProfiles | default list) }}

  {{- $renderList := list }}
  {{- $skippedList := list }}
  {{- range $template := $.Values.elCicdTemplates  }}
    {{- $_ := set $template "mustHaveAnyProfile" ($template.mustHaveAnyProfile | default list) }}
    {{- $_ := set $template "mustNotHaveAnyProfile" ($template.mustNotHaveAnyProfile | default list) }}
    {{- $_ := set $template "mustHaveEveryProfile" ($template.mustHaveEveryProfile | default list) }}
    {{- $_ := set $template "mustNotHaveEveryProfile" ($template.mustNotHaveEveryProfile | default list) }}

    {{- $hasMatchingProfile := not $template.mustHaveAnyProfile }}
    {{- range $profile := $template.mustHaveAnyProfile }}
      {{- $hasMatchingProfile = or $hasMatchingProfile (has $profile $.Values.elCicdProfiles) }}
    {{- end }}

    {{- $hasNoProhibitedProfiles := not $template.mustNotHaveAnyProfile }}
    {{- range $profile := $template.mustNotHaveAnyProfile }}
      {{- $hasNoProhibitedProfiles = or $hasNoProhibitedProfiles (has $profile $.Values.elCicdProfiles) }}
    {{- end }}
    {{- $hasNoProhibitedProfiles = or (not $template.mustNotHaveAnyProfile) (not $hasNoProhibitedProfiles) }}

    {{- $hasAllRequiredProfiles := true }}
    {{- range $profile := $template.mustHaveEveryProfile }}
      {{- $hasAllRequiredProfiles = and $hasAllRequiredProfiles (has $profile $.Values.elCicdProfiles) }}
    {{- end }}

    {{- $doesNotHaveAllProhibitedProfiles := true }}
    {{- range $profile := $template.mustNotHaveEveryProfile }}
      {{- $doesNotHaveAllProhibitedProfiles = and $doesNotHaveAllProhibitedProfiles (has $profile $.Values.elCicdProfiles) }}
    {{- end }}
    {{- $doesNotHaveAllProhibitedProfiles = or (not $template.doesNotHaveAllProhibitedProfiles) (not $doesNotHaveAllProhibitedProfiles) }}

    {{- if and $hasMatchingProfile $hasNoProhibitedProfiles $hasAllRequiredProfiles $doesNotHaveAllProhibitedProfiles  }}
      {{- $renderList = append $renderList $template }}
    {{- else }}
      {{- $skippedList = append $skippedList (list $template.templateName ($template.objNames | default $template.objName)) }}
    {{- end }}
  {{- end }}

  {{- $_ := set $.Values "renderingTemplates" $renderList }}
  {{- $_ := set $.Values "skippedTemplates" $skippedList }}
{{- end }}

{{- define "elCicdRenderer.createNamespaces" }}
  {{- $ := . }}
  {{- $nsValues := dict }}
  {{- $_ := set $nsValues "kind" "Namespace" }}
  {{- $_ := set $nsValues "apiVersion" "v1" }}

  {{- range $elCicdNamespace := $.Values.elCicdNamespaces }}
---
    {{- $_ := set $nsValues "objName" $elCicdNamespace }}
    {{- include "elCicdCommon.apiObjectHeader" (list $ $nsValues) }}
  {{- end }}
{{- end }}

{{- define "elCicdRenderer.circularReferenceCheck" }}
  {{- $value := index . 0 }}
  {{- $key := index . 1 }}
  {{- $elCicdRef := index . 2 }}
  {{- $elCicdDef := index . 3 }}
  {{- $processDefList := index . 4}}

  {{- if has $elCicdDef $processDefList }}
    {{- fail (printf "Circular elCicdDefs reference: '%s' in '%s: %s'" $elCicdRef $key $value) }}
  {{- end }}
{{- end }}

{{- define "elCicdRenderer.skippedTemplateLog" }}
# EXCLUDED BY PROFILES: {{ index . 0 }} -> {{ index . 1 }}
{{- end }}
