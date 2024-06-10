# SPDX-License-Identifier: LGPL-2.1-or-later

{{/*
  ======================================
  elcicd-renderer.initElCicdRenderer
  ======================================

  Initializes the el-CICD Renderer.

  1. Ensures all lists and dictionaries are non-null.
    a. Helm global dictionary
    b. elCicdDefaults: contains all default values for rendering
       i. Default ojbName will be the release name unless otherwise defined.
      ii. Default chart for full templateNames; e.g. elcicd-kubernetes is the default, so
          a templateName `foo` will be searched as `elcicd-kubernetes.foo`, whereas `other-chart.foo`
          remain untouched.
    c. elCicdDefs: el-CICD Chart user-defined values files variable definitions
    d. elCicdTemplates: list of el-CICD Chart style Helm templates to render
       i. Must not be empty; exception will occur if empty
  2. Initilizes default key/value pairs (elcicd-renderer.gatherElCicdDefaults)
  3. Initializes el-CICD Kubernetes resources, if included as a library chart dependency. (elcicd-kubernetes.init)
  4. Defines internal el-CICD Chart values for parsing.
*/}}
{{- define "elcicd-renderer.initElCicdRenderer" }}
  {{- $ := . }}

  {{- $_ := set $.Values "global" ($.Values.global | default dict) }}

  {{- $_ := set $.Values "elCicdDefaults" ($.Values.elCicdDefaults | default dict) }}
  {{- $_ := set $.Values.elCicdDefaults "objName" ($.Values.elCicdDefaults.objName | default $.Release.Name) }}

  {{- $_ := set $.Values "elCicdDefs" ($.Values.elCicdDefs | default dict) }}
  {{- $_ := set $.Values "skippedTemplates" list }}

  {{- $_ := set $.Values.elCicdDefaults "templatesChart" ($.Values.elCicdDefaults.templatesChart | default "elcicd-kubernetes") }}

  {{- if or $.Values.elCicdProfiles $.Values.global.elCicdProfiles }}
    {{- $_ := set $.Values "elCicdProfiles" ($.Values.global.elCicdProfiles | default $.Values.elCicdProfiles | default list) }}
    {{- if not (kindIs "slice" $.Values.elCicdProfiles) }}
      {{- fail (printf "Profiles must be specified as an array: %s" $.Values.elCicdProfiles) }}
    {{- end }}
  {{- end }}

  {{- include "elcicd-renderer.gatherElCicdDefaults" $ }}

  {{- range $dep := $.Chart.Dependencies }}
    {{- if (eq $dep.Name "elcicd-kubernetes") }}
      {{- include "elcicd-kubernetes.init" $ }}
    {{- end }}
  {{- end }}

  {{- $_ := set $.Values "__EL_CICD_DEPTH" "__EL_CICD_DEPTH" }}
  {{- $_ := set $.Values "__EL_CICD_MAX_DEPTH" 15 }}
  {{- $_ := set $.Values "__EL_CICD_ORIG_VALUE_KEY" "__ORIG_VALUE" }}

  {{- $_ := set $.Values "__EL_CICD_FILE_PREFIX" "$<FILE|" }}
  {{- $_ := set $.Values "__EL_CICD_CONFIG_PREFIX" "$<CONFIG|" }}

  {{- $_ := set $.Values "__EL_CICD_ESCAPED_REGEX" "[\\\\][\\$][<]" }}
  {{- $_ := set $.Values "__EL_CICD_UNESCAPED_REGEX" "$<" }}
  {{- $_ := set $.Values "__EL_CICD_PARAM_REGEX" "(?:^|[^\\\\])\\$<([\\w]+?(?:[-][\\w]+?)*)>" }}
{{- end }}

