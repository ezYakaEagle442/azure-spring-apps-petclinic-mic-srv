// Bicep Templaytes availables at https://github.com/Azure/bicep/tree/main/docs/examples/2

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#uniquestring
// uniqueString: You provide parameter values that limit the scope of uniqueness for the result. You can specify whether the name is unique down to subscription, resource group, or deployment.
// The returned value isn't a random string, but rather the result of a hash function. The returned value is 13 characters long. It isn't globally unique

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#guid
//guid function: Returns a string value containing 36 characters, isn't globally unique
// Unique scoped to deployment for a resource group
// param appName string = 'demo${guid(resourceGroup().id, deployment().name)}'

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#newguid
// Returns a string value containing 36 characters in the format of a globally unique identifier. 
// /!\ This function can only be used in the default value for a parameter.

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-date#utcnow
// You can only use this function within an expression for the default value of a parameter.
@maxLength(20)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'petclinic${uniqueString(resourceGroup().id)}'

param location string = 'westeurope'
// param rgName string = 'rg-${appName}'

@maxLength(24)
@description('The name of the KV, must be UNIQUE.  A vault name must be between 3-24 alphanumeric characters.')
param kvName string // = 'kv-${appName}'

@description('The name of the KV RG')
param kvRGName string

@description('Is KV Network access public ?')
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'enabled'

@description('The KV SKU name')
@allowed([
  'premium'
  'standard'
])
param kvSkuName string = 'standard'

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

@description('Should the service be deployed to a Corporate VNet ?')
param deployToVNet bool = false

@description('The Log Analytics workspace name used by Azure Spring Apps instance')
param logAnalyticsWorkspaceName string = 'log-${appName}'

param appInsightsName string = 'appi-${appName}'


@description('The Azure Spring Apps instance name')
param azureSpringAppsInstanceName string = 'asa-${appName}'

@description('The Storage Account name')
param azureStorageName string = 'stasa${appName}'

@description('The BLOB Storage service name')
param azureBlobServiceName string = 'default'

@description('The BLOB Storage Container name')
param blobContainerName string = '${appName}-blob'

@description('the GitHub Runner Service Principal Id')
param ghRunnerSpnPrincipalId string

// https://learn.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?tabs=bicep
resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
}
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.id

// https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/components?tabs=bicep
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    // ImmediatePurgeDataOn30Days: true // "ImmediatePurgeDataOn30Days cannot be set on current api-version"
    IngestionMode: 'LogAnalytics' // Cannot set ApplicationInsightsWithDiagnosticSettings as IngestionMode on consolidated application 
    Request_Source: 'rest'
    RetentionInDays: 30
    SamplingPercentage: 20
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}
output appInsightsResourceId string = appInsights.id
output appInsightsAppId string = appInsights.properties.AppId
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString


module identities './modules/asa/identity.bicep' = {
  name: 'asa-identities'
  params: {
    location: location
  }
}


// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scope-extension-resources
module roleAssignments './modules/asa/roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    kvName: kvName
    kvRGName: kvRGName
    kvRoleType: 'KeyVaultSecretsUser'
    asaCustomersServicePrincipalId: identities.outputs.customersServicePrincipalId
    asaVetsServicePrincipalId: identities.outputs.vetsServicePrincipalId
    asaVisitsServicePrincipalId: identities.outputs.visitsServicePrincipalId
  }
  dependsOn: [
    identities
  ] 
}

module storage './modules/asa/storage.bicep' = {
  name: 'storage'
  params: {
    blobContainerName: blobContainerName
    azureBlobServiceName: azureBlobServiceName
    azureStorageName: azureStorageName
    azureSpringAppsInstanceName: azureSpringAppsInstanceName
    ghRunnerSpnPrincipalId: ghRunnerSpnPrincipalId
  }
  dependsOn: [
    identities
  ] 
}
