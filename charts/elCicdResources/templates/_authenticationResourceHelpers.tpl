{{/*
genericRoleDefinition: all ClusterRoles and Roles have this structure
*/}}
{{- define "elCicdResources.genericRoleDefinition" }}
{{- $ := index . 0 }}
{{- $roleValues := index . 1 }}
{{- $_ := set $roleValues "apiVersion" "rbac.authorization.k8s.io/v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
rules:
{{- range $rule := $roleValues.rules }}
  {{- if $rule.apiGroups }}
  apiGroups: {{- $rule.apiGroups | toYaml | nindent 2 }}
  {{- end }}
  {{- if $rule.nonResourceURLs }}
  nonResourceURLs: {{- $rule.roleRef | toYaml | nindent 2 }}
  {{- end }}
  {{- if $rule.resourceNames }}
  resourceNames: {{- $rule.roleRef | toYaml | nindent 2 }}
  {{- end }}
  {{- if $rule.resources }}
  resources: {{- $rule.resources | toYaml | nindent 2 }}
  {{- end }}
  verbs:
    {{- $roleValues.verbs | toYaml | nindent 2 }}
{{- end }}
{{- end }}

{{/*
genericRoleBindingDefinition: all ClusterRoleBindings and RoleBindings have this structure
*/}}
{{- define "elCicdResources.genericRoleBindingDefinition" }}
{{- $ := index . 0 }}
{{- $roleBindingValues := index . 1 }}
{{- $_ := set $roleBindingValues "apiVersion" "rbac.authorization.k8s.io/v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
roleRef:
  {{- $roleBindingValues.roleRef | toYaml | nindent 2 }}
subjects:
{{ $roleBindingValues.subjects | toYaml }}
{{- end }}
