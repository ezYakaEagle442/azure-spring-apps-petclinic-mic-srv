// https://docs.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring?tabs=bicep
@description('A UNIQUE name')
@maxLength(20)
param appName string = '101-${uniqueString(deployment().name)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

@description('The Azure Active Directory tenant ID that should be used to manage Azure Spring Cloud Apps Identity.')
param tenantId string = subscription().tenantId

@description('The Log Analytics workspace name used by Azure Spring Cloud instance')
param logAnalyticsWorkspaceName string = 'log-${appName}'

param appInsightsName string = 'appi-${appName}'
param appInsightsDiagnosticSettingsName string = 'dgs-${appName}-send-logs-and-metrics-to-log-analytics'

@description('The Azure Spring Cloud instance name')
param azureSpringCloudInstanceName string = 'asc-${appName}'

// Check SKU REST API : https://docs.microsoft.com/en-us/rest/api/azurespringcloud/skus/list#code-try-0
@description('The Azure Spring Cloud SKU Capacity, ie Max App instances')
@minValue(8)
@maxValue(25)
param azureSpringCloudSkuCapacity int = 25

@description('The Azure Spring Cloud SKU name. Check it out at https://docs.microsoft.com/en-us/rest/api/azurespringcloud/skus/list#code-try-0')
@allowed([
  'BO'
  'S0'
  'E0'
])
param azureSpringCloudSkuName string = 'S0'

@allowed([
  'Basic'
  'Standard'
  'Enterprise'
])
@description('The Azure Spring Cloud SKU Tier. Check it out at https://docs.microsoft.com/en-us/rest/api/azurespringcloud/skus/list#code-try-0')
param azureSpringCloudTier string = 'Standard'

param vnetName string = 'vnet-azure-spring-cloud'
param appNetworkResourceGroup string 
param serviceRuntimeNetworkResourceGroup string 
param appSubnetId string 
param serviceRuntimeSubnetId string
param serviceCidr string
param zoneRedundant bool = false

@description('The Azure Spring Cloud Git Config Server name. Only "default" is supported')
@allowed([
  'default'
])
param configServerName string = 'default'

@description('The Azure Spring Cloud monitoring Settings name. Only "default" is supported')
@allowed([
  'default'
])
param monitoringSettingsName string = 'default'

@description('The Azure Spring Cloud Service Registry name. Only "default" is supported')
@allowed([
  'default'
])
param serviceRegistryName string = 'default' // The resource name 'Azure Spring Cloud Service Registry' is not valid

@description('The Azure Spring Cloud Config Server Git URI (The repo must be public).')
param gitConfigURI string

@description('The Azure Spring Cloud Build Agent pool name. Only "default" is supported') // to be checked
@allowed([
  'default'
])
param buildAgentPoolName string = 'default'
param builderName string = 'Java-Builder'
param buildName string = '${appName}-build'

@description('The Azure Spring Cloud Build service name. Only "{azureSpringCloudInstanceName}/default" is supported') // to be checked
param buildServiceName string = '${azureSpringCloudInstanceName}/default' // '{your-service-name}/default/default'  //{your-service-name}/{build-service-name}/{agenpool-name}

// @description('MySQL ResourceID')
// param mySQLResourceID string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?tabs=bicep
resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
}
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.id

// pre-req: https://docs.microsoft.com/en-us/azure/spring-cloud/quickstart-deploy-infrastructure-vnet-bicep
// https://docs.microsoft.com/en-us/azure/spring-cloud/quickstart-deploy-infrastructure-vnet-azure-cli#prerequisites
resource azurespringcloud 'Microsoft.AppPlatform/Spring@2022-01-01-preview' = {
  name: azureSpringCloudInstanceName
  location: location
  sku: {
    capacity: azureSpringCloudSkuCapacity
    name: azureSpringCloudSkuName
    tier: azureSpringCloudTier
  }
  properties: {
    networkProfile: {
      appNetworkResourceGroup: appNetworkResourceGroup
      appSubnetId: appSubnetId
      serviceCidr: serviceCidr
      serviceRuntimeNetworkResourceGroup: serviceRuntimeNetworkResourceGroup
      serviceRuntimeSubnetId: serviceRuntimeSubnetId
    }
    // zoneRedundant: zoneRedundant
  }
}

output azureSpringCloudResourceId string = azurespringcloud.id
output azureSpringCloudFQDN string = azurespringcloud.properties.fqdn
output azureSpringCloudOutboundPubIP string = azurespringcloud.properties.networkProfile.outboundIPs.publicIPs[0]

// https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/components?tabs=bicep
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

// https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings?tabs=bicep
resource appInsightsDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: appInsightsDiagnosticSettingsName
  scope: azurespringcloud
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

resource azurespringcloudmonitoringSettings 'Microsoft.AppPlatform/Spring/monitoringSettings@2022-03-01-preview' = {
  name: monitoringSettingsName
  parent: azurespringcloud
  properties: {
    appInsightsInstrumentationKey: appInsights.properties.InstrumentationKey //  appInsights.properties.ConnectionString // DO NOT USE the InstrumentationKey appInsights.properties.InstrumentationKey
    appInsightsSamplingRate: 10
    // traceEnabled: true Indicates whether enable the trace functionality, which will be deprecated since api version 2020-11-01-preview. Please leverage appInsightsInstrumentationKey to indicate if monitoringSettings enabled or not
  }
}


