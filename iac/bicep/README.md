# Azure Spring Apps

## Enterprise Tier

Read the [pre-req doc](https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-bicep?tabs=azure-spring-apps-standard#prerequisites)

If you're deploying Azure Spring Apps Enterprise tier for the first time in the target subscription, use the following commands to register the provider and accept the legal terms and privacy statements for the Enterprise tier :
```sh
az provider register --namespace Microsoft.SaaS
az term accept \
     --publisher vmware-inc \
     --product azure-spring-cloud-vmware-tanzu-2 \
     --plan tanzu-asc-ent-mtr
```

[https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-configure-single-sign-on-enterprise#create-and-configure-an-application-registration-with-azure-active-directory](https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-configure-single-sign-on-enterprise#create-and-configure-an-application-registration-with-azure-active-directory)
```sh
SSO_APP_NAME="asa-sso-petclinic"

# Use the following command to create an application registration with AAD
az ad app create --display-name ${SSO_APP_NAME} > ad.json

# Use the following command to retrieve the application ID and collect the client secret:
SSO_APPLICATION_ID=$(cat ad.json | jq -r '.appId')
az ad app credential reset --id ${SSO_APPLICATION_ID} --append > sso.json

# Use the following command to assign a Service Principal to the application registration:
az ad sp create --id ${SSO_APPLICATION_ID}

# retrieve the application's Client ID. 
SSO_APPLICATION_CLIENT_ID=$(cat sso.json | jq -r '.appId')

# retrieve the application's Client Secret. 
SSO_APPLICATION_CLIENT_PWD=$(cat sso.json | jq -r '.password')

# retrieve the Issuer URI
TENANT_ID=$(cat sso.json | jq -r '.tenant')
SSO_APPLICATION_ISSUER_URI="https://login.microsoftonline.com/${TENANT_ID}/v2.0"
echo $SSO_APPLICATION_ISSUER_URI

# Retrieve the JWK URI from the output of the following command. The Identity Service application will use the public JSON Web Keys (JWK) to verify JSON Web Tokens (JWT) issued by Active Directory.
TENANT_ID=$(cat sso.json | jq -r '.tenant')
SSO_APPLICATION_ISSUER_URI="https://login.microsoftonline.com/${TENANT_ID}/discovery/v2.0/keys"
echo $SSO_APPLICATION_ISSUER_URI

```


## Standard Tier

To use [Pipelines with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions?tabs=CLI) see [../../../README.md](../../README.md)
```sh

# See https://docs.microsoft.com/cli/azure/microsoft-graph-migration
# https://docs.microsoft.com/cli/azure/query-azure-cli
# The one below returns 0 ID because of Tenant mismatch
tenantId=$(az account show --query tenantId -o tsv)
azureSpringAppsObjectId="$(az ad sp list --filter "displayName eq 'Azure Spring Cloud Resource Provider'" --query "[?appDisplayName=='Azure Spring Cloud Resource Provider']" --query "[?appOwnerTenantId=='$tenantId'].id" -o tsv | head -1)"

# This query returns 1 and only 1 Id: d2531223-68f9-459e-b225-5592f90d145e
azureSpringAppsRpObjectId="$(az ad sp list --filter "displayName eq 'Azure Spring Cloud Resource Provider'" --query "[?appDisplayName=='Azure Spring Cloud Resource Provider'].id" -o tsv | head -1)"

az ad sp list --filter "displayname eq 'Azure Spring Cloud Resource Provider'" --query "[?appDisplayName=='Azure Spring Cloud Resource Provider'].id" -o tsv |
while IFS= read -r line
do
    echo "$line" &
done

# This query returns 1 and only 1 Id: e8de9221-a19c-4c81-b814-fd37c6caf9d2
azureSpringAppsRpAppId="$(az ad sp list --filter "displayname eq 'Azure Spring Cloud Resource Provider'" --query "[?appDisplayName=='Azure Spring Cloud Resource Provider'].appId" -o tsv | head -1)"
```

In the [Bicep parameter file](./parameters.json) :
- set the above value $azureSpringAppsRpAppIdin to the field "azureSpringAppsRp"
- set your laptop/dev station IP adress to the field "clientIPAddress"


```sh
# Check, choose a Region with AZ : https://docs.microsoft.com/en-us/azure/availability-zones/az-overview#azure-regions-with-availability-zones
az group create --name rg-iac-kv21 --location westeurope
az group create --name rg-iac-asa-petclinic-mic-srv --location westeurope

az deployment group create --name iac-101-kv -f ./modules/kv/kv.bicep -g rg-iac-kv \
    --parameters @./modules/kv/parameters-kv.json

az deployment group create --name iac-101-pre-req -f ./pre-req.bicep -g rg-iac-asa-petclinic-mic-srv \
    --parameters @./parameters.json --debug # --what-if to test like a dry-run

az deployment group create --name iac-101-asa -f ./petclinic-apps.bicep -g rg-iac-asa-petclinic-mic-srv \
    --parameters @./parameters.json --debug # --what-if to test like a dry-run    
```

Note: you can Run a Bicep script to debug and output the results to Azure Storage, see the [doc](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-bicep#sample-bicep-files)

