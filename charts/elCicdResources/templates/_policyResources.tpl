{{/*
ResourceQuota
*/}}
{{- define "elCicdResources.quota" }}
  {{- include "elCicdResources.resourceQuota" . }}  
{{- end }}

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
  {{- range $key, $value := $quotaValues }}
    {{- if (hasPrefix "limits." $key) }}
      {{ $key }}: {{ $value }} 
    {{- end }}
  {{- end }}
  scopeSelector:
  {{- $quotaValues.scopeSelector | toYaml | nindent 4 }}
  scopes:
  {{- $quotaValues.scopes | toYaml | indent 2 }}
{{- end }}