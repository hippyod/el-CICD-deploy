{{/*
Namespace
*/}}
{{- define "elcicd-kubernetes.namespace" }}
{{- $ := index . 0 }}
{{- $nsValues := index . 1 }}
{{- $_ := set $nsValues "kind" "Namespace" }}
{{- $_ := set $nsValues "apiVersion" "v1" }}
{{- include "elcicd-common.apiObjectHeader" . }}
{{- end }}