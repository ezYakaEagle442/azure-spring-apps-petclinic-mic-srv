// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring?tabs=bicep
@description('A UNIQUE name')
@maxLength(23)
param appName string = 'petcliasa${uniqueString(resourceGroup().id, subscription().id)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

@description('The Azure Active Directory tenant ID that should be used to manage Azure Spring Apps Apps Identity.')
param tenantId string = subscription().tenantId

@description('The Log Analytics workspace name used by Azure Spring Apps instance')
param logAnalyticsWorkspaceName string = 'log-${appName}'

param appInsightsName string = 'appi-${appName}'
param appInsightsDiagnosticSettingsName string = 'dgs-${appName}-send-logs-and-metrics-to-log-analytics'

@description('The Azure Spring Apps instance name')
param azureSpringAppsInstanceName string = 'asa-${appName}'

// Check SKU REST API : https://learn.microsoft.com/en-us/rest/api/azureSpringApps/skus/list#code-try-0
@description('The Azure Spring Apps SKU Capacity, ie Max App instances')
@minValue(8)
@maxValue(25)
param azureSpringAppsSkuCapacity int = 25

@description('The Azure Spring Apps SKU name. Check it out at https://learn.microsoft.com/en-us/rest/api/azureSpringApps/skus/list#code-try-0')
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
@description('The Azure Spring Apps SKU Tier. Check it out at https://learn.microsoft.com/en-us/rest/api/azureSpringApps/skus/list#code-try-0')
param azureSpringAppsTier string = 'Standard'

@description('Should the service be deployed to a Corporate VNet ?')
param deployToVNet bool = false

param vnetName string = 'vnet-azure-spring-apps'
param appNetworkResourceGroup string 
param serviceRuntimeNetworkResourceGroup string 
param appSubnetId string 
param serviceRuntimeSubnetId string
param serviceCidr string
param zoneRedundant bool = false

@description('The Azure Spring Apps Git Config Server name. Only "default" is supported')
@allowed([
  'default'
])
param configServerName string = 'default'

@description('The Azure Spring Apps monitoring Settings name. Only "default" is supported')
@allowed([
  'default'
])
param monitoringSettingsName string = 'default'

@description('The Azure Spring Apps Service Registry name. Only "default" is supported')
@allowed([
  'default'
])
param serviceRegistryName string = 'default' // The resource name 'Azure Spring Apps Service Registry' is not valid

@description('The Azure Spring Apps Config Server Git URI (The repo must be public).')
param gitConfigURI string

@description('The Azure Spring Apps Build Agent pool name. Only "default" is supported') // to be checked
@allowed([
  'default'
])
param buildAgentPoolName string = 'default'
param builderName string = 'Java-Builder'
param buildName string = '${appName}-build'

@description('The Azure Spring Apps Build service name. Only "{azureSpringAppsInstanceName}/default" is supported') // to be checked
param buildServiceName string = '${azureSpringAppsInstanceName}/default' // '{your-service-name}/default/default'  //{your-service-name}/{build-service-name}/{agenpool-name}

@secure()
@description('The MySQL DB server name.')
param serverName string

@secure()
@description('The MySQL DB Admin Login.')
param administratorLogin string = 'mys_adm'

@secure()
@description('The MySQL DB Admin Password.')
param administratorLoginPassword string

