// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring?tabs=bicep
@description('A UNIQUE name')
@maxLength(20)
param appName string = '101-${uniqueString(deployment().name)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

@description('The Azure Spring Apps instance name')
param azureSpringAppsInstanceName string = 'asa-${appName}'

@description('The Azure Spring Apps SKU name. Check it out at https://learn.microsoft.com/en-us/rest/api/azureSpringApps/skus/list#code-try-0')
@allowed([
  'BO'
  'S0'
  'E0'
])
param azureSpringAppsSkuName string = 'S0'


@description('Should the service be deployed to a Corporate VNet ?')
param deployToVNet bool = false

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


resource azureSpringApps 'Microsoft.AppPlatform/Spring@2022-09-01-preview' existing = {
  name: azureSpringAppsInstanceName
}

output azureSpringAppsResourceId string = azureSpringApps.id
output azureSpringAppsFQDN string = azureSpringApps.properties.fqdn
output azureSpringAppsOutboundPubIP string = azureSpringApps.properties.networkProfile.outboundIPs.publicIPs[0]

resource azureSpringAppsconfigserver 'Microsoft.AppPlatform/Spring/configServers@2022-09-01-preview' existing = {
  name: configServerName
}

resource shellcfgtestapp 'Microsoft.AppPlatform/Spring/apps@2022-09-01-preview' existing = {
  name: 'shell-cfg-test'
  parent: azureSpringApps
}


// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-09-01-preview/spring/apps/deployments?pivots=deployment-language-bicep
resource shellcfgtestappdeployment 'Microsoft.AppPlatform/Spring/apps/deployments@2022-09-01-preview' = {
  name: 'default'
  parent: shellcfgtestapp
  sku: {
    name: azureSpringAppsSkuName
  }
  properties: {
    active: true
    deploymentSettings: {
      containerProbeSettings: {
        disableProbe: true
      }
      resourceRequests: {
        cpu: any(1)
        memory: any(1)
      }
    }
    
    source: {
      version: '1.0.0'
      type: 'Container' // Jar, Container or Source https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-09-01-preview/spring/apps/deployments?pivots=deployment-language-bicep#usersourceinfo
      customContainer: {
        /*
        args: [
          'string'
        ]*/
        command: [
          'curl https://asa-petcliasa.svc.azuremicroservices.io/config/'
          'curl https://github.com/ezYakaEagle442/spring-petclinic-microservices-config/blob/main/application.yml'
          'curl https://github.com/ezYakaEagle442/spring-petclinic-microservices-config/Config'
        ]
        containerImage: 'bash' // This should be in the form of {repository}:{tag} without the server name of the registry
        /*imageRegistryCredential: {
          password: 'string'
          username: 'string'
        }*/
        languageFramework: 'string'
        server: 'https://index.docker.io/v1' // The name of the registry that contains the container image
      }
    }
  }
}
