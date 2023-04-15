{{/*
ClusterRole
*/}}
{{- define "elCicdKubernetes.clusterRole" }}
{{- $ := index . 0 }}
{{- $roleValues := index . 1 }}
{{- $_ := set $roleValues "kind" "ClusterRole" }}
{{- include "elCicdKubernetes.genericRoleDefinition" . }}
{{- end }}

{{/*
ClusterRole Binding
*/}}
{{- define "elCicdKubernetes.clusterRoleBinding" }}
{{- $ := index . 0 }}
{{- $roleBindingValues := index . 1 }}
{{- $_ := set $roleBindingValues "kind" "ClusterRoleBinding" }}
{{- include "elCicdKubernetes.genericRoleBindingDefinition" . }}
{{- end }}

{{/*
Role
*/}}
{{- define "elCicdKubernetes.role" }}
{{- $ := index . 0 }}
{{- $roleValues := index . 1 }}
{{- $_ := set $roleValues "kind" "Role" }}
{{- include "elCicdKubernetes.genericRoleDefinition" . }}
{{- end }}

{{/*
Role Binding
*/}}
{{- define "elCicdKubernetes.roleBinding" }}
{{- $ := index . 0 }}
{{- $roleBindingValues := index . 1 }}
{{- $_ := set $roleBindingValues "kind" "RoleBinding" }}
{{- include "elCicdKubernetes.genericRoleBindingDefinition" . }}
{{- end }}

{{/*
Service Account
*/}}
{{- define "elCicdKubernetes.serviceAccount" }}
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