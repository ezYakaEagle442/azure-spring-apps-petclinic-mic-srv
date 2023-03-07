// https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

@description('The Identity location')
param location string = resourceGroup().location

@description('A UNIQUE name')
@maxLength(23)
param appName string = 'petcliasa${uniqueString(deployment().name)}'

@description('The Identity Tags. See https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=bicep#apply-an-object')
param tags object = {
  Environment: 'Dev'
  Dept: 'IT'
  Scope: 'EU'
  CostCenter: '442'
  Owner: 'Petclinic'
}

///////////////////////////////////
// Resource names

// id-<app or service name>-<environment>-<region name>-<###>
// ex: id-appcn-keda-prod-eastus2-001

@description('The config-server Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param configServerAppIdentityName string = 'id-asa-${appName}-petclinic-config-server-dev-${location}-101'

@description('The api-gateway Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param apiGatewayAppIdentityName string = 'id-asa-${appName}-petclinic-api-gateway-dev-${location}-101'

@description('The UI for ASA-E Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param uiAppIdentityName string = 'id-asa-${appName}-petclinic-ui-dev-${location}-101'

@description('The customers-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param customersServiceAppIdentityName string = 'id-asa-${appName}-petclinic-customers-service-dev-${location}-101'

@description('The vets-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param vetsServiceAppIdentityName string = 'id-asa-${appName}-petclinic-vets-service-dev-${location}-101'

@description('The visits-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param visitsServiceAppIdentityName string = 'id-asa-${appName}-petclinic-visits-service-dev-${location}-101'

///////////////////////////////////
// New resources

// https://learn.microsoft.com/en-us/azure/templates/microsoft.managedidentity/userassignedidentities?pivots=deployment-language-bicep
resource configServerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: configServerAppIdentityName
  location: location
  tags: tags
}

output configServerIdentityId string = configServerIdentity.id
output configServerIdentityName string = configServerIdentity.name
output configServerPrincipalId string = configServerIdentity.properties.principalId

resource apiGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: apiGatewayAppIdentityName
  location: location
  tags: tags
}

output apiGatewayIdentityId string = apiGatewayIdentity.id
output apiGatewayIdentityName string = apiGatewayIdentity.name
output apiGatewayPrincipalId string = apiGatewayIdentity.properties.principalId

resource uiAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: uiAppIdentityName
  location: location
  tags: tags
}

output uiAppIdentityId string = uiAppIdentity.id
output uiAppIdentityName string = uiAppIdentity.name
output uiAppIdentityPrincipalId string = uiAppIdentity.properties.principalId

resource customersServicedentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: customersServiceAppIdentityName
  location: location
  tags: tags
}

output customersServiceIdentityId string = customersServicedentity.id
output customersServiceIdentityName string = customersServicedentity.name
output customersServicePrincipalId string = customersServicedentity.properties.principalId

resource vetsServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: vetsServiceAppIdentityName
  location: location
  tags: tags
}

output vetsServiceIdentityId string = vetsServiceIdentity.id
output vetsServiceIdentityName string = vetsServiceIdentity.name
output vetsServicePrincipalId string = vetsServiceIdentity.properties.principalId

resource visitsServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: visitsServiceAppIdentityName
  location: location
  tags: tags
}

output visitsServiceIdentityId string = visitsServiceIdentity.id
output visitsServiceIdentityName string = visitsServiceIdentity.name
output visitsServicePrincipalId string = visitsServiceIdentity.properties.principalId
