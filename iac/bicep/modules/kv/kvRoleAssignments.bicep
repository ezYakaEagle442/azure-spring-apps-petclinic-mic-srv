param vetsIdentityId string
param visitsIdentityId string
param customersIdentityId string
param configServerIdentityId string

// To get a UniqueID : https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-date#utcnow
/* You can only use this function within an expression for the default value of a parameter. 
Using this function anywhere else in a Bicep file returns an error. 
The function isn't allowed in other parts of the Bicep file because it returns a different value each time it's called.
*/
param utcValue string = utcNow()

@allowed([
  'KeyVaultAdministrator'
  'KeyVaultReader'
  'KeyVaultSecretsUser'  
])
@description('KV Built-in role to assign')
param kvRoleType string = 'KeyVaultSecretsUser'

param kvName string

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var role = {
  Owner: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
  NetworkContributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
  AcrPull: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
  KeyVaultAdministrator: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483'
  KeyVaultReader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/21090545-7ca7-4776-b22c-e363652d74d2'
  KeyVaultSecretsUser: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6'
}

// You need Key Vault Administrator permission to be able to see the Keys/Secrets/Certificates in the Azure Portal

resource vetsRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, kvRoleType , subscription().subscriptionId, 'vets', uniqueString(resourceGroup().id, deployment().name))
  scope: kv
  properties: {
    roleDefinitionId: role[kvRoleType]
    principalId: vetsIdentityId
    principalType: 'ServicePrincipal'
  }
}
output vetsRoleAssignmentUpdatedOn string = vetsRoleAssignment.properties.updatedOn
output vetsRoleAssignmentId string = vetsRoleAssignment.id
output vetsRoleAssignmentName string = vetsRoleAssignment.name

resource visitsRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, kvRoleType , subscription().subscriptionId, 'visits', uniqueString(resourceGroup().id, deployment().name))
  scope: kv
  properties: {
    roleDefinitionId: role[kvRoleType]
    principalId: visitsIdentityId
    principalType: 'ServicePrincipal'
  }
}
output visitsRoleAssignmentUpdatedOn string = visitsRoleAssignment.properties.updatedOn
output visitsRoleAssignmentId string = visitsRoleAssignment.id
output visitsRoleAssignmentName string = visitsRoleAssignment.name


resource configServerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, kvRoleType , subscription().subscriptionId, 'cfg', uniqueString(resourceGroup().id, deployment().name))
  scope: kv
  properties: {
    roleDefinitionId: role[kvRoleType]
    principalId: configServerIdentityId
    principalType: 'ServicePrincipal'
  }
}
output configServerRoleAssignmentUpdatedOn string = configServerRoleAssignment.properties.updatedOn
output configServerRoleAssignmentId string = configServerRoleAssignment.id
output configServerRoleAssignmentName string = configServerRoleAssignment.name

resource customersRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, kvRoleType , subscription().subscriptionId, 'customers', uniqueString(resourceGroup().id, deployment().name))
  scope: kv
  properties: {
    roleDefinitionId: role[kvRoleType]
    principalId: customersIdentityId
    principalType: 'ServicePrincipal'
  }
}
output customersRoleAssignmentUpdatedOn string = customersRoleAssignment.properties.updatedOn
output customersRoleAssignmentId string = customersRoleAssignment.id
output customersRoleAssignmentName string = customersRoleAssignment.name
