#!/bin/bash

# Deploy web app with Azure app service
#
# Required globals:
#   AZURE_APP_ID
#   AZURE_PASSWORD
#   AZURE_TENANT_ID
#   AZURE_APP_NAME
#   AZURE_RESOURCE_GROUP
#   ZIP_FILE
#
# Optional globals:
#   SLOT
#   EXTRA_ARGS
#   DEBUG

source "$(dirname "$0")/common.sh"

enable_debug

# mandatory parameters
AZURE_APP_ID=${AZURE_APP_ID:?'AZURE_APP_ID variable missing.'}
AZURE_PASSWORD=${AZURE_PASSWORD:?'AZURE_PASSWORD variable missing.'}
AZURE_TENANT_ID=${AZURE_TENANT_ID:?'AZURE_TENANT_ID variable missing.'}
AZURE_APP_NAME=${AZURE_APP_NAME:?'AZURE_APP_NAME variable missing.'}
AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP:?'AZURE_RESOURCE_GROUP variable missing.'}
ZIP_FILE=${ZIP_FILE:?'ZIP_FILE variable missing.'}

debug AZURE_APP_ID: "${AZURE_APP_ID}"
debug AZURE_TENANT_ID: "${AZURE_TENANT_ID}"
debug AZURE_RESOURCE_GROUP: "${AZURE_RESOURCE_GROUP}"
debug AZURE_APP_NAME: "${AZURE_APP_NAME}"
debug ZIP_FILE: "${ZIP_FILE}"

# auth
AUTH_ARGS_STRING="--username ${AZURE_APP_ID} --password ${AZURE_PASSWORD} --tenant ${AZURE_TENANT_ID}"

if [[ "${DEBUG}" == "true" ]]; then
  AUTH_ARGS_STRING="${AUTH_ARGS_STRING} --debug"
fi

AUTH_ARGS_STRING="${AUTH_ARGS_STRING} ${EXTRA_ARGS:=""}"

debug AUTH_ARGS_STRING: "${AUTH_ARGS_STRING}"

info "Signing in..."

run az login --service-principal ${AUTH_ARGS_STRING}

# deployment
ARGS_STRING="--resource-group ${AZURE_RESOURCE_GROUP} --name ${AZURE_APP_NAME} --src ${ZIP_FILE}"

if [[ ! -z "${SLOT}" ]]; then
  ARGS_STRING="${ARGS_STRING} --slot ${SLOT}"
fi

if [[ "${DEBUG}" == "true" ]]; then
  ARGS_STRING="${ARGS_STRING} --debug"
fi

ARGS_STRING="${ARGS_STRING} ${EXTRA_ARGS:=""}"

debug ARGS_STRING: "${ARGS_STRING}"

info "Starting deployment to Azure app service..."

run az webapp deployment source config-zip ${ARGS_STRING}

WEBAPP_URL=$(az webapp deployment list-publishing-profiles -n "${AZURE_APP_NAME}" -g "${AZURE_RESOURCE_GROUP}" --query '[0].destinationAppUrl' -o tsv)
info "Web App URL: ${WEBAPP_URL}"

if [ "${status}" -eq 0 ]; then
  success "Deployment successful."
else
  fail "Deployment failed."
fi
