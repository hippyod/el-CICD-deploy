{{/*
Ingress
*/}}
{{- define "elCicdResources.ingress" }}
{{- $ := index . 0 }}
{{- $ingressValues := index . 1 }}
{{- $_ := set $ingressValues "kind" "Ingress" }}
{{- $_ := set $ingressValues "apiVersion" "networking.k8s.io/v1" }}
{{- $_ := set $ingressValues "annotations" ($ingressValues.annotations | default dict) }}
{{- $_ := set $ingressValues "allowHttp" ($ingressValues.allowHttp | default "false") }}
{{- $_ := set $ingressValues.annotations "kubernetes.io/ingress.allow-http" $ingressValues.allowHttp }}
{{- include "elCicdResources.apiObjectHeader" . }}
spec:
  {{- if $ingressValues.defaultBackend }}
  defaultBackend: {{ $ingressValues.defaultBackend | toYaml | nindent 4 }}
  {{- end }}
  {{- if $ingressValues.ingressClassName }}
  ingressClassName: {{ $ingressValues.ingressClassName }}
  {{- end }}
  {{- if $ingressValues.rules }}
  rules: {{ $ingressValues.rules | toYaml | nindent 4 }}
  {{- else }}
  rules:
  - host: {{ $ingressValues.host | default (printf "%s%s" $ingressValues.appName $.Values.ingressHostSuffix) }}
    http:
      paths:
      - path: {{ $ingressValues.path | default $.Values.global.defaultIngressRulePath }}
        pathType: {{ $ingressValues.pathType | default $.Values.global.defaultIngressRulePathType }}
        backend:
          service:
            name: {{ $ingressValues.appName }}
            port:
              number: {{ $ingressValues.port | default $.Values.global.defaultPort }}
  {{- end }}
  {{- if $ingressValues.tls }}
  tls: {{ $ingressValues.tls | toYaml | nindent 4 }}
  {{- else if or $ingressValues.secretName (eq $ingressValues.allowHttp "false") }}
  tls:
  - secretName: {{ $ingressValues.secretName }}
  {{- end }}
{{- end }}

{{/*
Service
*/}}
{{- define "elCicdResources.service" }}
{{- $ := index . 0 }}
{{- $svcValues := index . 1 }}
{{- if or ($svcValues.prometheus).port $.Values.usePrometheus }}
  {{- include "elCicdResources.svcPrometheusAnnotations" . }}
{{- end }}
{{- if or $svcValues.threeScalePort $.Values.use3Scale }}
  {{- include "elCicdResources.3ScaleAnnotations" . }}
  {{- $_ := set $svcValues "labels" ($svcValues.labels  | default dict) }}
  {{- $_ := set $svcValues.labels "discovery.3scale.net" true }}
{{- end }}
{{- $_ := set $svcValues "kind" "Service" }}
{{- $_ := set $svcValues "apiVersion" "v1" }}
{{- include "elCicdResources.apiObjectHeader" . }}
spec:
  selector:
    {{- include "elCicdResources.selectorLabels" . | indent 4 }}
    {{- range $key, $value := $svcValues.selector }}
    {{ $key }}: {{ $value }}
    {{- end }}
  ports:
  {{- if and (or ($svcValues.service).ports $svcValues.ports) $svcValues.port }}
    {{- fail "A Service cannot define both port and ports values!" }}
  {{- end }}
  {{- if or $svcValues.ports ($svcValues.service).ports }}
    {{- (($svcValues.service).ports | default $svcValues.ports) | toYaml | nindent 2 }}
  {{- else }}
  - name: {{ $svcValues.appName }}-port
    port: {{ $svcValues.port | default $.Values.defaultPort }}
    {{- if $svcValues.targetPort }}
    targetPort: {{ $svcValues.targetPort }}
    {{- end }}
    {{- if or $svcValues.protocol $.Values.defaultProtocol }}
    protocol: {{ $svcValues.protocol | default $.Values.defaultProtocol }}
    {{- end }}
  {{- end }}
  {{- if or ($svcValues.prometheus).port $svcValues.usePrometheus }}
  - name: prometheus-port
    port: {{ ($svcValues.prometheus).port | default $.Values.defaultPrometheusPort }}
    {{- if or ($svcValues.prometheus).protocol $.Values.defaultPrometheusProtocol }}
    protocol: {{ ($svcValues.prometheus).protocol | default $.Values.defaultPrometheusProtocol }}
    {{- end }}
  {{- end }}
{{- end }}