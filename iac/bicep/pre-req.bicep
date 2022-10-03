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


@description('emailRecipient informed before the VM shutdown')
param autoShutdownNotificationEmail string

@description('Windows client VM deployed to the VNet. Computer name cannot be more than 15 characters long')
param windowsVMName string = 'vm-win-asa-petcli'

@description('The CIDR or source IP range. Asterisk "*" can also be used to match all source IPs. Default tags such as "VirtualNetwork", "AzureLoadBalancer" and "Internet" can also be used. If this is an ingress rule, specifies where network traffic originates from.')
param nsgRuleSourceAddressPrefix string
param nsgName string = 'nsg-asa-${appName}-app-client'
param nsgRuleName string = 'Allow RDP from local dev station'

param nicName string = 'nic-asa-${appName}-client-vm'

param vnetName string = 'vnet-azure-spring-apps'
param vnetCidr string = '10.42.0.0/21 '

@description('The name or ID of an existing subnet in "vnet" into which to deploy the Spring Apps app. Required when deploying into a Virtual Network. Smaller subnet sizes are supported, please refer: https://aka.ms/azure-spring-cloud-smaller-subnet-vnet-docs.')
param appSubnetCidr string = '10.42.1.0/28'

@description('The name or ID of an existing subnet in "vnet" into which to deploy the Spring Apps service runtime. Required when deploying into a Virtual Network.')
param serviceRuntimeSubnetCidr string = '10.42.2.0/28'

@description('Comma-separated list of IP address ranges in CIDR format. The IP ranges are reserved to host underlying Azure Spring Apps infrastructure, which should be 3 at least /16 unused IP ranges, must not overlap with any Subnet IP ranges. Addresses 10.2.0.0/16 matching the format *.*.*.0 or *.*.*.255 are reserved and cannot be used')
param serviceCidr string = '10.0.0.1/16,10.1.0.1/16,10.2.0.1/16' // Addresses 10.2.0.0/16 matching the format *.*.*.0 or *.*.*.255 are reserved and cannot be used
param serviceRuntimeSubnetName string = 'snet-svc-run'
param appSubnetName string = 'snet-app'

@description('The resource group where all network resources for apps will be created in')
param appNetworkResourceGroup string 

@description('The resource group where all network resources for Azure Spring Apps service runtime will be created in')
param serviceRuntimeNetworkResourceGroup string 

@description('The Log Analytics workspace name used by Azure Spring Apps instance')
param logAnalyticsWorkspaceName string = 'log-${appName}'

param appInsightsName string = 'appi-${appName}'

@description('The Azure Spring Apps instance name')
param azureSpringAppsInstanceName string = 'asa-${appName}'

// https://learn.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?tabs=bicep
resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
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

// https://docs.microsoft.com/en-us/azure/spring-cloud/how-to-deploy-in-azure-virtual-network?tabs=azure-portal#virtual-network-requirements
module vnetModule './modules/asa/vnet.bicep' = if (deployToVNet) {
  name: 'vnet-azurespringapps'
  // scope: resourceGroup(rg.name)
  params: {
     location: location
     vnetName: vnetName
     serviceRuntimeSubnetName: serviceRuntimeSubnetName
     serviceRuntimeSubnetCidr: serviceRuntimeSubnetCidr
     appSubnetName: appSubnetName
     appSubnetCidr: appSubnetCidr
     vnetCidr: vnetCidr
  }   
}

module dnsprivatezone './modules/asa/dns.bicep' = if (deployToVNet) {
  name: 'dns-private-zone'
  params: {
    appName: appName
    location: location
    vnetName: vnetName
    appNetworkResourceGroup: appNetworkResourceGroup
    azureSpringAppsInstanceName: azureSpringAppsInstanceName
    serviceRuntimeNetworkResourceGroup: serviceRuntimeNetworkResourceGroup
  }
  dependsOn: [
    vnetModule 
  ]     
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = if (deployToVNet) {
  name: vnetName
}

resource kvRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: kvRGName
  scope: subscription()
}

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: kvName
  scope: kvRG
}

module clientVM './modules/asa/client-vm.bicep' = if (deployToVNet) {
  name: 'vm-client'
  params: {
     location: location
     appName: appName
     vnetName: vnetName
     infrastructureSubnetID: vnet.properties.subnets[0].id
     windowsVMName: windowsVMName
     autoShutdownNotificationEmail: autoShutdownNotificationEmail
     adminUsername: kv.getSecret('VM-ADMIN-USER-NAME')
     adminPassword: kv.getSecret('VM-ADMIN-PASSWORD')
     nsgRuleSourceAddressPrefix: nsgRuleSourceAddressPrefix
     nicName: nicName
     nsgName: nsgName
     nsgRuleName: nsgRuleName
  }   
  dependsOn: [
    vnetModule
    dnsprivatezone    
  ]   
}
