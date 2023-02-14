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
param appName string = 'petcliasa${uniqueString(deployment().name)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

@description('The Azure Active Directory tenant ID that should be used to manage Azure Spring Apps Apps Identity.')
param tenantId string = subscription().tenantId

@description('The Azure Spring Apps instance name')
param azureSpringAppsInstanceName string = 'asa-${appName}'

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

// pre-req: https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-bicep
// https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-azure-cli#prerequisites
resource azureSpringApps 'Microsoft.AppPlatform/Spring@2022-12-01' existing = {
  name: azureSpringAppsInstanceName
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-09-01-preview/spring/apiportals?pivots=deployment-language-bicep
// https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-configure-single-sign-on-enterprise
// https://learn.microsoft.com/en-us/azure/spring-apps/how-to-use-enterprise-api-portal
// az spring api-portal  update  --help
resource apiPortal 'Microsoft.AppPlatform/Spring/apiPortals@2022-12-01' = if (azureSpringAppsTier=='Enterprise') {
  name: apiPortalName
  parent: azureSpringApps
  sku: {
    name: azureSpringAppsSkuName
    capacity: any(1) // Number of instance
    tier: azureSpringAppsTier
  }
  properties: {
    gatewayIds: [
        //'${azureSpringApps.id}/gateways/${gatewayName}'
        gateway.id
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
  dependsOn:  [
    gateway
  ]
}
output apiPortalId string = apiPortal.id
output apiPortalUrl string = apiPortal.properties.url
output gatewayIds array = apiPortal.properties.gatewayIds

/*
resource gatewayCustomdomain 'Microsoft.AppPlatform/Spring/gateways/domains@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'javarocks.com'
  parent: gateway
  properties: {
    thumbprint: 'xxx'
  }
}
*/

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/gateways?pivots=deployment-language-bicep
resource gateway 'Microsoft.AppPlatform/Spring/gateways@2022-12-01' = if (azureSpringAppsTier=='Enterprise') {
  name: gatewayName
  parent: azureSpringApps
  sku: {
    name: azureSpringAppsSkuName
    capacity: any(1)
    tier: azureSpringAppsTier
  }
  properties: {
    httpsOnly: false // for custom domain ONLY ?
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
    apiMetadataProperties: {
      title: 'Spring Cloud Gateway for Petclinic' // Title describing the context of the APIs available on the Gateway instance (default: Spring Cloud Gateway for K8S)
      description: '' // description of the APIs available on the Gateway instance (default: Generated OpenAPI 3 document that describes the API routes configured for '[Gateway instance name]' Spring Cloud Gateway instance deployed under '[namespace]' namespace.)
      version: '1.0.0' // Version of APIs available on this Gateway instance (default: unspecified)
      serverUrl: '/api' // Base URL that API consumers will use to access APIs on the Gateway instance.
      documentation: '' // Location of additional documentation for the APIs available on the Gateway instance
    }
    /* Spring Cloud Gateway APM feature is not enabled
    apmTypes: [
      'ApplicationInsights'
    ]
    */
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
  }
}
output gatewayId string = gateway.id
output gatewayUrl string = gateway.properties.url

/*
// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/gateways/routeconfigs?pivots=deployment-language-bicep
resource VetsGatewayRouteConfig 'Microsoft.AppPlatform/Spring/gateways/routeConfigs@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'vets-service-gateway-route-config'
  parent: gateway
  properties: {
    appResourceId: vetsserviceapp.id
    protocol: 'HTTP'
    filters: [
      'StripPrefix=0'
      'RateLimit=2,5s' // limit all users to two requests every 5 seconds
    ]
    predicates: [
      '/api/vet/**'
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
      'RateLimit=2,5s' // limit all users to two requests every 5 seconds
    ]
    predicates: [
      '/api/visit/**'
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
      'RateLimit=2,5s' // limit all users to two requests every 5 seconds
    ]
    predicates: [
      '/api/customer/**'
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

resource customersserviceapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' existing = {
  name: 'customers-service'
  parent: azureSpringApps
}

resource vetsserviceapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' existing = {
  name: 'vets-service'
  parent: azureSpringApps 
}

resource visitsservicerapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' existing = {
  name: 'visits-service'
  parent: azureSpringApps
}

// https://github.com/MicrosoftDocs/azure-docs/issues/102825
resource apigatewayapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' existing = {
  name: 'api-gateway'
  parent: azureSpringApps  
}
*/
