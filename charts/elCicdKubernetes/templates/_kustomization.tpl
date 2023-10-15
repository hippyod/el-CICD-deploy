{{/*
Kustomization
*/}}
{{- define "elCicdKubernetes.kustomization" }}
  {{- $ := index . 0 }}
  {{- $kustValues := index . 1 }}
  {{- $_ := set $kustValues "kind" "Kustomization" }}
  {{- $_ := set $kustValues "apiVersion" "kustomize.config.k8s.io/v1beta1" }}
  {{- include "elCicdCommon.apiObjectHeader" . }}

  {{- range $field, $fieldValue := ($kustValues.fields | default dict) }}
{{ $field }}: {{ $fieldValue | toYaml | nindent 2 }}
  {{- end }}
{{- end }}
