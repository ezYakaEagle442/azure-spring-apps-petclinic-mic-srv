/*=====================================================================================================================================
=                                                                                                                                    =
=                                                                                                                                    =
= https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-bicep?tabs=azure-spring-apps-enterprise  =                                                    *
=                                                                                                                                    =
=                                                                                                                                    =
=====================================================================================================================================*/


// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring?tabs=bicep
@description('A UNIQUE name')
@maxLength(20)
param appName string = '101-${uniqueString(deployment().name)}'

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
param azureSpringAppsSkuName string = 'E0'

@allowed([
  'Basic'
  'Standard'
  'Enterprise'
])
@description('The Azure Spring Apps SKU Tier. Check it out at https://learn.microsoft.com/en-us/rest/api/azureSpringApps/skus/list#code-try-0')
param azureSpringAppsTier string = 'Enterprise'

@description('Should the service be deployed to a Corporate VNet ?')
param deployToVNet bool = false

param zoneRedundant bool = false

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

@description('The Azure Spring Apps Application Configuration Service name. Only "default" is supported')
@allowed([
  'default'
])
param applicationConfigurationServiceName string = 'default'

@description('The Azure Spring Apps API Portal name. Only "default" is supported')
@allowed([
  'default'
])
param apiPortalName string = 'default'

@description('The Azure Spring Apps API Portal SSO Property clientId ')
@secure()
param apiPortalSsoClientId string

@description('The Azure Spring Apps API Portal SSO Property clientSecret ')
@secure()
param apiPortalSsoClientSecret string

@description('The Azure Spring Apps API Portal SSO Property issuerUri ')
@secure()
param apiPortalSsoIssuerUri string

@description('The Azure Spring Apps API Portal SSO Property ssoEnabled ')
param apiPortalSsoEnabled bool = false


@description('The Azure Spring Apps Spring Cloud Gateway name. Only "default" is supported')
@allowed([
  'default'
])
param gatewayName string = 'default'

@description('The Azure Spring Apps Application Configuration Service Git URI (The repo must be public).')
param gitConfigURI string

@allowed([
  'default'
])
@description('The Azure Spring Apps Application Configuration Service Git Repository name. Only "default" is supported')
param gitRepoName string  = 'default'

@description('The Azure Spring Apps Config Server Git label (branch/tag). Config Server takes master (on Git) as the default label if you do not specify one. To avoid Azure Spring Apps Config Server failure, be sure to pay attention to the default label when setting up Config Server with GitHub, especially for newly-created repositories. See https://learn.microsoft.com/en-us/azure/spring-apps/how-to-config-server https://docs.spring.io/spring-cloud-config/docs/3.1.4/reference/html/#_default_label . The default label used for Git is main. If you do not set spring.cloud.config.server.git.defaultLabel and a branch named main does not exist, the config server will by default also try to checkout a branch named master. If you would like to disable to the fallback branch behavior you can set spring.cloud.config.server.git.tryMasterBranch to false.')
param configServerLabel string = 'main'

@description('The Azure Spring Apps Build Agent pool name. Only "default" is supported') // to be checked
@allowed([
  'default'
])
param buildAgentPoolName string = 'default'
param builderName string = 'java-builder'
param buildName string = '${appName}-build'

@description('The Azure Spring Apps Build service name. Only "{azureSpringAppsInstanceName}/default" is supported') // to be checked
param buildServiceName string = '${azureSpringAppsInstanceName}/default' // '{your-service-name}/default/default'  //{your-service-name}/{build-service-name}/{agenpool-name}

