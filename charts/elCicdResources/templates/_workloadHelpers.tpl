{{/*
Deployment and Service combination
*/}}
{{- define "elCicdResources.deploymentService" }}
  {{- include "elCicdResources.deployment" . }}
---
  {{- include "elCicdResources.service" . }}
{{- end }}

{{/*
Deployment, Service, and Ingress combination
*/}}
{{- define "elCicdResources.deploymentServiceIngress" }}
  {{- include "elCicdResources.deployment" . }}
---
  {{- include "elCicdResources.service" . }}
---
  {{- include "elCicdResources.ingress" . }}
{{- end }}

{{/*
Job Template
*/}}
{{- define "elCicdResources.jobTemplate" }}
{{- $ := index . 0 }}
{{- $jobValues := index . 1 }}
{{- include "elCicdResources.apiMetadata" . }}
spec:
  {{- $whiteList := list "activeDeadlineSeconds"
                         "backoffLimit"
                         "completionMode"
                         "completions"
                         "manualSelector"
                         "parallelism"
                         "ttlSecondsAfterFinished" }}
  {{- $_ := set $jobValues "restartPolicy" ($jobValues.restartPolicy | default "Never") }}
  {{- include "elCicdResources.outputToYaml" (list $ $jobValues $whiteList) }}
  template: {{ include "elCicdResources.podTemplate" (list $ $jobValues false) | nindent 4 }}
{{- end }}

{{/*
Pod Template
*/}}
{{- define "elCicdResources.podTemplate" }}
{{- $ := index . 0 }}
{{- $podValues := index . 1 }}
{{- include "elCicdResources.apiMetadata" . }}
spec:
  {{- $whiteList := list  "activeDeadlineSeconds"
                          "affinity"
                          "automountServiceAccountToken"
                          "dnsConfig"
                          "dnsPolicy"
                          "enableServiceLinks"
                          "hostAliases"
                          "hostIPC"
                          "hostNetwork"
                          "hostPID"
                          "hostname"
                          "nodeName"
                          "nodeSelector"
                          "os"
                          "overhead"
                          "preemptionPolicy"
                          "priority"
                          "priorityClassName"
                          "readinessGates"
                          "restartPolicy"
                          "runtimeClassName"
                          "schedulerName"
                          "serviceAccount"
                          "serviceAccountName"
                          "setHostnameAsFQDN"
                          "shareProcessNamespace"
                          "subdomain"
                          "terminationGracePeriodSeconds"
                          "tolerations"
                          "topologySpreadConstraints"
                          "volumes" }}
  containers:
    {{- $containers := prepend ($podValues.sidecars | default list) $podValues }}
    {{- include "elCicdResources.containers" (list $ $podValues $containers) | trim | nindent 2 }}
  {{- if $podValues.ephemeralContainers }}
  ephemeralContainers:
    {{- include "elCicdResources.containers" (list $ $podValues.ephemeralContainers false) | trim | nindent 2 }}
  {{- end }}
  {{- $_ := set $podValues "imagePullSecrets" ($podValues.imagePullSecrets | default $.Values.elCicdDefaults.imagePullSecrets) }}
  {{- $_ := set $podValues "imagePullSecret" ($podValues.imagePullSecret | default $.Values.elCicdDefaults.imagePullSecret) }}
  {{- if $podValues.imagePullSecrets }}
  imagePullSecrets:
    {{- range $secretName := $podValues.imagePullSecrets }}
  - name: {{ $secretName }}
    {{- end }}
  {{- else if $podValues.imagePullSecret }}
  imagePullSecrets:
  - name: {{ $podValues.imagePullSecret }}
  {{- else }}
  imagePullSecrets: []
  {{- end }}
  {{- if $podValues.initContainers }}
  initContainers:
    {{- include "elCicdResources.containers" (list $ $podValues.initContainers false) | trim | nindent 2 }}
  {{- end }}
  {{- if $podValues.securityContext }}
  securityContext: {{ $podValues.securityContext | toYaml | nindent 4 }}
  {{- else }}
  securityContext:
    runAsNonRoot: true
    {{- if not $.Values.useLegacyPodSecurityContextDefault }}
    seccompProfile:
      type: RuntimeDefault
    {{- end }}
  {{- end }}
  {{- include "elCicdResources.outputToYaml" (list $ $podValues $whiteList) }}
{{- end }}

