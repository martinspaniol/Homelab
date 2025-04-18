{{- define "plextraktsync.name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end -}}

{{- define "plextraktsync.fullname" -}}
{{ .Release.Name }}-{{ include "plextraktsync.name" . }}
{{- end -}}

{{- define "plextraktsync.labels" -}}
app.kubernetes.io/name: {{ include "plextraktsync.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}