@maxLength(24)
@description('The name of the KV, must be UNIQUE. A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

@description('The name of the KV RG')
param kvRGName string

var kvURL = 'https://${kvName}.vault.azure.net'

@description('The config-server Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param configServerAppIdentityName string = 'id-asa-petclinic-config-server-dev-westeurope-101'

@description('The api-gateway Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param apiGatewayAppIdentityName string = 'id-asa-petclinic-api-gateway-dev-westeurope-101'

@description('The customers-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param customersServiceAppIdentityName string = 'id-asa-petclinic-customers-service-dev-westeurope-101'

@description('The vets-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param vetsServiceAppIdentityName string = 'id-asa-petclinic-vets-service-dev-westeurope-101'

@description('The visits-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param visitsServiceAppIdentityName string = 'id-asa-petclinic-visits-service-dev-westeurope-101'

@description('The discovery-server Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param discoveryServerAppIdentityName string = 'id-asa-petclinic-discovery-server-dev-westeurope-101'

resource kvRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: kvRGName
  scope: subscription()
}

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
  scope: kvRG
}
// pre-req: https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-bicep
// https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-azure-cli#prerequisites
resource azureSpringApps 'Microsoft.AppPlatform/Spring@2022-11-01-preview' = {
  name: azureSpringAppsInstanceName
  location: location
  sku: {
    capacity: azureSpringAppsSkuCapacity
    name: azureSpringAppsSkuName
    tier: azureSpringAppsTier
  }
  properties: {
    zoneRedundant: zoneRedundant
    //
    //marketplaceResource: {
    //  plan:
    //  product:
    //  publisher:
    //}
    //
  }
}

output azureSpringAppsResourceId string = azureSpringApps.id
output azureSpringAppsFQDN string = azureSpringApps.properties.fqdn
output azureSpringAppsOutboundPubIP array = azureSpringApps.properties.networkProfile.outboundIPs.publicIPs // /!\ has 2 IP separated from a coma, ex: 20.31.114.2,20.238.165.131

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

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-09-01-preview/spring/monitoringsettings?pivots=deployment-language-bicep
resource azureSpringAppsMonitoringSettings 'Microsoft.AppPlatform/Spring/monitoringSettings@2022-09-01-preview' = if (azureSpringAppsTier=='Standard') {
  name: monitoringSettingsName
  parent: azureSpringApps
  properties: {
    appInsightsInstrumentationKey: appInsights.properties.InstrumentationKey // /!\ ConnectionString for Enterprise tier ,  InstrumentationKey for Standard Tier 
    appInsightsSamplingRate: 10
    // traceEnabled: true Indicates whether enable the trace functionality, which will be deprecated since api version 2020-11-01-preview. Please leverage appInsightsInstrumentationKey to indicate if monitoringSettings enabled or not
  }
}

resource azureSpringAppsEnterpriseMonitoringSettings 'Microsoft.AppPlatform/Spring/monitoringSettings@2022-09-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: monitoringSettingsName
  parent: azureSpringApps
  properties: {
    appInsightsInstrumentationKey: appInsights.properties.ConnectionString // /!\ ConnectionString for Enterprise tier ,  InstrumentationKey for Standard Tier 
    appInsightsSamplingRate: 10
    // traceEnabled: true Indicates whether enable the trace functionality, which will be deprecated since api version 2020-11-01-preview. Please leverage appInsightsInstrumentationKey to indicate if monitoringSettings enabled or not
  }
}

resource apiGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: apiGatewayAppIdentityName
}

resource customersServicedentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: customersServiceAppIdentityName
}

resource vetsServiceAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: vetsServiceAppIdentityName
}

resource visitsServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: visitsServiceAppIdentityName
}


// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-09-01-preview/spring/configurationservices?pivots=deployment-language-bicep
resource appconfigservice 'Microsoft.AppPlatform/Spring/configurationServices@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: applicationConfigurationServiceName
  parent: azureSpringApps
  properties: {
    settings: {
      gitProperty: {
        repositories: [
          {
            name: gitRepoName
            label: configServerLabel
            // https://learn.microsoft.com/en-us/azure/spring-apps/how-to-enterprise-application-configuration-service#pattern
            // {profile} - Optional. The name of a profile whose properties you may be retrieving. 
            // An empty value, or the value default, includes properties that are shared across profiles. 
            // Non-default values include properties for the specified profile and properties for the default profile.
            patterns: [
              'application'
            ]
            //searchPaths: [
            //  '/'
            //]
            uri: gitConfigURI
          }
        ]
      }
    }
  }
}

