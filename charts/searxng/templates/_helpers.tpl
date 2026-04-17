{{- define "searxng.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "searxng.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "searxng.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "searxng.selectorLabels" -}}
app.kubernetes.io/name: {{ include "searxng.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "searxng.labels" -}}
helm.sh/chart: {{ include "searxng.chart" . }}
{{ include "searxng.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "searxng.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "searxng.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "searxng.runtimeEnvSecretName" -}}
{{- printf "%s-runtime" (include "searxng.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "searxng.configConfigMapName" -}}
{{- printf "%s-config" (include "searxng.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "searxng.configSecretName" -}}
{{- printf "%s-config-secret" (include "searxng.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "searxng.caConfigMapName" -}}
{{- printf "%s-ca" (include "searxng.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "searxng.valkey.fullname" -}}
{{- printf "%s-valkey" (include "searxng.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "searxng.valkey.authSecretName" -}}
{{- printf "%s-valkey-auth" (include "searxng.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "searxng.searxngSecretValue" -}}
{{- if .Values.secret.value -}}
{{- .Values.secret.value -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (include "searxng.runtimeEnvSecretName" .) -}}
{{- if and $existing (hasKey $existing.data "SEARXNG_SECRET") -}}
{{- index $existing.data "SEARXNG_SECRET" | b64dec -}}
{{- else -}}
{{- randAlphaNum 64 -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "searxng.valkeyPasswordValue" -}}
{{- if .Values.valkey.auth.password -}}
{{- .Values.valkey.auth.password -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (include "searxng.valkey.authSecretName" .) -}}
{{- if and $existing (hasKey $existing.data "password") -}}
{{- index $existing.data "password" | b64dec -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "searxng.managedValkeyUrl" -}}
{{- if .Values.valkey.externalUrl -}}
{{- .Values.valkey.externalUrl -}}
{{- else if .Values.valkey.enabled -}}
{{- if .Values.valkey.auth.enabled -}}
{{- printf "valkey://:%s@%s:%v/0" (include "searxng.valkeyPasswordValue" .) (include "searxng.valkey.fullname" .) .Values.valkey.service.port -}}
{{- else -}}
{{- printf "valkey://%s:%v/0" (include "searxng.valkey.fullname" .) .Values.valkey.service.port -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "searxng.createRuntimeEnvSecret" -}}
{{- if or (and .Values.secret.create (not .Values.secret.existingSecret) (not (hasKey .Values.env.values "SEARXNG_SECRET")) (not (hasKey .Values.env.secretValues "SEARXNG_SECRET"))) (gt (len .Values.env.secretValues) 0) (and (not (hasKey .Values.env.values "SEARXNG_VALKEY_URL")) (not (hasKey .Values.env.secretValues "SEARXNG_VALKEY_URL")) (not .Values.valkey.externalUrlSecret.name) (or .Values.valkey.externalUrl .Values.valkey.enabled)) -}}true{{- end -}}
{{- end -}}
