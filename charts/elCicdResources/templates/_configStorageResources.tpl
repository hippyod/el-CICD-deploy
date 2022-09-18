{{/*
ConfigMap
*/}}
{{- define "elCicdResources.configMap" }}
{{- $ := index . 0 }}
{{- $cmValues := index . 1 }}
{{- $_ := set $cmValues "kind" "ConfigMap" }}
{{- $_ := set $cmValues "apiVersion" "v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
{{- if $cmValues.binaryData }}
binaryData: {{ $cmValues.binaryData | toYaml | nindent 2}}
{{- end }}
{{- if $cmValues.data }}
data: {{ $cmValues.data | toYaml | nindent 2}}
{{- end }}
{{- if $cmValues.immutable }}
immutable: {{ $cmValues.immutable }}
{{- end }}
{{- end }}

{{/*
Secret
*/}}
{{- define "elCicdResources.secret" }}
{{- $ := index . 0 }}
{{- $secretValues := index . 1 }}
{{- $_ := set $secretValues "kind" "Secret" }}
{{- $_ := set $secretValues "apiVersion" "v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
{{- if $secretValues.data }}
data: {{ $secretValues.data | toYaml | nindent 2}}
{{- end }}
{{- if $secretValues.stringData }}
stringData: {{ $secretValues.stringData | toYaml | nindent 2}}
{{- end }}
{{- if $secretValues.immutable }}
immutable: {{ $secretValues.immutable }}
{{- end }}
{{- end }}

{{/*
PersistentVolume
*/}}
{{- define "elCicdResources.persistentVolume" }}
{{- $ := index . 0 }}
{{- $pvValues := index . 1 }}
kind: PersistentVolume
apiVersion: v1
metadata:
  name: {{ required "pv name required!" $pvValues.name }}
spec:
  capacity:
    storage: {{ $pvValues.storageCapacity }}
  accessModes:
  {{- if $pvValues.accessModes }}
  {{- $pvValues.accessModes | toYaml | indent 2 }}
  {{- else }}
  -  {{ $pvValues.accessMode | $.Values.global.defaultPvAccessMode }}
  {{- end }}
  persistentVolumeReclaimPolicy: {{ $pvValues.volumeReclaimPolicy | default $.Values.global.defaultVolumeReclaimPolicy }}
  nfsSpec: {{ $pvValues.pvSpec | toYaml | nindent 2 }}
  {{- if $pvValues.nodeAffinity }}
  nodeAffinity: {{ $pvValues.nodeAffinity | toYaml | nindent 4 }}
  {{- end }}
  {{- if $pvValues.storageClassName }}
  storageClassName: {{ $pvValues.storageClassName }}
  {{- end }}
  {{- if $pvValues.volumeMode }}
  volumeMode: {{ $pvValues.volumeMode }}
  {{- end }}
  claimRef:
    name: {{ required "pv claimRef name required!" $pvValues.claimRefName }}
    namespace: {{ required "pv claimRef namespace required!" $pvValues.claimRefNamespace }}
{{- end }}

{{/*
PersistentVolumeClaim
*/}}
{{- define "elCicdResources.persistentVolumeClaim" }}
{{- $ := index . 0 }}
{{- $pvcValues := index . 1 }}
{{- $_ := set $pvcValues "kind" "PersistentVolumeClaim" }}
{{- $_ := set $pvcValues "apiVersion" "v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
spec:
  accessModes:
  {{- if $pvcValues.accessModes }}
    {{- $pvcValues.accessModes | toYaml | indent 2 }}
  {{- else }}
  - {{ $pvcValues.accessMode | default $.Values.global.defaultPvAccessMode }}
  {{- end }}
  {{- if $pvcValues.dataSource }}
  dataSourceRef: {{ $pvcValues.dataSource | toYaml| nindent 4 }}
  {{- end }}
  {{- if $pvcValues.dataSourceRef }}
  dataSourceRef: {{ $pvcValues.dataSourceRef | toYaml| nindent 4 }}
  {{- end }}
  {{- if $pvcValues.resources }}
  resources: $pvcValues.resources | toYaml | nindent 2 }}
  {{- else }}
  resources:
    requests:
      storage: {{ $pvcValues.storageCapacity }}
  {{- end }}
  {{- if $pvcValues.selector }}
  selector: {{ $pvcValues.selector | toYaml| nindent 4 }}
  {{- end }}
  {{- if $pvcValues.storageClassName }}
  storageClassName: {{ $pvcValues.storageClassName }}
  {{- end }}
  {{- if $pvcValues.volumeMode }}
  volumeMode: {{ $pvcValues.volumeMode }}
  {{- end }}
  {{- if $pvcValues.volumeName }}
  volumeName: {{ $pvcValues.volumeName }}
  {{- end }}
{{- end }}
    
    