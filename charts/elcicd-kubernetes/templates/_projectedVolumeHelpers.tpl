{{- define "elcicd-kubernetes.projectedVolumes" }}
  {{- $ := index . 0 }}
  {{- $podValues := index . 1 }}
  {{- $containerVals := index . 2 }}
  
  {{- $volumeMounts := dict }}
  {{- range $projectedVolume := $containerVals.projectedVolumes }}
    {{- include "elcicd-kubernetes.addConfigMapsAndSecretsByLabels" (list $ $podValues $projectedVolume) }}

    {{- include "elcicd-kubernetes.createProjectedVolume" (list $ $podValues $projectedVolume) }}

    {{- $mountedVolume := dict "mountPath" $projectedVolume.mountPath }}
    {{- $_ := set $mountedVolume "name" $projectedVolume.name }}
    {{- if $projectedVolume.mountPropagation }}
      {{- $_ := set $mountedVolume "mountPropagation" $projectedVolume.mountPropagation }}
    {{- end }}
    {{- $_ := set $mountedVolume "readOnly" ($projectedVolume.readOnly | default false) }}
    {{- if $projectedVolume.subPath }}
      {{- $_ := set $mountedVolume "subPath" $projectedVolume.subPath }}
    {{- end }}
    {{- if $projectedVolume.subPathExpr }}
      {{- $_ := set $mountedVolume "subPathExpr" $projectedVolume.subPathExpr }}
    {{- end }}
    {{- $_ := set $volumeMounts $projectedVolume.name $mountedVolume }}
  {{- end }}
  {{- $_ := set $containerVals "volumeMounts" (concat ($containerVals.volumeMounts | default list) (values $volumeMounts)) }}
{{- end }}

{{- define "elcicd-kubernetes.createProjectedVolume" }}
  {{- $ := index . 0 }}
  {{- $podValues := index . 1 }}
  {{- $projectedVolume := index . 2 }}

  {{- $volume := dict }}
  {{- $_ := set $volume "name" $projectedVolume.name }}
  {{- if $projectedVolume.defaultMode }}
    {{- $_ := set $volume "defaultMode" $projectedVolume.defaultMode }}
  {{- end }}
  {{- $_ := set $volume "projected" dict }}
  {{- $_ := set $volume.projected "sources" list }}
  
  {{- $cmSources := dict }}
  {{- range $configMapName, $volumeDef := $projectedVolume.configMaps }}
    {{- $_ := set $volumeDef "name" $configMapName}}
    {{- $_ := set $cmSources $configMapName (dict "configMap" $volumeDef) }}
  {{- end }}
  
  {{- $secSources := dict }}
  {{- range $secretName, $volumeDef := $projectedVolume.secrets }}
    {{- $_ := set $volumeDef "name" $secretName}}
    {{- $_ := set $secSources $secretName (dict "secret" $volumeDef) }}
  {{- end }}
  
  {{- $saTokenSources := dict }}
  {{- range $saToken := $projectedVolume.serviceAccountTokens }}
    {{- $_ := set $secSources $saToken.name (dict "serviceAccountToken" $saToken) }}
  {{- end }}
  
  {{- $dApiSources := dict }}
  {{- range $dApiToken := $projectedVolume.downwardAPIs }}
    {{- $_ := set $secSources $dApiSources.name (dict "downwardAPI" $dApiToken) }}
  {{- end }}

  {{- $_ := set $volume.projected "sources" (concat (values $cmSources) (values $secSources) (values $saTokenSources) (values $dApiSources)) }}
  {{- $_ := set $podValues "volumes" (append ($podValues.volumes | default list) $volume) }}
{{- end }}

{{- define "elcicd-kubernetes.addConfigMapsAndSecretsByLabels" }}
  {{- $ = index . 0 }}
  {{- $podValues := index . 1 }}
  {{- $projectedVolume := index . 2 }}
  
  {{- $resultKey := uuidv4 }}
  
  {{- if or $projectedVolume.configMapLabels $projectedVolume.labels }}
    {{- $resources := ((lookup "v1" "ConfigMap" $podValues.namespace "").items | default list) }}
    {{- $resourceLabels := merge ($projectedVolume.configMapLabels | default dict) ($projectedVolume.labels | default dict) }}
    {{- include  "elcicd-kubernetes.getResourcesByLabel" (list $ $resources $resourceLabels $resultKey) }}
    {{- $_ := set $projectedVolume "configMaps" (merge ($projectedVolume.configMaps | default dict) (get $.Values.__EC_RESULT_DICT $resultKey)) }}
  {{- end }}
  
  {{- if or $projectedVolume.secretLabels $projectedVolume.labels }}
    {{- $resources := concat $resources ((lookup "v1" "Secret" $podValues.namespace "").items | default list) }}
    {{- $resourceLabels := merge ($projectedVolume.secretLabels | default dict) ($projectedVolume.labels | default dict) }}
    {{- include  "elcicd-kubernetes.getResourcesByLabel" (list $ $resources $resourceLabels $resultKey) }}
    {{- $_ := set $projectedVolume "secrets" (merge ($projectedVolume.secrets | default dict) (get $.Values.__EC_RESULT_DICT $resultKey)) }}
  {{- end }}
{{- end }}

{{- define "elcicd-kubernetes.getResourcesByLabel" }}
  {{- $ = index . 0 }}
  {{- $resources := index . 1 }}
  {{- $resourceLabels := index . 2 }}
  {{- $resultKey := index . 3 }}
  
  {{- $labelResources := dict }}
  {{- range $resource := $resources }}
    {{- if $resource.metadata.labels  }}
      {{- range $resourceLabel, $resourceVolDef := $resourceLabels }}
        {{- if hasKey $resource.metadata.labels $resourceLabel }}
          {{- $_ := set $labelResources $resource.metadata.name (deepCopy $resourceVolDef) }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  
  {{- $_ := set $.Values.__EC_RESULT_DICT $resultKey $labelResources }}
{{- end }}