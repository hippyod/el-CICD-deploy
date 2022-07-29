
{{/*
Service Account
*/}}
{{- define "elCicdChart.serviceAccount" }}
{{- $ := index . 0 }}
{{- $svcAcctValues := index . 1 }}
---
{{- $_ := set $svcAcctValues "kind" "ServiceAccount" }}
{{- $_ := set $svcAcctValues "apiVersion" "v1" }}
{{- include "elCicdChart.apiObjectHeader" . }}
{{- if $svcAcctValues.automountServiceAccountToken }}
automountServiceAccountToken: {{ $svcAcctValues.automountServiceAccountToken  }}
{{- end }}
{{- if $svcAcctValues.imagePullSecrets }}
imagePullSecrets:
{{- range $imagePullSecret := $svcAcctValues.imagePullSecrets  }}
- name: {{ $imagePullSecret }}
{{- end }}
{{- end }}
{{- if $svcAcctValues.secrets }}
secrets:
{{- range $secret := $svcAcctValues.secrets  }}
- name: {{ $secret }}
{{- end }}
{{- end }}
{{- end }}