{{/*
Container definition
*/}}
{{- define "elCicdResources.containers" }}
{{- $ := index . 0 }}
{{- $podValues := index . 1 }}
{{- $containers := index . 2 }}
{{- $whiteList := list "args"
                       "command"
                       "env"
                       "envFrom"
                       "lifecycle"
                       "livenessProbe"
                       "readinessProbe"
                       "startupProbe"
                       "stdin"
                       "stdinOnce"
                       "terminationMessagePath"
                       "terminationMessagePolicy"
                       "tty"
                       "volumeDevices"
                       "volumeMounts"
                       "workingDir" }}
{{- range $containerVals := $containers }}
- name: {{ $containerVals.name | default $containerVals.appName }}
  {{- if $containerVals.envFromSelectors }}
    {{- include "elCicdResources.envFrom" }}
  {{- end }}
  image: {{ $containerVals.image | default $.Values.elCicdDefaults.image }}
  imagePullPolicy: {{ $containerVals.imagePullPolicy | default $.Values.elCicdDefaults.imagePullPolicy }}
  {{- if or $containerVals.ports $containerVals.port $.Values.elCicdDefaults.port $containerVals.usePrometheus }}
  ports:
    {{- if and $containerVals.ports $containerVals.port }}
      {{- fail "A Container cannot define both port and ports values!" }}
    {{- end }}
    {{- if $containerVals.ports }}
      {{- $containerVals.ports | toYaml | nindent 2 }}
    {{- else if or $containerVals.port $.Values.elCicdDefaults.port }}
  - name: default-port
    containerPort: {{ $containerVals.port | default $.Values.elCicdDefaults.port }}
    protocol: {{ $containerVals.protocol | default $.Values.elCicdDefaults.protocol }}
    {{- end }}
    {{- if or ($containerVals.prometheus).port (and $containerVals.usePrometheus $.Values.elCicdDefaults.prometheusPort) }}
  - name: prometheus-port
    containerPort: {{ ($containerVals.prometheus).port | default $.Values.elCicdDefaults.prometheusPort }}
    protocol: {{ ($containerVals.prometheus).protocol | default ($.Values.elCicdDefaults.prometheusProtocol | default $.Values.elCicdDefaults.protocol) }}
    {{- end }}
  {{- end }}
  resources:
    limits:
      {{- if ($containerVals.resources).limits }}
        {{- range $limit, $value := ($containerVals.resources).limits }}
      {{ $limit }}: {{ $value }}
        {{- end }}
      {{- else }}
        {{- if $containerVals.limitsCpu }}
      cpu: {{ $containerVals.limitsCpu }}
        {{- end }}
        {{- if $containerVals.limitsMemory }}
      memory: {{ $containerVals.limitsMemory }}
        {{- end }}
      {{- end }}
    requests:
      {{- if ($containerVals.resources).requests }}
        {{- range $request, $value := ($containerVals.resources).requests }}
      {{ $request }}: {{ $value }}
        {{- end }}
      {{- else }}
        {{- if $containerVals.requestsCpu }}
      cpu: {{ $containerVals.requestsCpu }}
        {{- end }}
        {{- if $containerVals.requestsMemory }}
      memory: {{ $containerVals.requestsMemory }}
        {{- end }}
      {{- end }}
  {{- if $containerVals.securityContext }}
  securityContext: {{ $containerVals.securityContext | toYaml | nindent 4 }}
  {{- else }}
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
      - ALL
  {{- end }}
  {{- if $containerVals.projectedVolumeLabels }}
    {{- include "elCicdResources.createProjectedVolumesByLabels" (list $ $podValues $containerVals)}}
  {{- end }}
  {{- include "elCicdResources.outputToYaml" (list $ $containerVals $whiteList) }}
{{- end }}
{{- end }}