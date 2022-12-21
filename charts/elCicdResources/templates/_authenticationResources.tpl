{{/*
ClusterRole
*/}}
{{- define "elCicdResources.clusterRole" }}
{{- $_ := set $roleValues "kind" ClusterRole }}
{{- include "elCicdResources.genericRoleDefinition" . }}
{{- end }}

{{/*
Role
*/}}
{{- define "elCicdResources.role" }}
{{- $_ := set $roleValues "kind" Role }}
{{- include "elCicdResources.genericRoleDefinition" $newList }}
{{- end }}

{{/*
ClusterRole Binding
*/}}
{{- define "elCicdResources.clusterRoleBinding" }}
{{- $ := index . 0 }}
{{- $roleBindingValues := index . 1 }}
{{- $_ := set $roleBindingValues "kind" "ClusterRoleBinding" }}
{{- include "elCicdResources.genericRoleBindingDefinition" . }}
{{- end }}

{{/*
Role Binding
*/}}
{{- define "elCicdResources.roleBinding" }}
{{- $ := index . 0 }}
{{- $roleBindingValues := index . 1 }}
{{- $_ := set $roleBindingValues "kind" "RoleBinding" }}
{{- include "elCicdResources.genericRoleBindingDefinition" . }}
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