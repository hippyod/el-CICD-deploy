# SPDX-License-Identifier: LGPL-2.1-or-later

{{- define "elCicdRenderer.initElCicdRenderer" }}
  {{- $ := . }}
  
  {{- range $dep := $.Chart.Dependencies }}
    {{- if (eq $dep.Name "elCicdResources") }}
      {{- include "elCicdResources.initElCicdResources" $ }}
    {{- end }}
  {{- end }}
    
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
  {{- $_ := set $.Values "skippedTemplates" list }}
  
  {{- $_ := set $.Values "defaultRenderChart" ($.Values.defaultRenderChart | default "elCicdResources") }}
  
  {{- $_ := set $.Values "MAX_RECURSION" (int 5) }}
  {{- $_ := set $.Values "FILE_PREFIX" "${FILE|" }}
  {{- $_ := set $.Values "CONFIG_FILE_PREFIX" "${CONFIG|" }}
  {{- $_ := set $.Values "ELCICD_FILE_REF_REGEX" "[\\$][\\{](?:FILE\\||CONFIG\\|)([\\w]+?(?:[.-][\\w]+?)*)[\\}]" }}
  {{- $_ := set $.Values "ELCICD_PARAM_REGEX" "[\\$][\\{]([\\w]+?(?:[-][\\w]+?)*)[\\}]" }}
  {{- $_ := set $.Values.elCicdDefs "RELEASE_NAMESPACE" $.Release.Namespace }}
{{- end }}

{{- define "elCicdRenderer.filterTemplates" }}
  {{- $ := . }}
  
  {{- $renderList := list }}
  {{- $skippedList := list }}
  {{- range $template := $.Values.elCicdTemplates  }}
    {{- $anyProfile := not $template.anyProfiles }}
    {{- range $profile := $template.anyProfiles }}
      {{- $anyProfile = or $anyProfile (has $profile $.Values.profiles) }}
    {{- end }}
    
    {{- $ignoreExactlyProfiles := $template.ignoreExactlyProfiles }}
    {{- range $profile := $template.ignoreExactlyProfilesProfiles }}
      {{- $ignoreExactlyProfiles = and $ignoreExactlyProfiles (has $profile $.Values.profiles) }}
    {{- end }}

    {{- $mustHaveProfiles := true }}
    {{- range $profile := $template.mustHaveProfiles }}
      {{- $mustHaveRender = and $mustHaveRender (has $profile $.Values.profiles) }}
    {{- end }}
    
    {{- $ignoreAnyProfiles := false }}
    {{- range $profile := $template.ignoreAnyProfiles }}
      {{- $ignoreAnyProfiles = or $ignoreAnyProfiles (has $profile $.Values.profiles) }}
    {{- end }}
    
    {{- if and $anyProfile $mustHaveProfiles (not $ignoreExactlyProfiles) (not $ignoreAnyProfiles) }}
      {{- $renderList = append $renderList $template }}
    {{- else }}
      {{- $skippedList = append $skippedList (list $template.templateName ($template.appNames | default $template.appName)) }}
    {{- end }}
  {{- end }}
  
  {{- $_ := set $.Values "renderingTemplates" $renderList }}
  {{- $_ := set $.Values "skippedTemplates" $skippedList }}
{{- end }}

{{- define "elCicdRenderer.addNamespaces" }}
  {{- $ := . }}

  {{- $namespaceSet := dict }}
  {{- if $.Values.createNamespaces }}
    {{- range $template := $.Values.allTemplates }}
      {{- if $template.namespace }}
        {{- if not (hasKey $namespaceSet $template.namespace) }}
          {{- $_ := set $namespaceSet $template.namespace "foo" }}
          {{- $namespace := (lookup "v1" "namespace" "" $template.namespace) }}
          {{- if (not $namespace) }}
---
apiVersion: v1
kind: Namespace
metadata:
  name: {{ $template.namespace }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
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
