/*
az deployment group create --name asa-petclinic-storage -f iac/bicep/modules/asa/storage.bicep -g ${{ env.RG_APP }} \
            -p appName=${{ env.APP_NAME }} \
            -p location=${{ env.LOCATION }}
            
*/
@description('A UNIQUE name')
@maxLength(20)
param appName string = '101-${uniqueString(deployment().name)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

@description('The Azure Spring Apps instance name')
param azureSpringAppsInstanceName string = 'asa-${appName}'

@description('The Azure Active Directory tenant ID that should be used to manage Azure Spring Apps Apps Identity.')
param tenantId string = subscription().tenantId

@description('The Storage Account name')
param azureStorageName string = 'stasa${appName}'

@description('The BLOB Storage service name')
param azureBlobServiceName string = '${appName}-blob-svc'

@description('The BLOB Storage Container name')
param blobContainerName string = '${appName}-blob'

@description('The Identity Tags. See https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=bicep#apply-an-object')
param tags object = {
  Environment: 'Dev'
  Dept: 'IT'
  Scope: 'EU'
  CostCenter: '442'
  Owner: 'Petclinic'
}

@description('The Azure Strorage Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param storageIdentityName string = 'id-asa-petclinic-strorage-dev-westeurope-101'


// https://learn.microsoft.com/en-us/azure/templates/microsoft.managedidentity/userassignedidentities?pivots=deployment-language-bicep
resource storageIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: storageIdentityName
  location: location
  tags: tags
}
output storageIdentityId string = storageIdentity.id
output storageIdentityPrincipalId string = storageIdentity.properties.principalId

resource azureSpringApps 'Microsoft.AppPlatform/Spring@2022-09-01-preview' existing = {
  name: azureSpringAppsInstanceName
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep
resource azurestorage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: azureStorageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${storageIdentity.id}': {}
    }   
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowCrossTenantReplication: false
    allowedCopyScope: 'AAD'
    allowSharedKeyAccess: true

    defaultToOAuthAuthentication: false
    dnsEndpointType: 'AzureDnsZone'
    immutableStorageWithVersioning: {
      enabled: false
      immutabilityPolicy: {
        allowProtectedAppendWrites: false
        immutabilityPeriodSinceCreationInDays: 5
        state: 'Disabled'
      }
    }
    // isNfsV3Enabled: true
    keyPolicy: {
      keyExpirationPeriodInDays: 180
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
          action: 'Allow'
          value: azureSpringApps.properties.networkProfile.outboundIPs.publicIPs[0] // ASA
        }
        {
          action: 'Allow'
          value: azureSpringApps.properties.networkProfile.outboundIPs.publicIPs[1] // ASA
        }        
      ]
      resourceAccessRules: [
        {
          resourceId: azureSpringApps.id
          tenantId: tenantId
        }
      ]
      /*
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: 'string'
          state: 'string'
        }
      ]
      */
    }
    publicNetworkAccess: 'Enabled'
    routingPreference: {
      publishInternetEndpoints: false
      publishMicrosoftEndpoints: true
      routingChoice: 'MicrosoftRouting'
    }
    sasPolicy: {
      expirationAction: 'Log'
      sasExpirationPeriod: '30.23:59:00'
    }
    supportsHttpsTrafficOnly: true
  }
}

output azurestorageId string = azurestorage.id
output azurestorageSasToken string = azurestorage.listAccountSas().accountSasToken
output azurestorageKey0 string = azurestorage.listKeys().keys[0].value
output azurestorageKey1 string = azurestorage.listKeys().keys[1].value
output azurestorageHttpEndpoint string = azurestorage.properties.primaryEndpoints.blob
output azurestorageFileEndpoint string = azurestorage.properties.primaryEndpoints.file


resource azureblobservice 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  name: azureBlobServiceName
  parent: azurestorage
  properties: {
    containerDeleteRetentionPolicy: {
      allowPermanentDelete: true
      days: 5
      enabled: true
    }
    // defaultServiceVersion: ''
    deleteRetentionPolicy: {
      allowPermanentDelete: true
      days: 180
      enabled: true
    }
    isVersioningEnabled: true
    lastAccessTimeTrackingPolicy: {
      blobType: [
        'blockBlob'
      ]
      enable: false
      name: 'AccessTimeTracking'
      trackingGranularityInDays: 30
    }
    restorePolicy: {
      days: 30
      enabled: false
    }
  }
}
output azureblobserviceId string = azureblobservice.id

resource blobcontainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: blobContainerName
  parent: azureblobservice
  properties: {
    // defaultEncryptionScope: 'string'
    denyEncryptionScopeOverride: false
    enableNfsV3AllSquash: false
    enableNfsV3RootSquash: false
    immutableStorageWithVersioning: {
      enabled: false
    }
    publicAccess: 'Container'
  }
}
output blobcontainerId string = blobcontainer.id