@maxLength(24)
@description('The name of the KV, must be UNIQUE. A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

@description('The name of the KV RG')
param kvRGName string

@description('The config-server Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param configServerAppIdentityName string = 'id-asa-${appName}-petclinic-config-server-dev-${location}-101'

@description('The api-gateway Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param apiGatewayAppIdentityName string = 'id-asa-${appName}-petclinic-api-gateway-dev-${location}-101'

@description('The customers-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param customersServiceAppIdentityName string = 'id-asa-${appName}-petclinic-customers-service-dev-${location}-101'

@description('The vets-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param vetsServiceAppIdentityName string = 'id-asa-${appName}-petclinic-vets-service-dev-${location}-101'

@description('The visits-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param visitsServiceAppIdentityName string = 'id-asa-${appName}-petclinic-visits-service-dev-${location}-101'

resource kvRG 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: kvRGName
  scope: subscription()
}

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
  scope: kvRG
}
// pre-req: https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-bicep
// https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-azure-cli#prerequisites
resource azureSpringApps 'Microsoft.AppPlatform/Spring@2023-03-01-preview' = if (!deployToVNet) {
  name: azureSpringAppsInstanceName
  location: location
  sku: {
    capacity: azureSpringAppsSkuCapacity
    name: azureSpringAppsSkuName
    tier: azureSpringAppsTier
  }
  properties: {
    networkProfile: {
      appNetworkResourceGroup: appNetworkResourceGroup
      appSubnetId: appSubnetId
      serviceCidr: serviceCidr
      serviceRuntimeNetworkResourceGroup: serviceRuntimeNetworkResourceGroup
      serviceRuntimeSubnetId: serviceRuntimeSubnetId
    }
    zoneRedundant: zoneRedundant
  }
}

output azureSpringAppsResourceId string = azureSpringApps.id
output azureSpringAppsFQDN string = azureSpringApps.properties.fqdn
output azureSpringAppsOutboundPubIP string = azureSpringApps.properties.networkProfile.outboundIPs.publicIPs[0]

resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings?tabs=bicep
resource appInsightsDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: appInsightsDiagnosticSettingsName
  scope: azureSpringApps
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'ApplicationConsole'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'SystemLogs'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'IngressLogs'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }    
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource azureSpringAppsMonitoringSettings 'Microsoft.AppPlatform/Spring/monitoringSettings@2023-03-01-preview' = {
  name: monitoringSettingsName
  parent: azureSpringApps
  properties: {
    appInsightsInstrumentationKey: appInsights.properties.ConnectionString //  appInsights.properties.ConnectionString // DO NOT USE the InstrumentationKey appInsights.properties.InstrumentationKey
    appInsightsSamplingRate: 10
    // traceEnabled: true Indicates whether enable the trace functionality, which will be deprecated since api version 2020-11-01-preview. Please leverage appInsightsInstrumentationKey to indicate if monitoringSettings enabled or not
  }
}

resource configServerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: configServerAppIdentityName
}

resource apiGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: apiGatewayAppIdentityName
}

resource customersServicedentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: customersServiceAppIdentityName
}

resource vetsServiceAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: vetsServiceAppIdentityName
}

resource visitsServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: visitsServiceAppIdentityName
}

resource azureSpringAppsconfigserver 'Microsoft.AppPlatform/Spring/configServers@2023-03-01-preview' = {
  name: configServerName
  parent: azureSpringApps
  properties: {
    configServer: {
      gitProperty: {
        uri: gitConfigURI
      }
    }
  }
}

resource customersserviceapp 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: 'customers-service'
  location: location
  parent: azureSpringApps
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${customersServicedentity.id}': {}
    }      
  }
  properties: {
    addonConfigs: {}
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    azureSpringAppsconfigserver
  ]  
}
output customersServiceIdentity string = customersserviceapp.identity.principalId

resource vetsserviceapp 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: 'vets-service'
  location: location
  parent: azureSpringApps
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${vetsServiceAppIdentity.id}': {}
    }  
  }
  properties: {
    addonConfigs: {}
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    azureSpringAppsconfigserver
  ]  
}
output vetsServiceIdentity string = vetsserviceapp.identity.principalId

resource visitsservicerapp 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: 'visits-service'
  location: location
  parent: azureSpringApps
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${visitsServiceIdentity.id}': {}
    }  
  }
  properties: {
    addonConfigs: {}
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    azureSpringAppsconfigserver
  ]
}
output visitsServiceIdentity string = visitsservicerapp.identity.principalId


resource apigatewayapp 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: 'api-gateway'
  location: location
  parent: azureSpringApps
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${apiGatewayIdentity.id}': {}
    }  
  }
  properties: {
    addonConfigs: {}
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    azureSpringAppsconfigserver
    customersserviceapp
    vetsserviceapp
    visitsservicerapp
  ]  
}
output apiGatewayIdentity string = apigatewayapp.identity.principalId

/*

resource customersservicebinding 'Microsoft.AppPlatform/Spring/apps/bindings@2022-03-01-preview' = {
  name: 'customers-service MySQL DB Binding'
  parent: customersserviceapp
  properties: {
    bindingParameters: {}
    resourceId: mySQLResourceID // MySQL ResourceID
  }
}

resource vetsbinding 'Microsoft.AppPlatform/Spring/apps/bindings@2022-03-01-preview' = {
  name: 'vets-service MySQL DB Binding'
  parent: vetsserviceapp
  properties: {
    bindingParameters: {}
    resourceId: mySQLResourceID // MySQL ResourceID
  }
}

resource visitsbinding 'Microsoft.AppPlatform/Spring/apps/bindings@2022-03-01-preview' = {
  name: 'visits-service MySQL DB Binding'
  parent: visitsservicerapp
  properties: {
    bindingParameters: {
      databaseName: 'mydb'
      xxx: '' // username ? PWD ?
    }
    key: 'string' // There is no API Key for MySQL
    resourceId: mySQLResourceID // MySQL ResourceID
  }
}
*/