{{/*
  ======================================
  elcicd-renderer.gatherElCicdDefaults
  ======================================

  Collects the defaults el-CICD Chart will use when rendering.  Merges active profile
  specific defaults in.
*/}}
{{- define "elcicd-renderer.gatherElCicdDefaults" }}
  {{- $ := . }}

  {{- $_ := set $.Values "elCicdDefaults" ($.Values.elCicdDefaults | default dict) }}

  {{- range $profile := $.Values.elCicdProfiles }}
    {{- $profileDefaultsMap := (get $.Values (printf "elCicdDefaults-%s" $profile)) }}
    {{- if $profileDefaultsMap }}
      {{- $_ set $.Values "elCicdProfiles"  (mergeOverwrite $.Values.elCicdDefaults) }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
  ======================================
  elcicd-renderer.gatherElCicdTemplates
  ======================================

  Ensures elCicdTemplates is note empty.  Appends templates from lists with prefixes of `elCicdTemplates-`
*/}}
{{- define "elcicd-renderer.gatherElCicdTemplates" }}
  {{- $ := . }}

  {{- if $.Values.elCicdTemplates }}
    {{- if (not (kindIs "slice" $.Values.elCicdTemplates)) }}
        {{- fail "elcicd-renderer elCicdTemplates: must be defined" }}
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


{{/*
  ======================================
  elcicd-renderer.filterTemplates
  ======================================

  el-CICD Chart templates may be condigured to only render or not render depending on the active profile(s).

  elCicdTemplates:
  - templateName: <template name>
    objName: <object name>
    mustHaveAnyProfile: <render if the active profile is list>
    mustNotHaveAnyProfile: <do NOT render if the active profile is list>
    mustHaveEveryProfile: <render only every profiles in list is active>
    mustHaveEveryProfile: <do NOT render only every profiles in list is active>

  Skipped templates will be listed when the Chart has completed rendering.
*/}}
{{- define "elcicd-renderer.filterTemplates" }}
  {{- $ := index . 0 }}
  {{- $templates := index . 1 }}

  {{- $_ := set $.Values "elCicdProfiles" ($.Values.elCicdProfiles | default list) }}

  {{- $renderList := list }}
  {{- $skippedList := list }}
  {{- $resultDict := dict }}
  {{- $resultKey := uuidv4 }}
  {{- range $template := $templates }}
    {{- $_ := set $template "mustHaveAnyProfile" ($template.mustHaveAnyProfile | default list) }}
    {{- include "elcicd-renderer.replaceVarRefsInSlice" (list $ $template.mustHaveAnyProfile $.Values.elCicdDefs list $resultDict $resultKey) }}
    {{- $_ := set $template "mustHaveAnyProfile" (get $resultDict $resultKey) }}
    {{- $_ := unset $resultDict $resultKey }}
    
    {{- $_ := set $template "mustNotHaveAnyProfile" ($template.mustNotHaveAnyProfile | default list) }}
    {{- include "elcicd-renderer.replaceVarRefsInSlice" (list $ $template.mustNotHaveAnyProfile $.Values.elCicdDefs list $resultDict $resultKey) }}
    {{- $_ := set $template "mustNotHaveAnyProfile" (get $resultDict $resultKey) }}
    {{- $_ := unset $resultDict $resultKey }}
    
    {{- $_ := set $template "mustHaveEveryProfile" ($template.mustHaveEveryProfile | default list) }}
    {{- include "elcicd-renderer.replaceVarRefsInSlice" (list $ $template.mustHaveEveryProfile $.Values.elCicdDefs list $resultDict $resultKey) }}
    {{- $_ := set $template "mustHaveEveryProfile" (get $resultDict $resultKey) }}
    {{- $_ := unset $resultDict $resultKey }}
    
    {{- $_ := set $template "mustNotHaveEveryProfile" ($template.mustNotHaveEveryProfile | default list) }}
    {{- include "elcicd-renderer.replaceVarRefsInSlice" (list $ $template.mustNotHaveEveryProfile $.Values.elCicdDefs list $resultDict $resultKey) }}
    {{- $_ := set $template "mustNotHaveEveryProfile" (get $resultDict $resultKey) }}
    {{- $_ := unset $resultDict $resultKey }}

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
      {{- $objName := (empty $template.objNames | ternary (print "objName: " $template.objName) (print "objNames: " $template.objNames)) }}
      {{- $skippedList = append $skippedList (list $template.templateName $objName) }}
    {{- end }}
  {{- end }}

  {{- $_ := set $.Values "renderingTemplates" $renderList }}
  {{- $_ := set $.Values "skippedTemplates" $skippedList }}
{{- end }}