resource customersserviceapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' = {
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
    addonConfigs: {
      azureMonitor: {
        enabled: true
      }
      applicationConfigurationService: {
        resourceId: '${azureSpringApps.id}/configurationServices/${applicationConfigurationServiceName}'
      }
      serviceRegistry: {
          resourceId: '${azureSpringApps.id}/serviceRegistries/${serviceRegistryName}'
      }      
    }
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    appconfigservice
  ]  
}
output customersServiceIdentity string = customersserviceapp.identity.userAssignedIdentities['${customersServicedentity.id}'].principalId

resource vetsserviceapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' = {
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
    addonConfigs: {
      azureMonitor: {
        enabled: true
      }
      applicationConfigurationService: {
        resourceId: '${azureSpringApps.id}/configurationServices/${applicationConfigurationServiceName}'
      }
      serviceRegistry: {
          resourceId: '${azureSpringApps.id}/serviceRegistries/${serviceRegistryName}'
      }       
    }
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    appconfigservice
  ]  
}
output vetsServiceIdentity string = vetsserviceapp.identity.userAssignedIdentities['${vetsServiceAppIdentity.id}'].principalId

resource visitsservicerapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' = {
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
    addonConfigs: {
      azureMonitor: {
        enabled: true
      }
      applicationConfigurationService: {
        resourceId: '${azureSpringApps.id}/configurationServices/${applicationConfigurationServiceName}'
      }
      serviceRegistry: {
          resourceId: '${azureSpringApps.id}/serviceRegistries/${serviceRegistryName}'
      }       
    }
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    appconfigservice
  ]
}
output visitsServiceIdentity string = visitsservicerapp.identity.userAssignedIdentities['${visitsServiceIdentity.id}'].principalId


resource apigatewayapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' = {
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
    addonConfigs: {
      azureMonitor: {
        enabled: true
      }
      applicationConfigurationService: {
        resourceId: '${azureSpringApps.id}/configurationServices/${applicationConfigurationServiceName}'
      }
      serviceRegistry: {
          resourceId: '${azureSpringApps.id}/serviceRegistries/${serviceRegistryName}'
      }       
    }
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    appconfigservice
    customersserviceapp
    vetsserviceapp
    visitsservicerapp
  ]  
}
output apiGatewayIdentity string = apigatewayapp.identity.userAssignedIdentities['${apiGatewayIdentity.id}'].principalId



// Binding name can contain only lowercase letters, numbers and hyphens.
// https://learn.microsoft.com/en-us/azure/spring-apps/how-to-enterprise-service-registry
/*
az spring service-registry bind \
--resource-group $RESOURCE_GROUP \
--service $AZURE_SPRING_APPS_NAME \
--app serviceA
*/

