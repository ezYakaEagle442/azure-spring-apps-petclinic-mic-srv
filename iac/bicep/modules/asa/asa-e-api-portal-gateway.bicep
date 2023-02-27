/*=====================================================================================================================================
=                                                                                                                                    =
=                                                                                                                                    =
= https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-bicep?tabs=azure-spring-apps-enterprise  =                                                    *
=                                                                                                                                    =
=                                                                                                                                    =
=====================================================================================================================================*/


// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring?tabs=bicep
@description('A UNIQUE name')
@maxLength(23)
param appName string = 'petcliasa${uniqueString(deployment().name)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

@description('The Azure Active Directory tenant ID that should be used to manage Azure Spring Apps Apps Identity.')
param tenantId string = subscription().tenantId

@description('The Azure Spring Apps instance name')
param azureSpringAppsInstanceName string = 'asae-${appName}'

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

@description('The Spring Cloud Gateway server URL which is unknow the first time you run Bicep')
param gatewayServerUrl string = 'asae-XXXX-gateway-424242.svc.azuremicroservices.io/'

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
      serverUrl: gatewayServerUrl // ex: https://asae-petcliasa-gateway-424242.svc.azuremicroservices.io/ ==> Base URL that API consumers will use to access APIs on the Gateway instance.
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

resource vetsserviceapp 'Microsoft.AppPlatform/Spring/apps@2022-12-01' existing = {
  name: 'vets-service'
  parent: azureSpringApps
}

resource customersserviceapp 'Microsoft.AppPlatform/Spring/apps@2022-12-01' existing = {
  name: 'customers-service'
  parent: azureSpringApps
}

