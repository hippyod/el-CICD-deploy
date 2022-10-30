{{- define "elCicdResources.importEnvs" }}
  {{- $ := index . 0 }}
  {{- $containerVals := index . 0 }}

  {{- $resources := ((lookup "v1" "ConfigMap" $.Release.Namespace "").items | default list) }}
  {{- $resources := concat $resources.items ((lookup "v1" "Secret" $.Release.Namespace "").items | default list) }}

  {{- range $envFromLabels := $containerVals.envFromLabels }}
    {{- $resultMap := dict }}
    {{- include "elCicdResources.getResourcesByLabel" (list $ $resources $envFromLabels.labels $resultMap) }}
    {{- $labelResources := $resultMap.result }}
    
    {{- $envFromList := list }}
    {{- range $resourceName, $resource := $labelResources }}
      {{- $resourceMap := dict "name" $resourceName "optional" ($envFromLabels.optional | default false) }}
    
      {{- $sourceKey := printf "%sRef" ((eq $resource.kind "ConfigMap") | ternary "configMap" "secret") }}
      {{- $envFromList = append $envFromList (dict $sourceKey $resourceMap) }}
    {{- end }}
    {{- $_ := set $containerVals "envFrom" (concat ($containerVals.envFrom | default list) $envFromList) }}
  {{- end }}
{{- end }}

{{- define "elCicdResources.createProjectedVolumesByLabels" }}
  {{- $ := index . 0 }}
  {{- $podValues := index . 1 }}
  {{- $containerVals := index . 2 }}

  {{- $resources := ((lookup "v1" "ConfigMap" $.Release.Namespace "").items | default list) }}
  {{- $resources := concat $resources ((lookup "v1" "Secret" $.Release.Namespace "").items | default list) }}
  
  {{- range $volumeByLabels := $containerVals.projectedVolumeLabels }}
    {{- $resultMap := dict }}
    {{- include "elCicdResources.getResourcesByLabel" (list $ $resources $volumeByLabels.labels $resultMap) }}
    {{- $labeledResources := $resultMap.result }}

    {{- if $labeledResources }}
      {{- include "elCicdResources.createProjectedVolume" (list $ $podValues $volumeByLabels $labeledResources) }}

      {{- $mountedVolume := dict "name" $volumeByLabels.name
                                 "mountPath" $volumeByLabels.mountPath
                                 "readOnly" $volumeByLabels.readOnly
                                 "subPath" $volumeByLabels.subPath
                                 "subPathExpr" $volumeByLabels.subPathExpr }}
      {{- $_ := set $containerVals "volumeMounts" (append ($containerVals.volumeMounts | default list) $mountedVolume) }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "elCicdResources.createProjectedVolume" }}
  {{- $ := index . 0 }}
  {{- $podValues := index . 1 }}
  {{- $volumeByLabels := index . 2 }}
  {{- $labeledResources := index . 3 }}

  {{- $sourcesList := list }}
  {{- range $resourceName, $resource := $labeledResources }}
    {{- $item := dict "key" ($resource.data.contentKey | default "projectedContent") "path" ($resource.data.path | default "") }}
    {{- if $resource.data.mode }}
      {{- $_ := set $item "mode" $resource.data.mode }}
    {{- end }}
    {{- $items := list $item }}

    {{- $sourceMap := dict "name" $resourceName
                           "items" $items
                           "optional" (eq $resource.data.optional "true") }}

    {{- $sourceKey := (eq $resource.kind "ConfigMap") | ternary "configMap" "secret" }}
    {{- $sourcesList = append $sourcesList (dict $sourceKey $sourceMap) }}
  {{- end }}

  {{- $projectedMap := dict "sources" $sourcesList
                            "defaultMode" ($volumeByLabels.defaultMode | default 0777) }}

  {{- $projectVolume := dict "name" $volumeByLabels.name
                             "projected" $projectedMap }}

        # foo {{ len $podValues.volumes }}
  {{- $_ := set $podValues "volumes" (append ($podValues.volumes | default list) $projectVolume) }}
        # foo {{ len $podValues.volumes }}
{{- end }}

{{- define "elCicdResources.getResourcesByLabel" }}
  {{- $ = index . 0 }}
  {{- $resources := index . 1 }}
  {{- $labels := index . 2 }}
  {{- $resultMap := index . 3 }}
  
  {{- $labelResources := dict }}
  {{- range $resource := $resources }}
    {{- range $volumeLabel := $labels }}
      {{- if $resource.metadata.labels  }}
        {{- if hasKey $resource.metadata.labels $volumeLabel }}
          {{- $_ := set $labelResources $resource.metadata.name $resource }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  
  {{- $_ := set $resultMap "result" $labelResources }}
{{- end }}