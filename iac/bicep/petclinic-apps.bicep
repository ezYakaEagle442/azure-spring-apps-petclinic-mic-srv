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

@description('The Azure Spring Apps Resource Provider ID')
param azureSpringAppsRp string

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

param vnetName string = 'vnet-azure-spring-apps'

@description('Comma-separated list of IP address ranges in CIDR format. The IP ranges are reserved to host underlying Azure Spring Apps infrastructure, which should be 3 at least /16 unused IP ranges, must not overlap with any Subnet IP ranges. Addresses 10.2.0.0/16 matching the format *.*.*.0 or *.*.*.255 are reserved and cannot be used')
param serviceCidr string = '10.0.0.1/16,10.1.0.1/16,10.2.0.1/16' // Addresses 10.2.0.0/16 matching the format *.*.*.0 or *.*.*.255 are reserved and cannot be used
param serviceRuntimeSubnetName string = 'snet-svc-run'
param appSubnetName string = 'snet-app'
param zoneRedundant bool = false

@description('The resource group where all network resources for apps will be created in')
param appNetworkResourceGroup string 

@description('The resource group where all network resources for Azure Spring Apps service runtime will be created in')
param serviceRuntimeNetworkResourceGroup string 

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

@description('Allow client workstation to MySQL for local Dev/Test only')
param clientIPAddress string

@description('Should a MySQL Firewall be set to allow client workstation for local Dev/Test only')
param setFwRuleClient bool = false

@description('Allow Azure Spring Apps from Apps subnet to access MySQL DB')
param startIpAddress string = '10.42.1.0'

@description('Allow Azure Spring Apps from Apps subnet to access MySQL DB')
param endIpAddress string = '10.42.1.15'

/*
module rg 'rg.bicep' = {
  name: 'rg-bicep-${appName}'
  scope: subscription()
  params: {
    rgName: rgName
    location: location
  }
}
*/


resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = if (deployToVNet) {
  name: vnetName
}

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: kvName
}

module azurespringapps './modules/asa/asa.bicep' = {
  name: 'azurespringapps'
  // scope: resourceGroup(rg.name)
  params: {
    appName: appName
    location: location
    azureSpringAppsInstanceName: azureSpringAppsInstanceName
    azureSpringAppsSkuCapacity: azureSpringAppsSkuCapacity
    azureSpringAppsSkuName: azureSpringAppsSkuName
    azureSpringAppsTier: azureSpringAppsTier
    appNetworkResourceGroup: appNetworkResourceGroup
    appSubnetId: vnet.properties.subnets[1].id
    monitoringSettingsName: monitoringSettingsName
    serviceRuntimeNetworkResourceGroup: serviceRuntimeNetworkResourceGroup
    serviceRuntimeSubnetId: vnet.properties.subnets[0].id
    serviceCidr: serviceCidr
    configServerName: configServerName
    gitConfigURI: gitConfigURI
    serviceRegistryName: serviceRegistryName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
    appInsightsDiagnosticSettingsName: appInsightsDiagnosticSettingsName
    zoneRedundant: zoneRedundant
    serverName: kv.getSecret('MYSQL-SERVER-NAME')
    administratorLogin: kv.getSecret('SPRING-DATASOURCE-USERNAME')
    administratorLoginPassword: kv.getSecret('SPRING-DATASOURCE-PASSWORD')   
    clientIPAddress: clientIPAddress
    startIpAddress: startIpAddress
    endIpAddress: endIpAddress
    deployToVNet: deployToVNet
    setFwRuleClient: setFwRuleClient
  }
  dependsOn: [
    roleAssignments
  ]
}

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scope-extension-resources
module roleAssignments './modules/asa/roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    vnetName: vnetName
    subnetName: appSubnetName
    kvName: kvName
    kvRGName: kvRGName
    networkRoleType: 'Owner'
    kvRoleType: 'KeyVaultReader'
    azureSpringAppsRp: azureSpringAppsRp
  }
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

module KeyVaultAccessPolicies './modules/kv/kv_policies.bicep'= {
  name: 'KeyVaultAccessPolicies'
  scope: resourceGroup(kvRGName)
  params: {
    appName: appName
    kvName: kvName
    tenantId: tenantId
    accessPoliciesObject: accessPoliciesObject
  } 
}
