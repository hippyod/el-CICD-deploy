{{/*
ResourceQuota
*/}}
{{- define "elcicd-kubernetes.resourceQuota" }}
{{- $ := index . 0 }}
{{- $quotaValues := index . 1 }}
{{- $_ := set $quotaValues "kind" "ResourceQuota" }}
{{- $_ := set $quotaValues "apiVersion" "v1" }}
{{- include "elcicd-common.apiObjectHeader" . }}
spec:
  hard:
  {{- $quotaValues.hard | toYaml | nindent 4 }}
  {{- if $quotaValues.scopeSelector }}
  scopeSelector:
  {{- $quotaValues.scopeSelector | toYaml | nindent 4 }}
  {{- end }}
  {{- if $quotaValues.scopes }}
  scopes:
  {{- $quotaValues.scopes | toYaml | nindent 4 }}
  {{- end }}
{{- end }}

{{/*
LimitRange
*/}}
{{- define "elcicd-kubernetes.limitRange" }}
{{- $ := index . 0 }}
{{- $limitValues := index . 1 }}
{{- $_ := set $limitValues "kind" "LimitRange" }}
{{- $_ := set $limitValues "apiVersion" "v1" }}
{{- include "elcicd-common.apiObjectHeader" . }}
spec:
  limits: {{ $limitValues.limits | toYaml | nindent 2 }}
{{- end }}