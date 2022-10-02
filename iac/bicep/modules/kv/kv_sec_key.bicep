/*
If you need to purge KV: https://docs.microsoft.com/en-us/azure/key-vault/general/key-vault-recovery?tabs=azure-portal
The user will need the following permissions (at subscription level) to perform operations on soft-deleted vaults:
Microsoft.KeyVault/locations/deletedVaults/purge/action
*/

// https://argonsys.com/microsoft-cloud/library/dealing-with-deployment-blockers-with-bicep/

@description('A UNIQUE name')
@maxLength(20)
param appName string = 'iacdemo${uniqueString(resourceGroup().id)}'

@maxLength(24)
@description('The name of the KV, must be UNIQUE.  A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

@description('Specifies all KV secrets {"secretName":"","secretValue":""} wrapped in a secure object.')
@secure()
param secretsObject object

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: kvName
}


// https://docs.microsoft.com/en-us/azure/developer/github/github-key-vault
// https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets?tabs=bicep

resource kvSecrets 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = [for secret in secretsObject.secrets: {
  name: secret.secretName
  parent: kv
  properties: {
    attributes: {
      enabled: true
      exp: 1656547200
      // nbf: int
    }
    contentType: 'text/plain'
    value: secret.secretValue
  }
}]
