#!/usr/bin/env bats

setup() {
    DOCKER_IMAGE=${DOCKER_IMAGE:="test/azure-storage-deploy"}

    echo "Building image..."
    docker build -t ${DOCKER_IMAGE}:0.1.0 .

    # generated
    RANDOM_NUMBER=$RANDOM

    # required globals - stored in Pipelines repository variables
    AZURE_APP_ID="${AZURE_APP_ID}"
    AZURE_PASSWORD="${AZURE_PASSWORD}"
    AZURE_TENANT_ID="${AZURE_TENANT_ID}"

    # required globals - generated
    AZURE_RESOURCE_GROUP="test${RANDOM_NUMBER}"
    AZURE_APP_NAME="website${RANDOM_NUMBER}"
    ZIP_FILE="artifact-$RANDOM_NUMBER.zip"

    # optional globals - fixed
    SLOT="test"

    # locals
    HOSTING_PLAN_NAME="${AZURE_APP_NAME}plan"
    AZURE_LOCATION="CentralUS"

    echo "Clean up zip file"
    rm -f artifact-*.zip

    echo "Create zip file"
    echo $RANDOM_NUMBER > test/code/index.html
    zip -j $ZIP_FILE test/code/*

    echo "Create required Azure resources"
    az login --service-principal --username ${AZURE_APP_ID} --password ${AZURE_PASSWORD} --tenant ${AZURE_TENANT_ID}
    az group create --name ${AZURE_RESOURCE_GROUP} --location ${AZURE_LOCATION}
}

teardown() {
    echo "Clean up zip file"
    rm -f artifact-*.zip

    echo "Clean up Azure resources" 
    # Don't append --no-wait here, as we have two tests that use the same app name. 
    # The second test should only run once the first one has deleted all resources.
    az group delete --name ${AZURE_RESOURCE_GROUP} --yes
}

@test "artifact.zip file can be deployed to Azure app service" {

    az appservice plan create --name ${HOSTING_PLAN_NAME} --resource-group ${AZURE_RESOURCE_GROUP}
    az webapp create --name ${AZURE_APP_NAME} --plan ${HOSTING_PLAN_NAME} --resource-group ${AZURE_RESOURCE_GROUP} 

    echo "Run test"
    run docker run \
        -e AZURE_APP_ID="${AZURE_APP_ID}" \
        -e AZURE_PASSWORD="${AZURE_PASSWORD}" \
        -e AZURE_TENANT_ID="${AZURE_TENANT_ID}" \
        -e AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP}" \
        -e AZURE_APP_NAME="${AZURE_APP_NAME}" \
        -e ZIP_FILE="${ZIP_FILE}" \
        -v $(pwd):$(pwd) \
        -w $(pwd) \
        ${DOCKER_IMAGE}:0.1.0

    echo ${output}
    [[ "${status}" == "0" ]]

    # Verify
    run curl --silent "https://${AZURE_APP_NAME}.azurewebsites.net"

    echo ${output}
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"$RANDOM_NUMBER"* ]]
}

@test "artifact.zip file can be deployed to Azure app service slot" {

    SKU="S1" # So it supports slots
    az appservice plan create --name ${HOSTING_PLAN_NAME} --resource-group ${AZURE_RESOURCE_GROUP} --sku ${SKU}
    az webapp create --name ${AZURE_APP_NAME} --plan ${HOSTING_PLAN_NAME} --resource-group ${AZURE_RESOURCE_GROUP} 
    az webapp deployment slot create --name ${AZURE_APP_NAME} --resource-group ${AZURE_RESOURCE_GROUP} --slot ${SLOT}

    echo "Run test"
    run docker run \
        -e AZURE_APP_ID="${AZURE_APP_ID}" \
        -e AZURE_PASSWORD="${AZURE_PASSWORD}" \
        -e AZURE_TENANT_ID="${AZURE_TENANT_ID}" \
        -e AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP}" \
        -e AZURE_APP_NAME="${AZURE_APP_NAME}" \
        -e ZIP_FILE="${ZIP_FILE}" \
        -e SLOT="${SLOT}" \
        -v $(pwd):$(pwd) \
        -w $(pwd) \
        ${DOCKER_IMAGE}:0.1.0

    echo ${output}
    [[ "${status}" == "0" ]]

    # Verify
    run curl --silent "https://${AZURE_APP_NAME}-${SLOT}.azurewebsites.net"

    echo ${output}
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"$RANDOM_NUMBER"* ]]
}