// https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-apps-enterprise#activate-service-registration-and-discovery
// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/serviceregistries?pivots=deployment-language-bicep
resource serviceRegistry 'Microsoft.AppPlatform/Spring/serviceRegistries@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: serviceRegistryName
  parent: azureSpringApps

}
output serviceRegistryId string = serviceRegistry.id
//output serviceRegistryCpu string = serviceRegistry.properties.resourceRequests.cpu
//output serviceRegistryInstanceCount int = serviceRegistry.properties.resourceRequests.instanceCount
//output serviceRegistryMemory string = serviceRegistry.properties.resourceRequests.memory

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-09-01-preview/spring/apiportals?pivots=deployment-language-bicep
// https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-configure-single-sign-on-enterprise
// https://learn.microsoft.com/en-us/azure/spring-apps/how-to-use-enterprise-api-portal
// az spring api-portal  update  --help
resource apiPortal 'Microsoft.AppPlatform/Spring/apiPortals@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: apiPortalName
  parent: azureSpringApps
  sku: {
    name: azureSpringAppsSkuName
    capacity: any(1) // Number of instance ?
    tier: azureSpringAppsTier
  }
  properties: {
    gatewayIds: [
        '${azureSpringApps.id}/gateways/${gatewayName}'
      ]
    httpsOnly: false
    public: true
    ssoProperties: {
      clientId: apiPortalSsoClientId
      clientSecret: apiPortalSsoClientSecret
      issuerUri: apiPortalSsoIssuerUri
      scope: [
        'openid'
        'profile'
        'email'
      ]
    }
  }
}
output apiPortalId string = apiPortal.id
output apiPortalUrl string = apiPortal.properties.url
output gatewayIds array = apiPortal.properties.gatewayIds

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/gateways?pivots=deployment-language-bicep
resource gateway 'Microsoft.AppPlatform/Spring/gateways@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: gatewayName
  parent: azureSpringApps
  sku: {
    name: azureSpringAppsSkuName
    capacity: any(1)
    tier: azureSpringAppsTier
  }
  properties: {
    corsProperties: {
      allowCredentials: false
      allowedOrigins: [
        '*'
      ]
      allowedMethods: [
        'GET'
      ]
      allowedHeaders: [
        '*'
      ]
    }
    httpsOnly: false
    public: true
    // az spring gateway update --help
    resourceRequests: {
      cpu: '1' // CPU resource quantity. Should be 500m or number of CPU cores.
      memory: '1Gi' // Memory resource quantity. Should be 512Mi or #Gi, e.g., 1Gi, 3Gi.
    }
    ssoProperties: {
      clientId: apiPortalSsoClientId
      clientSecret: apiPortalSsoClientSecret
      issuerUri: apiPortalSsoIssuerUri
      scope: [
        'openid'
        'profile'
        'email'
      ]
    }  
  }
}
output gatewayId string = gateway.id
output gatewayUrl string = gateway.properties.url

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/gateways/routeconfigs?pivots=deployment-language-bicep
resource VetsGatewayRouteConfig 'Microsoft.AppPlatform/Spring/gateways/routeConfigs@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'vets-service-gateway-route-config'
  parent: gateway
  properties: {
    appResourceId: vetsserviceapp.id
    protocol: 'HTTP'
    filters: [
      'StripPrefix=0'
    ]
    predicates: [
      '/api/vet/**'
      '/vets'
    ]
    routes: [
      {
        title: 'vets-service'
        description: 'vets-service'
        uri: 'http://vets-service'
        order: 2
        ssoEnabled: apiPortalSsoEnabled
      }
    ]
  }
}
output VetsGatewayRouteConfigId string = VetsGatewayRouteConfig.id
output VetsGatewayRouteConfigAppResourceId string = VetsGatewayRouteConfig.properties.appResourceId
output VetsGatewayRouteConfigRoutes array = VetsGatewayRouteConfig.properties.routes
output VetsGatewayRouteConfigIsSsoEnabled bool = VetsGatewayRouteConfig.properties.ssoEnabled
output VetsGatewayRouteConfigPredicates array = VetsGatewayRouteConfig.properties.predicates

resource VisitsGatewayRouteConfig 'Microsoft.AppPlatform/Spring/gateways/routeConfigs@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'visits-service-gateway-route-config'
  parent: gateway
  properties: {
    appResourceId: visitsservicerapp.id
    protocol: 'HTTP'
    filters: [
      'StripPrefix=0'
    ]
    predicates: [
      '/api/visit/**'
      '/visits'
    ]
    routes: [
      {
        title: 'visits-service' 
        description: 'visits-service'
        uri: 'http://visits-service'
        order: 3
        ssoEnabled: apiPortalSsoEnabled
      }
    ]
  }
}
output VisitsGatewayRouteConfigId string = VisitsGatewayRouteConfig.id
output VisitsGatewayRouteConfigAppResourceId string = VisitsGatewayRouteConfig.properties.appResourceId
output VisitsGatewayRouteConfigRoutes array = VisitsGatewayRouteConfig.properties.routes
output VisitsGatewayRouteConfigIsSsoEnabled bool = VisitsGatewayRouteConfig.properties.ssoEnabled
output VisitsGatewayRouteConfigPredicates array = VisitsGatewayRouteConfig.properties.predicates

