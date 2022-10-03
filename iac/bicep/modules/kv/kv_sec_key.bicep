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

/*
@description('Specifies all KV secrets {"secretName":"","secretValue":""} wrapped in a secure object.')
@secure()
param secretsObject object
*/

@description('Secret Name.')
@secure()
param secretName string

@description('Secret value')
@secure()
param secretValue string

// https://learn.microsoft.com/en-us/azure/key-vault/secrets/secrets-best-practices#secrets-rotation
// Because secrets are sensitive to leakage or exposure, it's important to rotate them often, at least every 60 days. 
@description('Expiry date in seconds since 1970-01-01T00:00:00Z. Ex: 1672444800 ==> 31/12/2022')
param secretExpiryDate int = 1672444800

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: kvName
}


// https://docs.microsoft.com/en-us/azure/developer/github/github-key-vault
// https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets?tabs=bicep

resource kvSecrets 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: secretName
  parent: kv
  properties: {
    attributes: {
      enabled: true
      // https://learn.microsoft.com/en-us/azure/key-vault/secrets/secrets-best-practices#secrets-rotation
      // Because secrets are sensitive to leakage or exposure, it's important to rotate them often, at least every 60 days. 
      // Expiry date in seconds since 1970-01-01T00:00:00Z.
      // 1672444800 ==> 31/12/2022
      exp: secretExpiryDate
    }
    contentType: 'text/plain'
    value: secretValue
  }
}

/*

resource kvSecrets 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = [for secret in secretsObject.secrets: {
  name: secret.secretName
  parent: kv
  properties: {
    attributes: {
      enabled: true
      // https://learn.microsoft.com/en-us/azure/key-vault/secrets/secrets-best-practices#secrets-rotation
      // Because secrets are sensitive to leakage or exposure, it's important to rotate them often, at least every 60 days. 
      // Expiry date in seconds since 1970-01-01T00:00:00Z.
      // 1672444800 ==> 31/12/2022
      exp: secretExpiryDate
      // nbf: int
    }
    contentType: 'text/plain'
    value: secret.secretValue
  }
}]

*/