resource adminserverapp 'Microsoft.AppPlatform/Spring/apps@2022-03-01-preview' = {
  name: 'admin-server'
  location: location
  parent: azurespringcloud
  identity: {
    // principalId: 'string'
    // tenantId: tenantId is a READ-ONLY attribute
    type: 'SystemAssigned'
  }
  properties: {
    addonConfigs: {}
    // fqdn: 'string'
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
}
output adminServerIdentity string = adminserverapp.identity.principalId


resource customersserviceapp 'Microsoft.AppPlatform/Spring/apps@2022-03-01-preview' = {
  name: 'customers-service'
  location: location
  parent: azurespringcloud
  identity: {
    // principalId: 'string'
    // tenantId: tenantId is a READ-ONLY attribute
    type: 'SystemAssigned'
  }
  properties: {
    addonConfigs: {}
    // fqdn: 'string'
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
}
output customersServiceIdentity string = customersserviceapp.identity.principalId

resource apigatewayapp 'Microsoft.AppPlatform/Spring/apps@2022-03-01-preview' = {
  name: 'api-gateway'
  location: location
  parent: azurespringcloud
  identity: {
    // principalId: 'string'
    // tenantId: tenantId is a READ-ONLY attribute
    type: 'SystemAssigned'
  }
  properties: {
    addonConfigs: {}
    // fqdn: 'string'
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
}
output apiGatewayIdentity string = apigatewayapp.identity.principalId

resource vetsserviceapp 'Microsoft.AppPlatform/Spring/apps@2022-03-01-preview' = {
  name: 'vets-service'
  location: location
  parent: azurespringcloud
  identity: {
    // principalId: 'string'
    // tenantId: tenantId is a READ-ONLY attribute
    type: 'SystemAssigned'
  }
  properties: {
    addonConfigs: {}
    // fqdn: 'string'
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
}
output vetsServiceIdentity string = vetsserviceapp.identity.principalId

resource visitsservicerapp 'Microsoft.AppPlatform/Spring/apps@2022-03-01-preview' = {
  name: 'visits-service'
  location: location
  parent: azurespringcloud
  identity: {
    // principalId: 'string'
    // tenantId: tenantId is a READ-ONLY attribute
    type: 'SystemAssigned'
  }
  properties: {
    addonConfigs: {}
    // fqdn: 'string'
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
}
output visitsServiceIdentity string = visitsservicerapp.identity.principalId

resource azurespringcloudconfigserver 'Microsoft.AppPlatform/Spring/configServers@2022-01-01-preview' = {
  name: configServerName
  parent: azurespringcloud
  properties: {
    configServer: {
      gitProperty: {
        uri: gitConfigURI
      }
    }

  }
}

module dnsprivatezone './dns.bicep' = {
  name: 'dns-private-zone'
  params: {
     location: location
     vnetName: vnetName
     azureSpringCloudInstanceName: azureSpringCloudInstanceName
     appNetworkResourceGroup: appNetworkResourceGroup
     serviceRuntimeNetworkResourceGroup: serviceRuntimeNetworkResourceGroup
  }
  dependsOn: [
    azurespringcloud
  ]     
}




/*
resource configserverapp 'Microsoft.AppPlatform/Spring/apps@2022-03-01-preview' = {
  name: 'config-server'
  location: location
  parent: azurespringcloud
  identity: {
    // principalId: 'string'
    // tenantId: tenantId is a READ-ONLY attribute
    type: 'SystemAssigned'
  }
  properties: {
    addonConfigs: {}
    // fqdn: 'string'
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
}
output configServerIdentity string = configserverapp.identity.principalId

// https://docs.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring/apps?tabs=bicep
resource discoveryserverapp 'Microsoft.AppPlatform/Spring/apps@2022-03-01-preview' = {
  name: 'discovery-server'
  location: location
  parent: azurespringcloud
  identity: {
    // principalId: 'string' is a READ-ONLY attribute
    // tenantId: tenantId is a READ-ONLY attribute
    type: 'SystemAssigned'
  }
  properties: {
    addonConfigs: {}
    // fqdn: 'string'
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
}
output discoveryServerIdentity string = discoveryserverapp.identity.principalId
*/


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
  parent: azurespringcloud
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
    azurespringcloud
  ]  
}

// https://docs.microsoft.com/en-us/azure/spring-cloud/how-to-enterprise-build-service?tabs=azure-portal#default-builder-and-tanzu-buildpacks
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
    azurespringcloud
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



/* requires enterprise Tier: https://azure.microsoft.com/en-us/pricing/details/spring-cloud/

// https://github.com/MicrosoftDocs/azure-docs/issues/89924
resource azurespringcloudserviceregistry 'Microsoft.AppPlatform/Spring/serviceRegistries@2022-01-01-preview' = {
  name: serviceRegistryName
  parent: azurespringcloud
}


resource azurespringcloudapiportal 'Microsoft.AppPlatform/Spring/apiPortals@2022-01-01-preview' = {
  name: 'string'
  sku: {
    capacity: int
    name: 'string'
    tier: 'string'
  }
  parent: azurespringcloud
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

resource azurespringcloudgateway 'Microsoft.AppPlatform/Spring/gateways@2022-01-01-preview' = {
  name: 'string'
  sku: {
    capacity: int
    name: 'string'
    tier: 'string'
  }
  parent: azurespringcloud
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
  parent: azurespringcloud
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
