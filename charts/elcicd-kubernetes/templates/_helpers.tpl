
{{/*
  ======================================
  elcicd-kubernetes.init
  ======================================
  
  Initialize elcicd-kubernetes chart.  Sets the following defaults:
  
  - deploymentRevisionHistoryLimit: 0
  - port: 0
  - protocol: 0
  - ingressRulePath: 0
  - ingressRulePathType: 0
  
  Prometheus and 3Scale defaults are provided:
  
  - prometheusPort: 0
  - prometheusPath: 0
  - prometheusScheme: 0
  - prometheusScrape: 0
  - prometheusProtocol: 0
  
  - 3ScaleScheme: 0
*/}}
{{- define "elcicd-kubernetes.init" }}
  {{- $ := . }}
  
  {{- $_ := set $.Values.elCicdDefaults "annotations" ($.Values.elCicdDefaults.annotations | default dict) }}
  {{- $_ := set $.Values.elCicdDefaults "labels" ($.Values.elCicdDefaults.labels | default dict) }}
  
  {{- $_ := set $.Values.elCicdDefaults "deploymentRevisionHistoryLimit" ($.Values.elCicdDefaults.deploymentRevisionHistoryLimit | default 0) }}

  {{- $_ := set $.Values.elCicdDefaults "imagePullPolicy" ($.Values.elCicdDefaults.imagePullPolicy | default "Always") }}

  {{- $_ := set $.Values.elCicdDefaults "port" ($.Values.elCicdDefaults.port | default "8080") }}
  {{- $_ := set $.Values.elCicdDefaults "protocol" ($.Values.elCicdDefaults.protocol | default "TCP") }}

  {{- $_ := set $.Values.elCicdDefaults "ingressRulePath" ($.Values.elCicdDefaults.ingressRulePath | default "/") }}
  {{- $_ := set $.Values.elCicdDefaults "ingressRulePathType" ($.Values.elCicdDefaults.ingressRulePathType | default "Prefix") }}

  {{- $_ := set $.Values.elCicdDefaults "prometheusPort" ($.Values.elCicdDefaults.prometheusPort | default "9090") }}
  {{- $_ := set $.Values.elCicdDefaults "prometheusPath" ($.Values.elCicdDefaults.prometheusPath | default "/metrics") }}
  {{- $_ := set $.Values.elCicdDefaults "prometheusScheme" ($.Values.elCicdDefaults.prometheusScheme | default "https") }}
  {{- $_ := set $.Values.elCicdDefaults "prometheusScrape" ($.Values.elCicdDefaults.prometheusScrape | default "false") }}
  {{- $_ := set $.Values.elCicdDefaults "prometheusProtocol" ($.Values.elCicdDefaults.prometheusProtocol | default "TCP") }}

  {{- $_ := set $.Values.elCicdDefaults "3ScaleScheme" ((get $.Values.elCicdDefaults "3ScaleScheme") | default "https") }}
{{- end }}

{{/*
Service Prometheus Annotations definition
*/}}
{{- define "elcicd-kubernetes.prometheusAnnotations" }}
  {{- $ := index . 0 }}
  {{- $svcValues := index . 1 }}
  {{- $_ := set $svcValues "annotations" ($svcValues.annotations | default dict) }}

  {{- if or ($svcValues.prometheus).path $.Values.elCicdDefaults.prometheusPath }}
    {{- $_ := set $svcValues.annotations "prometheus.io/path" ($svcValues.prometheus.path | default $.Values.elCicdDefaults.prometheusPath) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).port $.Values.elCicdDefaults.prometheusPort }}
    {{- $_ := set $svcValues.annotations "prometheus.io/port" ($svcValues.prometheus.port | default $svcValues.port) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).scheme $.Values.elCicdDefaults.prometheusScheme }}
    {{- $_ := set $svcValues.annotations "prometheus.io/scheme" ($svcValues.prometheus.scheme | default $.Values.elCicdDefaults.prometheusScheme) }}
  {{- end }}

  {{- if or ($svcValues.prometheus).scrape $.Values.elCicdDefaults.prometheusScrape }}
    {{- $_ := set $svcValues.annotations "prometheus.io/scrape" ($svcValues.prometheus.scrape | default $.Values.elCicdDefaults.prometheusScrape) }}
  {{- end }}
{{- end }}

{{/*
Service Prometheus 3Scale definition
*/}}
{{- define "elcicd-kubernetes.3ScaleAnnotations" }}
  {{- $ := index . 0 }}
  {{- $svcValues := index . 1 }}
  {{- $_ := set $svcValues "annotations" ($svcValues.annotations | default dict) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/path" ($svcValues.threeScale.port | default $svcValues.port | default $.Values.elCicdDefaults.port) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/port" ($svcValues.threeScale.path | default (get $.Values.elCicdDefaults "3ScalePath")) }}
  {{- $_ := set $svcValues.annotations "discovery.3scale.net/scheme" ($svcValues.threeScale.scheme | default (get $.Values.elCicdDefaults "3ScaleScheme")) }}
{{- end }}