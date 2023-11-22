{{/*
ClusterRole
*/}}
{{- define "elcicd-kubernetes.clusterRole" }}
{{- $ := index . 0 }}
{{- $roleValues := index . 1 }}
{{- $_ := set $roleValues "kind" "ClusterRole" }}
{{- include "elcicd-kubernetes.genericRoleDefinition" . }}
{{- end }}

{{/*
ClusterRole Binding
*/}}
{{- define "elcicd-kubernetes.clusterRoleBinding" }}
{{- $ := index . 0 }}
{{- $roleBindingValues := index . 1 }}
{{- $_ := set $roleBindingValues "kind" "ClusterRoleBinding" }}
{{- include "elcicd-kubernetes.genericRoleBindingDefinition" . }}
{{- end }}

{{/*
Role
*/}}
{{- define "elcicd-kubernetes.role" }}
{{- $ := index . 0 }}
{{- $roleValues := index . 1 }}
{{- $_ := set $roleValues "kind" "Role" }}
{{- include "elcicd-kubernetes.genericRoleDefinition" . }}
{{- end }}

{{/*
Role Binding
*/}}
{{- define "elcicd-kubernetes.roleBinding" }}
{{- $ := index . 0 }}
{{- $roleBindingValues := index . 1 }}
{{- $_ := set $roleBindingValues "kind" "RoleBinding" }}
{{- include "elcicd-kubernetes.genericRoleBindingDefinition" . }}
{{- end }}

{{/*
Service Account
*/}}
{{- define "elcicd-kubernetes.serviceAccount" }}
{{- $ := index . 0 }}
{{- $svcAcctValues := index . 1 }}
{{- $_ := set $svcAcctValues "kind" "ServiceAccount" }}
{{- $_ := set $svcAcctValues "apiVersion" "v1" }}
{{- include "elcicd-common.apiObjectHeader" . }}
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