resource visitsservicerapp 'Microsoft.AppPlatform/Spring/apps@2022-12-01' existing = {
  name: 'visits-service'
  parent: azureSpringApps
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/gateways/routeconfigs?pivots=deployment-language-bicep
resource VetsGatewayRouteConfig 'Microsoft.AppPlatform/Spring/gateways/routeConfigs@2022-12-01' = if (azureSpringAppsTier=='Enterprise') {
  name: 'vets-service-gateway-route-config'
  parent: gateway
  properties: {
    appResourceId: vetsserviceapp.id
    protocol: 'HTTP'
    routes: [
      {
        title: 'Get All Vets'
        description: 'Get All Vets calling vets-service'
        order: 120
        filters: [
          'StripPrefix=2' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-stripprefix-gatewayfilter-factory
          'RateLimit=2,5s' // limit all users to two requests every 5 seconds https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-set-request-rate-limits-enterprise
        ]
        predicates: [
          // 'Path=/api/vet/**'
          'Path=/api/vet/vets'
        ]        
      }
    ]
  }
}
output VetsGatewayRouteConfigId string = VetsGatewayRouteConfig.id
output VetsGatewayRouteConfigAppResourceId string = VetsGatewayRouteConfig.properties.appResourceId
output VetsGatewayRouteConfigRoutes array = VetsGatewayRouteConfig.properties.routes
output VetsGatewayRouteConfigIsSsoEnabled bool = VetsGatewayRouteConfig.properties.routes[0].ssoEnabled
output VetsGatewayRouteConfigPredicates array = VetsGatewayRouteConfig.properties.routes[0].predicates

resource VisitsGatewayRouteConfig 'Microsoft.AppPlatform/Spring/gateways/routeConfigs@2022-12-01' = if (azureSpringAppsTier=='Enterprise') {
  name: 'visits-service-gateway-route-config'
  parent: gateway
  properties: {
    appResourceId: visitsservicerapp.id
    protocol: 'HTTP'
    routes: [
      {
        title: 'Get Visits for a given {ownerId} & /{petId}' 
        description: 'Get Visits calling visits-service'
        order: 110
        filters: [
          'StripPrefix=2' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-stripprefix-gatewayfilter-factory
          'RateLimit=2,5s' // limit all users to two requests every 5 seconds https://docs.vmware.com/en/VMware-Spring-Cloud-Gateway-for-Kubernetes/1.2/scg-k8s/GUID-route-filters.html#ratelimit-limiting-user-requests-filter
        ]
        predicates: [
          // 'Path=/api/visit/**'
          'Path=/api/visit/owners/{ownerId}/pets/{petId}/visits'
        ]  
      }
    ]
  }
}
output VisitsGatewayRouteConfigId string = VisitsGatewayRouteConfig.id
output VisitsGatewayRouteConfigAppResourceId string = VisitsGatewayRouteConfig.properties.appResourceId
output VisitsGatewayRouteConfigRoutes array = VisitsGatewayRouteConfig.properties.routes
output VisitsGatewayRouteConfigIsSsoEnabled bool = VisitsGatewayRouteConfig.properties.routes[0].ssoEnabled
output VisitsGatewayRouteConfigPredicates array = VisitsGatewayRouteConfig.properties.routes[0].predicates

resource CustomersGatewayRouteConfig 'Microsoft.AppPlatform/Spring/gateways/routeConfigs@2022-12-01' = if (azureSpringAppsTier=='Enterprise') {
  name: 'customers-service-gateway-route-config'
  parent: gateway
  properties: {
    appResourceId: customersserviceapp.id
    protocol: 'HTTP'
    routes: [
      {
        description: 'Get owners customers-service'
        title: 'Get owners'
        //uri: URI field should be used only ro route to external service out of ASA
        order: 101
        // ssoEnabled: false
        filters: [
          'StripPrefix=2' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-stripprefix-gatewayfilter-factory
          'RateLimit=2,5s' // limit all users to two requests every 5 seconds https://docs.vmware.com/en/VMware-Spring-Cloud-Gateway-for-Kubernetes/1.2/scg-k8s/GUID-route-filters.html#ratelimit-limiting-user-requests-filter
        ]
        predicates: [ // /!\ 1 Path ONLY inside predicates
          // 'Path=/api/customer/**' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-path-route-predicate-factory
          'Path=/api/customer/owners'
        ]
      }
      {
        description: 'Get Pet Types'
        title: 'Get Pet Types calling customers-service'
        order: 102
        // ssoEnabled: false
        filters: [
          'StripPrefix=2' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-stripprefix-gatewayfilter-factory
          'RateLimit=2,5s' // limit all users to two requests every 5 seconds https://docs.vmware.com/en/VMware-Spring-Cloud-Gateway-for-Kubernetes/1.2/scg-k8s/GUID-route-filters.html#ratelimit-limiting-user-requests-filter
        ]
        predicates: [
          // 'Path=/api/customer/**' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-path-route-predicate-factory
          'Path=/api/customer/petTypes'
        ]
      }
      {
        description: 'Get Owner given a {ownerId}'
        title: 'Get Owner calling customers-service'
        order: 103
        // ssoEnabled: false
        filters: [
          'StripPrefix=2' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-stripprefix-gatewayfilter-factory
          'RateLimit=2,5s' // limit all users to two requests every 5 seconds https://docs.vmware.com/en/VMware-Spring-Cloud-Gateway-for-Kubernetes/1.2/scg-k8s/GUID-route-filters.html#ratelimit-limiting-user-requests-filter
        ]
        predicates: [
          // 'Path=/api/customer/**' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-path-route-predicate-factory
          'Path=/api/customer/owners/{ownerId}'
        ]
      }      
      {
        description: 'Get Pets given a {ownerId}'
        title: 'Get Pets calling customers-service'
        order: 104
        // ssoEnabled: false
        filters: [
          'StripPrefix=2' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-stripprefix-gatewayfilter-factory
          'RateLimit=2,5s' // limit all users to two requests every 5 seconds https://docs.vmware.com/en/VMware-Spring-Cloud-Gateway-for-Kubernetes/1.2/scg-k8s/GUID-route-filters.html#ratelimit-limiting-user-requests-filter
        ]
        predicates: [
          // 'Path=/api/customer/**' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-path-route-predicate-factory
          'Path=/api/customer/owners/{ownerId}/pets'
        ]
      }      
      {
        description: 'Get a Pet given a {ownerId} and a {petId}'
        title: 'Get Pet calling customers-service'
        order: 105
        // ssoEnabled: false
        filters: [
          'StripPrefix=2' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-stripprefix-gatewayfilter-factory
          'RateLimit=2,5s' // limit all users to two requests every 5 seconds https://docs.vmware.com/en/VMware-Spring-Cloud-Gateway-for-Kubernetes/1.2/scg-k8s/GUID-route-filters.html#ratelimit-limiting-user-requests-filter
        ]
        predicates: [
          // 'Path=/api/customer/**' // https://cloud.spring.io/spring-cloud-gateway/reference/html/#the-path-route-predicate-factory
          'Path=/api/customer/owners/{ownerId}/pets/{petId}'
        ]
      } 
    ]
  }
}
output CustomersGatewayRouteConfigId string = CustomersGatewayRouteConfig.id
output CustomersGatewayRouteConfigAppResourceId string = CustomersGatewayRouteConfig.properties.appResourceId
output CustomersGatewayRouteConfigRoutes array = CustomersGatewayRouteConfig.properties.routes
output CustomersGatewayRouteConfigRoute0Predicates array = CustomersGatewayRouteConfig.properties.routes[0].predicates

