@allowed([
  'KeyVaultAdministrator'
  'KeyVaultReader'
  'KeyVaultSecretsUser'  
])
@description('KV Built-in role to assign')
param kvRoleType string = 'KeyVaultSecretsUser'

param kvName string

@description('The name of the KV RG')
param kvRGName string

param asaCustomersServicePrincipalId string
param asaVetsServicePrincipalId string
param asaVisitsServicePrincipalId string

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: kvName
  scope: resourceGroup(kvRGName)
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

// https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal#prerequisites
// /!\ To assign Azure roles, you must have: requires to have Microsoft.Authorization/roleAssignments/write and Microsoft.Authorization/roleAssignments/delete permissions, 
// such as User Access Administrator or Owner.
resource kvSecretsUserRoleAssignmentCustomersService 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, kvRoleType , asaCustomersServicePrincipalId)
  properties: {
    roleDefinitionId: role[kvRoleType]
    principalId: asaCustomersServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource kvSecretsUserRoleAssignmentVetsService 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, kvRoleType , asaVetsServicePrincipalId)
  properties: {
    roleDefinitionId: role[kvRoleType]
    principalId: asaVetsServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource kvSecretsUserRoleAssignmentVisitsService 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, kvRoleType , asaVisitsServicePrincipalId)
  properties: {
    roleDefinitionId: role[kvRoleType]
    principalId: asaVisitsServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
