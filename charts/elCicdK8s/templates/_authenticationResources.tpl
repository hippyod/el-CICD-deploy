{{/*
ClusterRole
*/}}
{{- define "elCicdK8s.clusterRole" }}
{{- $ := index . 0 }}
{{- $roleValues := index . 1 }}
{{- $_ := set $roleValues "kind" "ClusterRole" }}
{{- include "elCicdK8s.genericRoleDefinition" . }}
{{- end }}

{{/*
ClusterRole Binding
*/}}
{{- define "elCicdK8s.clusterRoleBinding" }}
{{- $ := index . 0 }}
{{- $roleBindingValues := index . 1 }}
{{- $_ := set $roleBindingValues "kind" "ClusterRoleBinding" }}
{{- include "elCicdK8s.genericRoleBindingDefinition" . }}
{{- end }}

{{/*
Role
*/}}
{{- define "elCicdK8s.role" }}
{{- $ := index . 0 }}
{{- $roleValues := index . 1 }}
{{- $_ := set $roleValues "kind" "Role" }}
{{- include "elCicdK8s.genericRoleDefinition" . }}
{{- end }}

{{/*
Role Binding
*/}}
{{- define "elCicdK8s.roleBinding" }}
{{- $ := index . 0 }}
{{- $roleBindingValues := index . 1 }}
{{- $_ := set $roleBindingValues "kind" "RoleBinding" }}
{{- include "elCicdK8s.genericRoleBindingDefinition" . }}
{{- end }}

{{/*
Service Account
*/}}
{{- define "elCicdK8s.serviceAccount" }}
{{- $ := index . 0 }}
{{- $svcAcctValues := index . 1 }}
{{- $_ := set $svcAcctValues "kind" "ServiceAccount" }}
{{- $_ := set $svcAcctValues "apiVersion" "v1" }}
{{- include "elCicdCommon.apiObjectHeader" . }}
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