{{- define "elCicdJenkins.configurePipelines" }}
  {{- $elCicdDefs := $.Values.elCicdDefs }}

  {{- $configMaps := lookup "v1" "ConfigMap" $.Release.Namespace "" }}
    
  {{- $projectDict := dict }}
  {{- $jobsPath := "%s/jobs/%s/config.xml" }}
  {{- range $pipelineMap := $configMaps.items }}
    {{- if ($pipelineMap.metadata).labels }}
      {{- if get $pipelineMap.metadata.labels "jenkins-pipeline" }}
        {{- $projectId := $pipelineMap.data.projectid }}
        {{- if not (hasKey $projectDict $projectId) }}          
          {{- $itemList := list (dict "key" "configXml" "path" (printf "%s/config.xml" $projectId)) }}
          {{- $configMapVolume := dict "configMap" (dict "name" "jenkins-folder" "items" $itemList) }}
          {{- $_ := set $elCicdDefs "VOLUME_JOB_SOURCES" (append ($elCicdDefs.VOLUME_JOB_SOURCES | default list) $configMapVolume) }} 
          {{- $projectDict = set $projectDict $pipelineMap.data.projectid "placeholder" }}
        {{- end }}
        
        {{- $itemList := list (dict "key" "configXml" "path" (printf $jobsPath $projectId $pipelineMap.metadata.name)) }}
        {{- $configMapVolume := dict "configMap" (dict "name" $pipelineMap.metadata.name "items" $itemList) }}
        {{- $_ := set $elCicdDefs "VOLUME_JOB_SOURCES" (append ($elCicdDefs.VOLUME_JOB_SOURCES | default list) $configMapVolume) }} 
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}