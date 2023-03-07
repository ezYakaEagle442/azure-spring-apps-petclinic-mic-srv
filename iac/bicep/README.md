# Azure Spring Apps


FYI, if you want to check the services available per locations :
```sh
az provider list --output table

az provider show -n Microsoft.AppPlatform --query "resourceTypes[?resourceType == 'Spring']".locations | jq '.[0]' | jq 'length'

az provider show -n Microsoft.ContainerService --query "resourceTypes[?resourceType == 'managedClusters']".locations | jq '.[0]' | jq 'length'
az provider show -n Microsoft.RedHatOpenShift --query "resourceTypes[?resourceType == 'OpenShiftClusters']".locations | jq '.[0]' | jq 'length’

az provider show -n Microsoft.App --query "resourceTypes[?resourceType == 'managedEnvironments']".locations | jq '.[0]' | jq 'length’
az provider show -n Microsoft.App --query "resourceTypes[?resourceType == 'connectedEnvironments']".locations | jq '.[0]' | jq 'length'

```

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

The steps below will be implemented in the [workflow](./.github/workflows/deploy-iac-enterprise-tier.yml)
az ad sp list --filter will fails with "ERROR: Insufficient privileges to complete the operation"

see on:
- [stackoverflow](https://stackoverflow.com/questions/64333681/insufficient-privileges-to-complete-the-operation-with-listing-service-principal)
- [MS learn](https://learn.microsoft.com/en-us/answers/questions/899080/insufficient-privileges-to-complete-the-operation-3.html)

Giving the GH Runner SP the 'Owner' role is not enough. You have the give it the '[Directory Readers](https://learn.microsoft.com/en-us/azure/active-directory/roles/permissions-reference)' role. 

Read [https://lnx.azurewebsites.net/directory-roles-for-azure-ad-service-principal/](https://lnx.azurewebsites.net/directory-roles-for-azure-ad-service-principal/)

This is not possible using the Azure CLI or Portal though. 
You have to use the [Azure AD Graph API](https://learn.microsoft.com/en-us/graph/graph-explorer/graph-explorer-overview), to understand how to get an Access Token to call the API read [https://learn.microsoft.com/en-us/graph/auth/auth-concepts](https://learn.microsoft.com/en-us/graph/auth/auth-concepts) and [https://learn.microsoft.com/en-us/graph/auth-v2-service#token-request](https://learn.microsoft.com/en-us/graph/auth-v2-service#token-request).

You can get the Full Directory Permissions Reference [here](https://learn.microsoft.com/en-us/graph/permissions-reference#directory-permissions)

The easiest way to do this is using [https://graphexplorer.azurewebsites.net](https://graphexplorer.azurewebsites.net) :

GET
https://graph.windows.net/free-media.eu/directoryRoles?api-version=1.6
(you need to change free-media.eu to your tenant name, ex for MS FTE: https://graph.windows.net/microsoft.com/directoryRoles)

other ex: 
https://graph.windows.net/EnvZzzz424242.onmicrosoft.com/$metadata#directoryObjects/Microsoft.DirectoryServices.DirectoryRole  
https://graph.windows.net/EnvZzzz424242.onmicrosoft.com/directoryRoles

Workround see [https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-directory-readers-role-tutorial?view=azuresql](https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-directory-readers-role-tutorial?view=azuresql) : 

create a Group 'ASA-Directory-Readers' having 'Directory Readers' role ,then add the SP to that group. (to be tested)

```sh
SPN_APP_NAME="gha_asa_run"

SPN_APP_ID=$(az ad sp list --all --query "[?appDisplayName=='${SPN_APP_NAME}'].{appId:appId}" --output tsv)
# use the one that works
SPN_APP_ID=$(az ad sp list --show-mine --query "[?appDisplayName=='${SPN_APP_NAME}'].{id:appId}" --output tsv)

TENANT_ID=$(az ad sp list --all --query "[?appDisplayName=='${SPN_APP_NAME}'].{t:appOwnerOrganizationId}" --output tsv)
# use the one that works
TENANT_ID=$(az ad sp list --show-mine --query "[?appDisplayName=='${SPN_APP_NAME}'].{t:appOwnerOrganizationId}" --output tsv)

# /!\ In Bicep : RBAC ==> GH Runner SPN must have "Storage Blob Data Contributor" Role on the storage Account"
# /!\ The SPN Id is NOT the App Registration Object ID, but the Enterprise Registration Object ID"
SPN_ID=$(az ad sp show --id $SPN_APP_ID --query id -o tsv)


# Giving the GH Runner SP the 'Owner' role is not enough to run 'az ad sp list --filter'. You have the give it the 'Directory Readers' role
# https://learn.microsoft.com/en-us/azure/active-directory/roles/permissions-reference  


AAD_DIR_READERS="Directory Readers"
az ad group create --display-name "$AAD_DIR_READERS" --mail-nickname aadreadersgroup --description "Directory Readers for Azure Spring Apps - Enetrprise SSO Config"
aad_dir_readers_group_object_id=$(az ad group show -g "$AAD_DIR_READERS" --query id -o tsv)
echo "aad_dir_readers_group_object_id" : $aad_dir_readers_group_object_id

# The object ID of the User, or service principal.
USR_ID=$(az account show --query user.name -o tsv)
USR_SPN_ID=$(az ad user show --id ${USR_ID} --query id -o tsv)
az ad group member add --member-id $USR_SPN_ID -g $aad_dir_readers_group_object_id
az ad group member add --member-id $SPN_ID -g $aad_dir_readers_group_object_id


# Directory Readers: 88d8e3e3-8f55-4a1e-953a-9b9898b8876b
directoryReadersRoleTemplateId=88d8e3e3-8f55-4a1e-953a-9b9898b8876b

#az role assignment create --assignee $SPN_APP_ID --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_APP} --role 88d8e3e3-8f55-4a1e-953a-9b9898b8876b 

# https://learn.microsoft.com/en-us/graph/permissions-reference#directory-permissions
# Directory.Read.All	Delegated	06da0dbc-49e2-44d2-8312-53f166ab848a
# https://learn.microsoft.com/en-us/troubleshoot/azure/active-directory/verify-first-party-apps-sign-in#application-ids-of-commonly-used-microsoft-applications
az ad app permission add --api 00000003-0000-0000-c000-000000000000  --api-permissions 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope --id $SPN_APP_ID
```

```console
Invoking `az ad app permission grant --id <GUID of you $SPN_APP_ID 42424242424242424242442> --api 00000003-0000-0000-c000-000000000000 --scope`
```

```sh
az ad app permission grant --id ${SPN_APP_ID} --api 00000003-0000-0000-c000-000000000000 --scope --id ${SPN_APP_ID}
az ad app permission admin-consent --id ${SPN_APP_ID}

SPN_PWD=XXX424242xxx # set the Secret of you SPN

# https://learn.microsoft.com/en-us/graph/auth-v2-service#token-request
# https://github.com/microsoftgraph/microsoft-graph-docs/issues/20272
access_token=$(curl -X POST -d \
"client_id=${SPN_APP_ID}%2F\.default&client_secret=${SPN_PWD} \
&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default&grant_type=client_credentials" \
https://login.microsoftonline.com/{$TENANT_ID}/oauth2/v2.0/token \
| jq -r .access_token) 

set -euo pipefail
#access_token=$(az account get-access-token --query accessToken -o tsv)

# https://learn.microsoft.com/en-us/graph/use-the-api#version
# https://developer.microsoft.com/en-us/graph/graph-explorer
curl -X GET -H "Authorization: Bearer $access_token" -H "Accept:application/json" -H "Content-Type: application/json" \
https://graph.microsoft.com/v1.0/EnvZzzz424242.onmicrosoft.com/directoryRoles


az ad sp list --filter "displayName eq '$SPN_APP_NAME'" --query "[?appDisplayName=='$SPN_APP_NAME'].{id:appId}" -o tsv

```


```sh
SSO_APP_NAME="asa-sso-petclinic"

# Use the following command to create an application registration with AAD
az ad app create --display-name ${SSO_APP_NAME} > aad_sso_app.json

# Use the following command to retrieve the application ID and collect the client secret:
SSO_APPLICATION_ID=$(cat aad_sso_app.json | jq -r '.appId')
az ad app credential reset --id ${SSO_APPLICATION_ID} --append > aad_sso_app_creds.json

# Use the following command to assign a Service Principal to the application registration:
az ad sp create --id ${SSO_APPLICATION_ID}

# retrieve the application's Client ID.
SSO_APPLICATION_CLIENT_ID=$(cat aad_sso_app_creds.json | jq -r '.appId')

# retrieve the application's Client Secret. 
SSO_APPLICATION_CLIENT_PWD=$(cat aad_sso_app_creds.json | jq -r '.password')

# retrieve the Issuer URI
TENANT_ID=$(cat aad_sso_app_creds.json | jq -r '.tenant')
SSO_APPLICATION_ISSUER_URI="https://login.microsoftonline.com/${TENANT_ID}/v2.0"
echo $SSO_APPLICATION_ISSUER_URI

# Retrieve the JWK URI from the output of the following command. The Identity Service application will use the public JSON Web Keys (JWK) to verify JSON Web Tokens (JWT) issued by Active Directory.
SSO_APPLICATION_JWK_SET_URI="https://login.microsoftonline.com/${TENANT_ID}/discovery/v2.0/keys"
echo $SSO_APPLICATION_JWK_SET_URI

# https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-configure-single-sign-on-enterprise#create-and-configure-an-application-registration-with-azure-active-directory
APPLICATION_ID=$(cat aad_sso_app.json | jq -r '.appId')
echo "APPLICATION_ID=$APPLICATION_ID"

APPLICATION_ID=$(az ad sp list --filter "displayName eq '${SSO_APP_NAME}'" --query "[?appDisplayName=='${SSO_APP_NAME}'].{id:appId}" -o tsv)
echo "APPLICATION_ID=$APPLICATION_ID"

# add the GitHub Runner App as one Owner of the AAD SSO app 
az ad app owner list --id ${APPLICATION_ID} -o table

az ad app show --id $SPN_APP_ID 
az ad app owner add --id ${APPLICATION_ID} --owner-object-id $SPN_ID

az ad app owner list --id ${APPLICATION_ID} -o table


# https://learn.microsoft.com/en-us/graph/permissions-reference#directory-permissions
# Application.ReadWrite.All	Delegated	bdfbf15f-ee85-4955-8675-146e8e5296b5
#                           Application 1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9	
# https://learn.microsoft.com/en-us/troubleshoot/azure/active-directory/verify-first-party-apps-sign-in#application-ids-of-commonly-used-microsoft-applications
az ad app permission add --api 00000003-0000-0000-c000-000000000000  --api-permissions bdfbf15f-ee85-4955-8675-146e8e5296b5=Scope --id $SPN_APP_ID
```

```console
Invoking `az ad app permission grant --id <GUID of you $SPN_APP_ID 42424242424242424242442> --api 00000003-0000-0000-c000-000000000000 --scope`
```

```sh
az ad app permission grant --id ${SPN_APP_ID} --api 00000003-0000-0000-c000-000000000000 --scope --id ${SSO_APPLICATION_CLIENT_ID}
az ad app permission admin-consent --id ${SPN_APP_ID}

GATEWAY_URL=$(az spring gateway show \
    --resource-group <resource-group-name> \
    --service <Azure-Spring-Apps-service-instance-name> | jq -r '.properties.url')

PORTAL_URL=$(az spring api-portal show \
    --resource-group <resource-group-name> \
    --service <Azure-Spring-Apps-service-instance-name> | jq -r '.properties.url')

az ad app update \
    --id ${APPLICATION_ID} \
    --web-redirect-uris "https://${GATEWAY_URL}/login/oauth2/code/sso" "https://${PORTAL_URL}/oauth2-redirect.html" "https://${PORTAL_URL}/login/oauth2/code/sso"

```
Add the App secrets  to your GH repo settings / Actions / secrets / Actions secrets / New Repository secrets / Add , ex: [https://github.com/ezYakaEagle442/azure-spring-apps-petclinic-mic-srv/settings/secrets/actions](https://github.com/ezYakaEagle442/azure-spring-apps-petclinic-mic-srv/settings/secrets/actions):

Secret Name	| Secret Value example
-------------:|:-------:
API_PORTAL_SSO_CLIENT_ID | PUT HERE THE VALUE OF $SSO_APPLICATION_ID 
API_PORTAL_SSO_CLIENT_SECRET | SSO_APPLICATION_CLIENT_PWD
SSO_APPLICATION_ISSUER_URI |  PUT HERE THE VALUE OF $SSO_APPLICATION_ISSUER_URI 
SSO_APPLICATION_JWK_SET_URI |  |  PUT HERE THE VALUE OF $SSO_APPLICATION_JWK_SET_URI

Finally regarding RBAC, you ahve to create a custom Role and add permission 'Other: List environment variables secret for Microsoft Azure Spring Apps Spring Cloud Gateway' to be able to view the Spring Cloud Gateway from he Azure Portal

Check :
- [https://github.com/Azure/Azure-Spring-Apps/issues/37](https://github.com/Azure/Azure-Spring-Apps/issues/37)
- [https://learn.microsoft.com/en-us/azure/spring-apps/how-to-permissions?tabs=Azure-portal](https://learn.microsoft.com/en-us/azure/spring-apps/how-to-permissions?tabs=Azure-portal)

## Standard Tier

To use [Pipelines with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions?tabs=CLI) see [../../../README.md](../../README.md)
```sh

# See https://docs.microsoft.com/cli/azure/microsoft-graph-migration
# https://docs.microsoft.com/cli/azure/query-azure-cli
# The one below returns 0 ID because of Tenant mismatch
tenantId=$(az account show --query tenantId -o tsv)
azureSpringAppsObjectId="$(az ad sp list --filter "displayName eq 'Azure Spring Cloud Resource Provider'" --query "[?appDisplayName=='Azure Spring Cloud Resource Provider']" --query "[?appOwnerTenantId=='$tenantId'].id" -o tsv | head -1)"

# This query returns 1 and only 1 Id:
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

