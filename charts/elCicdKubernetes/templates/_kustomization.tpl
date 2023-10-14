{{/*
Kustomization
*/}}
{{- define "elCicdKubernetes.kustomization" }}
{{- $ := index . 0 }}
{{- $kustValues := index . 1 }}
{{- $_ := set $kustValues "kind" "Kustomization" }}
{{- $_ := set $kustValues "apiVersion" "kustomize.config.k8s.io/v1beta1" }}
{{- include "elCicdCommon.apiObjectHeader" . }}

{{- $kustomizations := dict  
  "buildMetadata" "placeHolder"
  "commonAnnotations" "placeHolder"
  "commonLabels" "placeHolder"
  "components" "placeHolder"
  "configMapGenerator" "placeHolder"
  "crds" "placeHolder"
  "images" "placeHolder"
  "labels" "placeHolder"
  "namePrefix" "placeHolder"
  "namespace" "placeHolder"
  "nameSuffix" "placeHolder"
  "openApi" "placeHolder"
  "patches" "placeHolder"
  "replacements" "placeHolder"
  "replicas" "placeHolder"
  "resources" "placeHolder"
  "secretGenerator" "placeHolder"
  "sortOptions" "placeHolder"
}}

{{- range $kustomization := $kustValues }}
  {{- if not (get $kustomizations $kustomization) }}
    {{- fail "%s is NOT a valid kustomization built-in" $kustomization }}
  {{- end }}
{{ $kustomization }}: {{ get $kustValues $kustomization }}
{{- end }}
