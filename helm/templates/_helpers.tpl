{{/*
Create the name of the ServiceAccount to use
*/}}
{{- define "my-api-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
    {{- default (include "my-api-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
    {{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Fullname of the chart.
*/}}
{{- define "my-api-chart.fullname" -}}
{{- .Release.Name }}-{{ .Chart.Name }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "my-api-chart.labels" -}}
helm.sh/chart: {{ include "my-api-chart.chart" . }}
{{ include "my-api-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "my-api-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-api-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Chart name
*/}}
{{- define "my-api-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride }}
{{- end }}

{{/*
Chart version
*/}}
{{- define "my-api-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end }}