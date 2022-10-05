{{/*
Expand the name of the chart.
*/}}
{{- define "quickwit.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "quickwit.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "quickwit.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "quickwit.labels" -}}
helm.sh/chart: {{ include "quickwit.chart" . }}
{{ include "quickwit.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "quickwit.selectorLabels" -}}
app.kubernetes.io/name: {{ include "quickwit.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Search Selector labels
*/}}
{{- define "quickwit.searcher.selectorLabels" -}}
{{ include "quickwit.selectorLabels" . }}
app.kubernetes.io/component: searcher
{{- end }}

{{/*
Indexer Selector labels
*/}}
{{- define "quickwit.indexer.selectorLabels" -}}
{{ include "quickwit.selectorLabels" . }}
app.kubernetes.io/component: indexer
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "quickwit.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "quickwit.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Quickwit environment
*/}}
{{- define "quickwit.environment" -}}
- name: NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
- name: POSTGRES_HOST
  value: {{ required "A valid config.postgres.host is required!" .Values.config.postgres.host }}
- name: POSTGRES_PORT
  value: {{ .Values.config.postgres.port | default 5432 | quote }}
- name: POSTGRES_DATABASE
  value: {{ .Values.config.postgres.database | default "metastore" }}
- name: POSTGRES_USERNAME
  value: {{ .Values.config.postgres.username | default "quickwit" }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "quickwit.fullname" . }}
      key: postgres.password
- name: QW_CONFIG
  value: node.yaml
- name: QW_METASTORE_URI
  value: "postgres://$(POSTGRES_USERNAME):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/$(POSTGRES_DATABASE)"
{{- if .Values.config.s3.endpoint }}
- name: QW_S3_ENDPOINT
  value: {{ .Values.config.s3.endpoint }}
{{- end }}
- name: AWS_REGION
  value: {{ .Values.config.s3.region | default "us-east-1" }}
- name: AWS_ACCESS_KEY_ID
  value: {{ required "A valid config.s3.access_key is required!" .Values.config.s3.access_key }}
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "quickwit.fullname" . }}
      key: s3.secret_key
- name: QW_NODE_ID
  value: "$(POD_NAME)"
- name: QW_PEER_SEEDS
  value: {{ include "quickwit.fullname" . }}-headless
- name: QW_PUBLIC_IP
  value: "$(POD_IP)"
{{- range $key, $value := .Values.environment }}
- name: "{{ $key }}"
  value: "{{ $value }}"
{{- end }}
{{- end }}

