{{- define "elcicd-argoCd.appProject" }}
  {{- $ := index . 0 }}
  {{- $appProjValues := index . 1 }}
  {{- $_ := set $appProjValues "kind" "AppProject" }}
  {{- $_ := set $appProjValues "apiVersion" "argoproj.io/v1alpha1" }}
  {{- include "elcicd-common.apiObjectHeader" . }}
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
    {{- include "elcicd-common.outputToYaml" (list $ $appProjValues $whiteList) }}
{{- end }}

{{- define "elcicd-argoCd.applicationSet" }}
  {{- $ := index . 0 }}
  {{- $appSetValues := index . 1 }}
  {{- $_ := set $appSetValues "kind" "ApplicationSet" }}
  {{- $_ := set $appSetValues "apiVersion" "argoproj.io/v1alpha1" }}
  {{- include "elcicd-common.apiObjectHeader" . }}
  spec:
    {{- $whiteList := list "generators"
                           "goTemplate"
                           "syncPolicy"
                           "template" }}
    {{- include "elcicd-common.outputToYaml" (list $ $appSetValues $whiteList) }}
{{- end }}

{{- define "elcicd-argoCd.application" }}
  {{- $ := index . 0 }}
  {{- $appValues := index . 1 }}
  {{- $_ := set $appValues "kind" "Application" }}
  {{- $_ := set $appValues "apiVersion" "argoproj.io/v1alpha1" }}
  {{- include "elcicd-common.apiObjectHeader" . }}
  spec:
    {{- $whiteList := list "destination"
                           "ignoreDifferences"
                           "info"
                           "project"
                           "revisionHistoryLimit"
                           "source"
                           "syncPolicy" }}
    {{- include "elcicd-common.outputToYaml" (list $ $appValues $whiteList) }}
{{- end }}