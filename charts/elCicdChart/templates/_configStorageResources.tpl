{{/*
ConfigMap
*/}}
{{- define "elCicdChart.configMap" }}

{{- $cmValues := index . 1 }}
{{- $_ := set $cmValues "kind" "ConfigMap" }}
{{- $_ := set $cmValues "apiVersion" "v1" }}
{{- include "elCicdChart.apiObjectHeader" . }}
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
PersistentVolume
*/}}
{{- define "elCicdChart.PersistentVolume" }}
{{- $pvValues := index . 1 }}
kind: PersistentVolume
apiVersion: v1
metadata:
  projectid: {{ $.Values.projectid }}
  name: {{ required "pv name required!" $pvValues.name }}
spec:
  capacity:
    storage: {{ $pvValues.storageCapacity }}
  accessModes:
  {{- if $pvValues.accessModes }}
  {{- $pvValues.accessModes | toYaml | indent 2 }}
  {{- else }}
  -  {{ $pvValues.accessMode | $.Values.defaultPvAccessMode }}
  {{- end }}
  persistentVolumeReclaimPolicy: {{ $pvValues.volumeReclaimPolicy | default $.Values.defaultVolumeReclaimPolicy }}
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
{{- define "elCicdChart.PersistentVolumeClaim" }}
{{- $pvcValues := index . 1 }}
{{- $_ := set $pvcValues "kind" "PersistentVolumeClaim" }}
{{- $_ := set $pvcValues "apiVersion" "v1" }}
{{- include "elCicdChart.apiObjectHeader" . }}
spec:
  accessModes:
  {{- if $pvcValues.accessModes }}
  {{- $pvcValues.accessModes | toYaml | indent 2 }}
  {{- else }}
  -  {{ $pvcValues.accessMode | $.Values.defaultPvAccessMode }}
  {{- end }}
  {{- if $pvcValues.dataSourceRef }}
  dataSourceRef: {{ $pvcValues.dataSourceRef | toYaml| nindent 4 }}
  {{- end }}
  {{- if $pvcValues.resources }}
  resources: $pvcValues.resources | toYaml | nindent 2 }}
  {{- else }}
  resources:
    requests:
      storage: {{ $pvcValues.capacity }}
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
  volumeName: {{ $pvcValues.volumeName }}
{{- end }}
    
    