/*
resource buildService 'Microsoft.AppPlatform/Spring/buildServices@2022-03-01-preview' = {
  name: 'string'
  parent: azureSpringApps
  properties: {
    kPackVersion: '0.5.1'
    resourceRequests: {
      cpu: '200m'
      memory: '4Gi'
    }
  }
}

// https://github.com/Azure/azure-rest-api-specs/issues/18286
// Feature BuildService is not supported in Sku S0: https://github.com/MicrosoftDocs/azure-docs/issues/89924
resource buildService 'Microsoft.AppPlatform/Spring/buildServices@2022-03-01-preview' existing = {
  //scope: resourceGroup('my RG')
  name: buildServiceName  
}

resource buildagentpool 'Microsoft.AppPlatform/Spring/buildServices/agentPools@2022-03-01-preview' = {
  name: buildAgentPoolName
  parent: buildService
  properties: {
    poolSize: {
      name: 'S1'
    }
  }
  dependsOn: [
    azureSpringApps
  ]  
}

// https://learn.microsoft.com/en-us/azure/spring-apps/how-to-enterprise-build-service?tabs=azure-portal#default-builder-and-tanzu-buildpacks
resource builder 'Microsoft.AppPlatform/Spring/buildServices/builders@2022-03-01-preview' = {
  name: builderName
  parent: buildService
  properties: {
    buildpackGroups: [
      {
        buildpacks: [
          {
            id: 'tanzu-buildpacks/java-azure'
          }
        ]
        name: 'java'
      }
    ]
    stack: {
      id: 'tanzu-base-bionic-stack' // io.buildpacks.stacks.bionic-base  https://docs.pivotal.io/tanzu-buildpacks/stacks.html , OSS from https://github.com/paketo-buildpacks/java
      version: '1.1.49'
    }
  }
  dependsOn: [
    azureSpringApps
  ]
}

resource build 'Microsoft.AppPlatform/Spring/buildServices/builds@2022-03-01-preview' = {
  name: buildName
  parent: buildService
  properties: {
    agentPool: buildAgentPoolName
    builder: builderName
    env: {}
    relativePath: '/'
  }
  dependsOn: [
    buildagentpool
    builder
  ]
}
*/



/* requires enterprise Tier: https://azure.microsoft.com/en-us/pricing/details/spring-apps/

// https://github.com/MicrosoftDocs/azure-docs/issues/89924
resource azureSpringAppsserviceregistry 'Microsoft.AppPlatform/Spring/serviceRegistries@2022-01-01-preview' = {
  name: serviceRegistryName
  parent: azureSpringApps
}


resource azureSpringAppsapiportal 'Microsoft.AppPlatform/Spring/apiPortals@2022-01-01-preview' = {
  name: 'string'
  sku: {
    capacity: int
    name: 'string'
    tier: 'string'
  }
  parent: azureSpringApps
  properties: {
    gatewayIds: [
      'string'
    ]
    httpsOnly: bool
    public: bool
    sourceUrls: [
      'string'
    ]
    ssoProperties: {
      clientId: 'string'
      clientSecret: 'string'
      issuerUri: 'string'
      scope: [
        'string'
      ]
    }
  }
}

resource azureSpringAppsgateway 'Microsoft.AppPlatform/Spring/gateways@2022-01-01-preview' = {
  name: 'string'
  sku: {
    capacity: int
    name: 'string'
    tier: 'string'
  }
  parent: azureSpringApps
  properties: {
    apiMetadataProperties: {
      description: 'string'
      documentation: 'string'
      serverUrl: 'string'
      title: 'string'
      version: 'string'
    }
    corsProperties: {
      allowCredentials: bool
      allowedHeaders: [
        'string'
      ]
      allowedMethods: [
        'string'
      ]
      allowedOrigins: [
        'string'
      ]
      exposedHeaders: [
        'string'
      ]
      maxAge: int
    }
    httpsOnly: bool
    public: bool
    resourceRequests: {
      cpu: 'string'
      memory: 'string'
    }
    ssoProperties: {
      clientId: 'string'
      clientSecret: 'string'
      issuerUri: 'string'
      scope: [
        'string'
      ]
    }
  }
}

resource appconfigservice 'Microsoft.AppPlatform/Spring/configurationServices@2022-03-01-preview' = {
  name: 'string'
  parent: azureSpringApps
  properties: {
    settings: {
      gitProperty: {
        repositories: [
          {
            hostKey: 'string'
            hostKeyAlgorithm: 'string'
            label: 'string'
            name: 'string'
            password: 'string'
            patterns: [
              'string'
            ]
            privateKey: 'string'
            searchPaths: [
              'string'
            ]
            strictHostKeyChecking: bool
            uri: 'string'
            username: 'string'
          }
        ]
      }
    }
  }
}

*/
