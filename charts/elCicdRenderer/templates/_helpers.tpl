# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elCicdRenderer.initElCicdRenderer" }}
  {{- $ := . }}

  {{- if $.Values.profiles }}
    {{- if not (kindIs "slice" $.Values.profiles) }}
      {{- fail (printf "Profiles must be specified as an array: %s" $.Values.profiles) }}
    {{- end }}
  {{- end }}

  {{- $_ := required "Missing elCicdTemplates: list" $.Values.elCicdTemplates }}
  {{- if (not (kindIs "slice" $.Values.elCicdTemplates)) }}
      {{- fail "elCicdRenderer elCicdTemplates: must be defined" }}
  {{- end }}

  {{- $_ := set $.Values "elCicdDefs" ($.Values.elCicdDefs | default dict) }}
  {{- $_ := set $.Values "elCicdDefaults" ($.Values.elCicdDefaults | default dict) }}
  {{- $_ := set $.Values "skippedTemplates" list }}

  {{- range $dep := $.Chart.Dependencies }}
    {{- if (eq $dep.Name "elCicdK8s") }}
      {{- include "elCicdK8s.initElCicdResources" $ }}
      {{- $_ := set $.Values.elCicdDefaults "templatesChart" ($.Values.elCicdDefaults.templatesChart | default "elCicdK8s") }}
    {{- end }}
  {{- end }}

  {{- $_ := set $.Values "MAX_RECURSION" (int 5) }}
  {{- $_ := set $.Values "FILE_PREFIX" "${FILE|" }}
  {{- $_ := set $.Values "CONFIG_PREFIX" "${CONFIG|" }}
  {{- $_ := set $.Values "ELCICD_PARAM_REGEX" "(?:^|[^\\\\])[\\$][\\{]([\\w]+?(?:[-][\\w]+?)*)[\\}]" }}
  {{- $_ := set $.Values.elCicdDefs "RELEASE_NAMESPACE" $.Release.Namespace }}
{{- end }}

{{- define "elCicdRenderer.filterTemplates" }}
  {{- $ := . }}
  {{- $_ := set $.Values "profiles" ($.Values.profiles | default list) }}

  {{- $renderList := list }}
  {{- $skippedList := list }}
  {{- range $template := $.Values.elCicdTemplates  }}
    {{- $_ := set $template "mustHaveAnyProfile" ($template.mustHaveAnyProfile | default list) }}
    {{- $_ := set $template "mustNotHaveEveryProfile" ($template.mustNotHaveEveryProfile | default list) }}
    {{- $_ := set $template "mustHaveEveryProfile" ($template.mustHaveEveryProfile | default list) }}
    {{- $_ := set $template "mustNotHaveAnyProfile" ($template.mustNotHaveAnyProfile | default list) }}

    {{- $hasMatchingProfile := not $template.mustHaveAnyProfile }}
    {{- range $profile := $template.mustHaveAnyProfile }}
      {{- $hasMatchingProfile = or $hasMatchingProfile (has $profile $.Values.profiles) }}
    {{- end }}

    {{- $hasNoProhibitedProfiles := not $template.mustNotHaveAnyProfile }}
    {{- range $profile := $template.mustNotHaveAnyProfile }}
      {{- $hasNoProhibitedProfiles = or $hasNoProhibitedProfiles (has $profile $.Values.profiles) }}
    {{- end }}
    {{- $hasNoProhibitedProfiles := not $hasNoProhibitedProfiles }}

    {{- $hasAllRequiredProfile := true }}
    {{- range $profile := $template.mustHaveEveryProfile }}
      {{- $hasAllRequiredProfile = and $hasAllRequiredProfile (has $profile $.Values.profiles) }}
    {{- end }}
    
    {{- $doesNotHaveAllProhibitedProfiles := true }}
    {{- range $profile := $template.mustNotHaveEveryProfile }}
      {{- $doesNotHaveAllProhibitedProfiles = and $doesNotHaveAllProhibitedProfiles (has $profile $.Values.profiles) }}
    {{- end }}
    {{- $doesNotHaveAllProhibitedProfiles := not $doesNotHaveAllProhibitedProfiles }}

    {{- if and $hasMatchingProfile $hasNoProhibitedProfiles $hasAllRequiredProfile $doesNotHaveAllProhibitedProfiles  }}
      {{- $renderList = append $renderList $template }}
    {{- else }}
      {{- $skippedList = append $skippedList (list $template.templateName ($template.appNames | default $template.appName)) }}
    {{- end }}
  {{- end }}

  {{- $_ := set $.Values "renderingTemplates" $renderList }}
  {{- $_ := set $.Values "skippedTemplates" $skippedList }}
{{- end }}

{{- define "elCicdRenderer.createNamespaces" }}
  {{- $ := . }}

  {{- range $elCicdNamespace := $.Values.elCicdNamespaces }}
---
apiVersion: v1
kind: Namespace
metadata:
  name: {{ $elCicdNamespace }}
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
