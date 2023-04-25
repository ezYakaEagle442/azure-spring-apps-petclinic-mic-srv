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
@maxLength(23)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'petcliasa${uniqueString(resourceGroup().id, subscription().id)}'

param location string = resourceGroup().location
// param rgName string = 'rg-${appName}'

@maxLength(24)
@description('The name of the KV, must be UNIQUE.  A vault name must be between 3-24 alphanumeric characters.')
param kvName string // = 'kv-${appName}'

param setKVAccessPolicies bool = false

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

param zoneRedundant bool = false

@description('The Log Analytics workspace name used by Azure Spring Apps instance')
param logAnalyticsWorkspaceName string = 'log-${appName}'

param appInsightsName string = 'appi-${appName}'
param appInsightsDiagnosticSettingsName string = 'dgs-${appName}-send-logs-and-metrics-to-log-analytics'

@description('The Azure Spring Apps instance name')
param azureSpringAppsInstanceName string = 'asa-${appName}'

// Check SKU REST API : https://docs.microsoft.com/en-us/rest/api/azureSpringApps/skus/list#code-try-0
@description('The Azure Spring Apps SKU Capacity, ie Max App instances')
@minValue(8)
@maxValue(25)
param azureSpringAppsSkuCapacity int = 25

@description('The Azure Spring Apps SKU name')
@allowed([
  'BO'
  'S0'
  'E0'
])
param azureSpringAppsSkuName string = 'S0'

@allowed([
  'Basic'
  'Standard'
  'Enterprise'
])
@description('The Azure Spring Apps SKU Tier')
param azureSpringAppsTier string = 'Standard'

@description('The Azure Spring Apps Git Config Server name')
@allowed([
  'default'
])
param configServerName string = 'default'

@description('The Azure Spring Apps monitoring Settings name')
@allowed([
  'default'
])
param monitoringSettingsName string = 'default'

@description('The Azure Spring Apps Service Registry name. only "default" is supported')
@allowed([
  'default'
])
param serviceRegistryName string = 'default' // The resource name 'Azure Spring Apps Service Registry' is not valid

@description('The Azure Spring Apps Config Server Git URI (The repo must be public).')
param gitConfigURI string

@description('The MySQL server name')
param mySQLServerName string = appName

@description('The MySQL administrator Login')
param mySQLadministratorLogin  string = 'mys_adm'

module azurespringapps './modules/asa/asa.bicep' = if (azureSpringAppsTier=='Standard') {
  name: 'asa-pub'
  // scope: resourceGroup(rg.name)
  params: {
    appName: appName
    location: location
    kvName: kvName
    kvRGName: kvRGName
    azureSpringAppsInstanceName: azureSpringAppsInstanceName
    azureSpringAppsSkuCapacity: azureSpringAppsSkuCapacity
    azureSpringAppsSkuName: azureSpringAppsSkuName
    azureSpringAppsTier: azureSpringAppsTier
    monitoringSettingsName: monitoringSettingsName
    configServerName: configServerName
    gitConfigURI: gitConfigURI
    serviceRegistryName: serviceRegistryName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
    appInsightsDiagnosticSettingsName: appInsightsDiagnosticSettingsName
    zoneRedundant: zoneRedundant
    deployToVNet: deployToVNet
  }
}

resource kvRG 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: kvRGName
  scope: subscription()
}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: kvName
  scope: kvRG
}  


var  vNetRules = []
var  ipRules = azurespringapps.outputs.azureSpringAppsOutboundPubIP // /!\ has 2 IP separated from a coma, ex: 20.31.114.2,20.238.165.131

// Must allow ASA to access Existing KV
module kvsetiprules './modules/kv/kv.bicep' = {
  name: 'kv-set-iprules'
  scope: kvRG
  params: {
    appName: appName
    kvName: kvName
    location: location
    ipRules: ipRules
    vNetRules: vNetRules
  }
  dependsOn: [
    azurespringapps
  ]  
}

module mysqlPub './modules/mysql/mysql.bicep' = {
  name: 'mysqldbpub'
  params: {
    appName: appName
    location: location
    serverName: mySQLServerName
    administratorLogin: mySQLadministratorLogin
    administratorLoginPassword: kv.getSecret('SPRING-DATASOURCE-PASSWORD') 
    azureSpringAppsOutboundPubIP: ipRules // /!\ has 2 IP separated from a coma, ex: 20.31.114.2,20.238.165.131
  }
  dependsOn: [
    azurespringapps
  ]
}

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/key-vault-parameter?tabs=azure-cli
/*
The user who deploys the Bicep file must have the Microsoft.KeyVault/vaults/deploy/action permission for the scope 
of the resource group and key vault. 
The Owner and Contributor roles both grant this access.
If you created the key vault, you're the owner and have the permission.
*/


// Specifies all Apps Identities {"appName":"","appIdentity":""} wrapped into an object.')
var appsObject = { 
  apps: [
    {
    appName: 'customers-service'
    appIdentity: azurespringapps.outputs.customersServiceIdentity
    }
    {
    appName: 'vets-service'
    appIdentity: azurespringapps.outputs.vetsServiceIdentity
    }
    {
    appName: 'visits-service'
    appIdentity: azurespringapps.outputs.visitsServiceIdentity
    }
  ]
}
  
var accessPoliciesObject = {
  accessPolicies: [
    {
      objectId: azurespringapps.outputs.customersServiceIdentity
      tenantId: tenantId
      permissions: {
        secrets: [
          'get'
          'list'
        ]
      }
    }
    {
      objectId: azurespringapps.outputs.vetsServiceIdentity
      tenantId: tenantId
      permissions: {
        secrets: [
          'get'
          'list'
        ]
      }
    }
    {
      objectId:  azurespringapps.outputs.visitsServiceIdentity
      tenantId: tenantId
      permissions: {
        secrets: [
          'get'
          'list'
        ]
      }
    }
  ]
}

module KeyVaultAccessPolicies './modules/kv/kv_policies.bicep'= if (setKVAccessPolicies)  {
  name: 'KeyVaultAccessPolicies'
  scope: resourceGroup(kvRGName)
  params: {
    appName: appName
    kvName: kvName
    tenantId: tenantId
    accessPoliciesObject: accessPoliciesObject
  } 
}
