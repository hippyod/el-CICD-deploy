{{- define "elCicdArgoCd.appProject" }}
  {{- $ := index . 0 }}
  {{- $appProjValues := index . 1 }}
  {{- $_ := set $appProjValues "kind" "AppProject" }}
  {{- $_ := set $appProjValues "apiVersion" "argoproj.io/v1alpha1" }}
  {{- include "elCicdCommon.apiObjectHeader" . }}
  spec:
    {{- $whiteList := list "clusterResourceBlacklist"
                           "clusterResourceWhitelist"
                           "description"
                           "destinations"
                           "parallelism"
                           "namespaceResourceBlacklist"
                           "namespaceResourceWhitelist"
                           "orphanedResources"
                           "permitOnlyProjectScopedClusters"
                           "roles"
                           "signatureKeys"
                           "sourceRepos"
                           "syncWindows" }}
    {{- include "elCicdCommon.outputToYaml" (list $ $appProjValues $whiteList) }}
{{- end }}

{{- define "elCicdArgoCd.applicationSet" }}
  {{- $ := index . 0 }}
  {{- $appSetValues := index . 1 }}
  {{- $_ := set $appSetValues "kind" "ApplicationSet" }}
  {{- $_ := set $appSetValues "apiVersion" "argoproj.io/v1alpha1" }}
  {{- include "elCicdCommon.apiObjectHeader" . }}
  spec:
    {{- $whiteList := list "generators"
                           "goTemplate"
                           "syncPolicy"
                           "template" }}
    {{- include "elCicdCommon.outputToYaml" (list $ $appSetValues $whiteList) }}
{{- end }}

{{- define "elCicdArgoCd.application" }}
  {{- $ := index . 0 }}
  {{- $appValues := index . 1 }}
  {{- $_ := set $appValues "kind" "Application" }}
  {{- $_ := set $appValues "apiVersion" "argoproj.io/v1alpha1" }}
  {{- include "elCicdCommon.apiObjectHeader" . }}
  spec:
    {{- $whiteList := list "destination"
                           "ignoreDifferences"
                           "info"
                           "project"
                           "revisionHistoryLimit"
                           "source"
                           "syncPolicy" }}
    {{- include "elCicdCommon.outputToYaml" (list $ $appValues $whiteList) }}
{{- end }}