@description('A UNIQUE name')
@maxLength(20)
param appName string = 'iacdemo${uniqueString(resourceGroup().id)}'

@maxLength(24)
@description('The name of the KV, must be UNIQUE. A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

// see https://github.com/microsoft/azure-container-apps/issues/151
@description('The KeyVault AccessPolicies for the Azure Container Apps Identities  wrapped into an object. See https://docs.microsoft.com/en-us/azure/container-apps/managed-identity')
param accessPoliciesObject object

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: kvName
}

// create accessPolicies https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/accesspolicies?tabs=bicep
// /!\ Preview feature: When enableRbacAuthorization is true in KV, the key vault will use RBAC for authorization of data actions, and the access policies specified in vault properties will be ignored
// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/loops#loop-with-condition
resource kvAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = { 
  name: 'add' // any('add-${app.appName}')
  parent: kv // https://github.com/Azure/bicep/issues/5660 https://gitmetadata.com/repo/Azure/bicep/issues/4756
  properties: {
    accessPolicies: [for accessPolicy in accessPoliciesObject.accessPolicies: {
        tenantId: tenantId
        objectId: accessPolicy.objectId
        permissions: accessPolicy.permissions
      }]
  }
}

