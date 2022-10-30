
{{/*
Role Binding
*/}}
{{- define "elCicdResources.roleBinding" }}
{{- $ := index . 0 }}
{{- $roleBindingValues := index . 1 }}
{{- $_ := set $roleBindingValues "kind" "RoleBinding" }}
{{- $_ := set $roleBindingValues "apiVersion" "rbac.authorization.k8s.io/v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
roleRef:
  {{- $roleBindingValues.roleRef | toYaml | nindent 2 }}
subjects:
{{ $roleBindingValues.subjects | toYaml }}
{{- end }}

{{/*
Service Account
*/}}
{{- define "elCicdResources.serviceAccount" }}
{{- $ := index . 0 }}
{{- $svcAcctValues := index . 1 }}
{{- $_ := set $svcAcctValues "kind" "ServiceAccount" }}
{{- $_ := set $svcAcctValues "apiVersion" "v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
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