resource CustomersGatewayRouteConfig 'Microsoft.AppPlatform/Spring/gateways/routeConfigs@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'customers-service-gateway-route-config'
  parent: gateway
  properties: {
    appResourceId: customersserviceapp.id
    protocol: 'HTTP'
    filters: [
      'StripPrefix=0'
    ]
    predicates: [
      '/api/customer/**'
      '/owners'
    ]
    routes: [
      {
        description: 'customers-service'
        title: 'customers-service'
        uri: 'http://customers-service'
        order: 1
        ssoEnabled: apiPortalSsoEnabled

      }
    ]
  }
}
output CustomersGatewayRouteConfigId string = CustomersGatewayRouteConfig.id
output CustomersGatewayRouteConfigAppResourceId string = CustomersGatewayRouteConfig.properties.appResourceId
output CustomersGatewayRouteConfigRoutes array = CustomersGatewayRouteConfig.properties.routes
output CustomersGatewayRouteConfigIsSsoEnabled bool = CustomersGatewayRouteConfig.properties.ssoEnabled
output CustomersGatewayRouteConfigPredicates array = CustomersGatewayRouteConfig.properties.predicates

resource customersbinding 'Microsoft.AppPlatform/Spring/apps/bindings@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'customers-service-binding'
  parent: customersserviceapp
  properties: {
    bindingParameters: {}
    resourceId: customersserviceapp.id
    key: 'customers-service' // There is no API Key for MySQL
  }
  dependsOn: [
    serviceRegistry
  ]
}

resource vetsbinding 'Microsoft.AppPlatform/Spring/apps/bindings@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'vets-service-binding'
  parent: vetsserviceapp
  properties: {
    bindingParameters: {}
    resourceId: vetsserviceapp.id
    key: 'vets-service' // There is no API Key for MySQL
  }
  dependsOn: [
    serviceRegistry
  ]  
}

resource visitsbinding 'Microsoft.AppPlatform/Spring/apps/bindings@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'visits-service-binding'
  parent: visitsservicerapp
  properties: {
    bindingParameters: {
      /*
      databaseName: 'mydb'
      xxx: '' // username ? PWD ?
      */
    }
    key: 'visits-service' // There is no API Key for MySQL
    resourceId: visitsservicerapp.id
  }
  dependsOn: [
    serviceRegistry
  ]  
}

// https://github.com/Azure/azure-rest-api-specs/issues/18286
// Feature BuildService is not supported in Sku S0: https://github.com/MicrosoftDocs/azure-docs/issues/89924
resource buildService 'Microsoft.AppPlatform/Spring/buildServices@2022-11-01-preview' existing = if (azureSpringAppsTier=='Enterprise') {
  //scope: resourceGroup('my RG')
  name: buildServiceName
}

resource buildagentpool 'Microsoft.AppPlatform/Spring/buildServices/agentPools@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: buildAgentPoolName
  parent: buildService
  properties: {
    poolSize: {
      name: 'S1'
    }
  }
}

// https://learn.microsoft.com/en-us/azure/spring-apps/how-to-enterprise-build-service?tabs=azure-portal#default-builder-and-tanzu-buildpacks
resource builder 'Microsoft.AppPlatform/Spring/buildServices/builders@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
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
      version: '1.2.35'
    }
  }
  dependsOn: [
    azureSpringApps
  ]
}

resource build 'Microsoft.AppPlatform/Spring/buildServices/builds@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
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
