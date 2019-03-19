# Bitbucket Pipelines Pipe: Azure Web Apps Deploy

Deploys an application to [Azure Web Apps](https://azure.microsoft.com/en-gb/services/app-service/web). Azure Web Apps enables you to build and host web applications in the programming language of your choice without managing infrastructure. It offers auto-scaling and high availability.

## YAML Definition

Add the following snippet to the script section of your `bitbucket-pipelines.yml` file:

```yaml
script:
    - pipe: microsoft/azure-web-apps-deploy:1.0.1
      variables:
        AZURE_APP_ID: $AZURE_APP_ID
        AZURE_PASSWORD: $AZURE_PASSWORD
        AZURE_TENANT_ID: $AZURE_TENANT_ID
        AZURE_RESOURCE_GROUP: '<string>'
        AZURE_APP_NAME: '<string>'
        ZIP_FILE: '<string>'
        # SLOT: '<string>' # Optional.
        # DEBUG: '<boolean>' # Optional.
```

## Variables

| Variable              | Usage                                                       |
| ------------------------ | ----------------------------------------------------------- |
| AZURE_APP_ID (*)         | The app ID, URL or name associated with the service principal required for login. |
| AZURE_PASSWORD (*)       | Credentials like the service principal password, or path to certificate required for login. |
| AZURE_TENANT_ID  (*)     | The AAD tenant required for login with the service principal. |
| AZURE_RESOURCE_GROUP (*) | Name of the resource group that the app service is deployed to.  |
| AZURE_APP_NAME (*)       | Name of the web app you want to deploy. |
| ZIP_FILE (*)             | Zip file path for deployment e.g. app.zip |
| SLOT                     | Name of the slot. Defaults to the production slot if not specified. |
| DEBUG                    | Turn on extra debug information. Default: `false`. |

_(*) = required variable._

## Prerequisites

You will need to configure required Azure resources before running the pipe. The easiest way to do it is by using the Azure cli. You can either [install the Azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) on your local machine, or you can use the [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) provided by the Azure Portal in a browser.

### Service principal

You will need a service principal with sufficient access to create an Azure App Service instance, or update an existing App Service. To create a service principal using the Azure CLI, execute the following command in a bash shell:

```sh
az ad sp create-for-rbac --name MyServicePrincipal
```

Refer to the following documentation for more detail:

* [Create an Azure service principal with Azure CLI](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)

### App Service

Using the service principal credentials obtained in the previous step, you can use the following commands to create an Azure App Service instance in a Bash shell:

```bash
az login --service-principal --username ${AZURE_APP_ID}  --password ${AZURE_PASSWORD} --tenant ${AZURE_TENANT_ID}

az group create --name ${AZURE_RESOURCE_GROUP} --location australiaeast

az appservice plan create --name ${AZURE_APP_NAME} --resource-group ${AZURE_RESOURCE_GROUP} --sku FREE

az webapp create --name ${AZURE_APP_NAME} --resource-group ${AZURE_RESOURCE_GROUP} --plan $AZURE_APP_NAME
```

Refer to the following documentation for more detail:

* [Create an App Service app and deploy code from a local Git repository using Azure CLI](https://docs.microsoft.com/en-us/azure/app-service/scripts/cli-deploy-local-git)

## Examples

### Basic example

```yaml
script:
  - pipe: microsoft/azure-web-apps-deploy:1.0.1
    variables:
      AZURE_APP_ID: $AZURE_APP_ID
      AZURE_PASSWORD: $AZURE_PASSWORD
      AZURE_TENANT_ID: $AZURE_TENANT_ID
      AZURE_RESOURCE_GROUP: $AZURE_RESOURCE_GROUP
      AZURE_APP_NAME: 'my-site'
      ZIP_FILE: 'my-package.zip'
```

### Advanced example

```yaml
script:
  - pipe: microsoft/azure-web-apps-deploy:1.0.1
    variables:
      AZURE_APP_ID: $AZURE_APP_ID
      AZURE_PASSWORD: $AZURE_PASSWORD
      AZURE_TENANT_ID: $AZURE_TENANT_ID
      AZURE_RESOURCE_GROUP: $AZURE_RESOURCE_GROUP
      AZURE_APP_NAME: 'my-site'
      ZIP_FILE: 'my-package.zip'
      SLOT: 'staging'
```

## Support

If you’d like help with this pipe, or you have an issue or feature request, [let us know on community][community].

If you’re reporting an issue, please include:

* the version of the pipe
* relevant logs and error messages
* steps to reproduce

[community]: https://community.atlassian.com/t5/forums/postpage/choose-node/true/interaction-style/qanda?add-tags=bitbucket-pipelines,pipes,azure
