@description('A UNIQUE name')
@maxLength(23)
param appName string = 'petcliasa${uniqueString(resourceGroup().id, subscription().id)}'

// https://docs.microsoft.com/en-us/rest/api/containerregistry/registries/check-name-availability
@description('The name of the ACR, must be UNIQUE. The name must contain only alphanumeric characters, be globally unique, and between 5 and 50 characters in length.')
param acrName string = appName

@description('The ACR location')
param location string = resourceGroup().location

// https://learn.microsoft.com/en-us/azure/templates/microsoft.containerregistry/registries?pivots=deployment-language-bicep#sku
@allowed([
  'Basic'
  'Premium'
  'Standard'
  'Classic'
])
@description('The ACR SKU, either Basic with admin user enabled, or Premium with scoped-permissions')
param acrSkuName string = 'Basic'

@description('Admin user must be enabled ONLY when acrSkuName is Basic')
param adminUserEnabled bool = true

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSkuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: adminUserEnabled // required for TAP,alternative required Premium SKU with scoped-permissions, see https://learn.microsoft.com/en-us/azure/container-registry/container-registry-repository-scoped-permissions
    dataEndpointEnabled: false // data endpoint rule is not supported for the SKU Basic
    anonymousPullEnabled: false // anonymousPullEnabled looks removed since API ⁠2021-09-01
    // VNet rule is not supported for the SKU Basic
    /*
    networkRuleSet: {
      defaultAction: 'Deny'
      
      ipRules: [
        {
          action: 'Allow'
          value: [] //  https://learn.microsoft.com/en-us/azure/container-registry/container-registry-access-selected-networks#access-from-aks
        }
      ]
      
    }*/
    //networkRuleBypassOptions: 'AzureServices'
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

output acrId string = acr.id
output acrName string = acr.name
output acrIdentity string = acr.identity.principalId
output acrType string = acr.type
output acrRegistryUrl string = acr.properties.loginServer

// outputs-should-not-contain-secrets
// output acrRegistryUsr string = acr.listCredentials().username
//output acrRegistryPwd string = acr.listCredentials().passwords[0].value

// https://learn.microsoft.com/en-us/azure/templates/microsoft.containerregistry/registries/scopemaps?pivots=deployment-language-bicep

resource scopeMap 'Microsoft.ContainerRegistry/registries/scopeMaps@2023-01-01-preview' = if(acrSkuName=='Premium') {
  name: 'acrScopeMap'
  parent: acr
  properties:{
    actions:[
      'repositories/petclinic/*/write'
      'repositories/petclinic/*/read'     
    ]
    description: 'Petclinic ACR Push scope map'
  }
}

output scopeMapId string= scopeMap.id

