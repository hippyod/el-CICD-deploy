{{/*
ResourceQuota
*/}}
{{- define "elCicdResources.resourceQuota" }}
{{- $ := index . 0 }}
{{- $quotaValues := index . 1 }}
{{- $_ := set $quotaValues "kind" "ResourceQuota" }}
{{- $_ := set $quotaValues "apiVersion" "v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
spec:
  hard:
  {{- $quotaValues.hard | toYaml | nindent 4 }}
  {{- if $quotaValues.scopeSelector }}
  scopeSelector:
  {{- $quotaValues.scopeSelector | toYaml | nindent 4 }}
  {{- end }}
  {{- if $quotaValues.scopes }}
  scopes:
  {{- $quotaValues.scopes | toYaml | nindent 2 }}
  {{- end }}
{{- end }}

{{/*
LimitRange
*/}}
{{- define "elCicdResources.limitRange" }}
{{- $ := index . 0 }}
{{- $limitValues := index . 1 }}
{{- $_ := set $limitValues "kind" "LimitRange" }}
{{- $_ := set $limitValues "apiVersion" "v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
spec:
  limits:
    {{- if $limitValues.default }}
    default: {{ $limitValues.default | toYaml | nindent 2 }}
    {{- end }}
    {{- if $limitValues.defaultRequest }}
    defaultRequest: {{ $limitValues.defaultRequest | toYaml | nindent 2 }}
    {{- end }}
    {{- if $limitValues.max }}
    max: {{ $limitValues.max | toYaml | nindent 2 }}
    {{- end }}
    {{- if $limitValues.maxLimitRequestRatio }}
    maxLimitRequestRatio: {{ $limitValues.maxLimitRequestRatio | toYaml | nindent 2 }}
    {{- end }}
    {{- if $limitValues.min }}
    min: {{ $limitValues.min | toYaml | nindent 2 }}
    {{- end }}
    {{- if $limitValues.type }}
    type: {{ $limitValues.type }}
    {{- end }}    
{{- end }}