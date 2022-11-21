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
    {{- if (eq $dep.Name "elCicdResources") }}
      {{- include "elCicdResources.initElCicdResources" $ }}
      {{- $_ := set $.Values.elCicdDefaults "templatesChart" ($.Values.elCicdDefaults.templatesChart | default "elCicdResources") }}
    {{- end }}
  {{- end }}
    
  {{- $_ := set $.Values "MAX_RECURSION" (int 5) }}
  {{- $_ := set $.Values "FILE_PREFIX" "${FILE|" }}
  {{- $_ := set $.Values "CONFIG_PREFIX" "${CONFIG|" }}
  {{- $_ := set $.Values "ELCICD_FILE_REF_REGEX" "[\\$][\\{](?:FILE\\||CONFIG\\|)([\\w]+?(?:[.-][\\w]+?)*)[\\}]" }}
  {{- $_ := set $.Values "ELCICD_PARAM_REGEX" "[\\$][\\{]([\\w]+?(?:[-][\\w]+?)*)[\\}]" }}
  {{- $_ := set $.Values.elCicdDefs "RELEASE_NAMESPACE" $.Release.Namespace }}
{{- end }}

{{- define "elCicdRenderer.filterTemplates" }}
  {{- $ := . }}
  {{- $_ := set $.Values "profiles" ($.Values.profiles | default list) }}
  
  {{- $renderList := list }}
  {{- $skippedList := list }}
  {{- range $template := $.Values.elCicdTemplates  }}
    {{- $_ := set $template "anyProfiles" ($template.anyProfiles | default list) }}
    {{- $_ := set $template "ignoreExactlyProfiles" ($template.ignoreExactlyProfiles | default list) }}
    {{- $_ := set $template "mustHaveProfiles" ($template.mustHaveProfiles | default list) }}
    {{- $_ := set $template "ignoreAnyProfiles" ($template.ignoreAnyProfiles | default list) }}
  
    {{- $anyProfile := not $template.anyProfiles }}
    {{- range $profile := $template.anyProfiles }}
      {{- $anyProfile = or $anyProfile (has $profile $.Values.profiles) }}
    {{- end }}
        
    {{- $ignoreExactlyProfiles := and $template.ignoreExactlyProfiles (eq (len $template.ignoreExactlyProfiles) (len $.Values.profiles)) }}
    {{- if and $ignoreExactlyProfiles $template.ignoreExactlyProfiles }}
      {{- range $profile := $template.ignoreExactlyProfiles }}
        {{- $ignoreExactlyProfiles = and $ignoreExactlyProfiles (has $profile $.Values.profiles) }}
      {{- end }}
    {{- end }}

    {{- $mustHaveProfiles := or (empty $template.mustHaveProfiles) (eq (len $template.mustHaveProfiles) (len $.Values.profiles)) }}
    {{- if and $mustHaveProfiles $template.mustHaveProfiles }}
      {{- range $profile := $template.mustHaveProfiles }}
        {{- $mustHaveProfiles = and $mustHaveProfiles (has $profile $.Values.profiles) }}
      {{- end }}
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

{{- define "elCicdRenderer.createNamespaces" }}
  {{- $ := . }}

  {{- if $.Values.createNamespaces }}
    {{- $tplNamespaceSet := dict }}
    {{- range $template := $.Values.allTemplates }}
      {{- if $template.namespace }}
        {{- $_ := set $tplNamespaceSet $template.namespace "foo" }}
      {{- end }}
    {{- end }}
  
    {{- range $tplNamespace := (keys $tplNamespaceSet) }}
      {{- if (not (lookup "v1" "Namespace" "" $tplNamespace)) }}
---
apiVersion: v1
kind: Namespace
metadata:
  name: {{ $tplNamespace }}
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
