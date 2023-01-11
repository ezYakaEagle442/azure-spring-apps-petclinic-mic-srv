// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring?tabs=bicep
@description('A UNIQUE name')
@maxLength(20)
param appName string = '101-${uniqueString(deployment().name)}'

param deploymentVersion string = '2.6.6'

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

var kvURL = 'https://${kvName}.vault.azure.net/'

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
resource azureSpringApps 'Microsoft.AppPlatform/Spring@2022-11-01-preview' existing = {
  name: azureSpringAppsInstanceName
}

output azureSpringAppsResourceId string = azureSpringApps.id
output azureSpringAppsFQDN string = azureSpringApps.properties.fqdn
output azureSpringAppsOutboundPubIP string = azureSpringApps.properties.networkProfile.outboundIPs.publicIPs[0]

resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings?tabs=bicep
resource appInsightsDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' existing = {
  name: appInsightsDiagnosticSettingsName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource configServerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: configServerAppIdentityName
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

resource azureSpringAppsconfigserver 'Microsoft.AppPlatform/Spring/configServers@2022-11-01-preview' existing = {
  name: configServerName
}

resource customersserviceapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' existing = {
  name: 'customers-service'
  parent: azureSpringApps
}

resource adminserverapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' existing = {
  name: 'adm-test'
  parent: azureSpringApps
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/apps/deployments?pivots=deployment-language-bicep
resource adminserverappdeployment 'Microsoft.AppPlatform/Spring/apps/deployments@2022-11-01-preview' = {
  name: 'default'
  parent: adminserverapp
  sku: {
    name: azureSpringAppsSkuName
  }
  properties: {
    active: true
    deploymentSettings: {
      addonConfigs: {
        azureMonitor: {
          enabled: true
        }
      }
      environmentVariables: {
        SPRING_CLOUD_AZURE_KEY_VAULT_ENDPOINT: kvURL
        // VETS_SVC_APP_IDENTITY_CLIENT_ID: vetsServiceAppIdentity.properties.clientId
        SPRING_CLOUD_AZURE_TENANT_ID: tenantId
      }
      resourceRequests: {
        cpu: '1'
        memory: '1Gi'
      }      
      containerProbeSettings: {
        disableProbe: false
      }
      livenessProbe: {
        disableProbe: false
        failureThreshold: 5
        initialDelaySeconds: 30
        periodSeconds: 60
        probeAction: {
          type: 'HTTPGetAction'
          path:  '/actuator/health/liveness' /* /actuator */
        }
        successThreshold: 1
        timeoutSeconds: 30

      }
      readinessProbe: {
        disableProbe: false
        failureThreshold: 5
        initialDelaySeconds: 30
        periodSeconds: 60
        probeAction: {
          type: 'HTTPGetAction'
          path: '/actuator/health/readiness' /* /actuator */
          scheme: 'HTTP'
        }
        successThreshold: 1
        timeoutSeconds: 30
      }
      startupProbe: {
        disableProbe: false
        failureThreshold: 5
        initialDelaySeconds: 30
        periodSeconds: 60
        probeAction: {
          type: 'ExecAction'
          command: [
            'sleep'
            '60'
          ]
        }
        successThreshold: 1
        timeoutSeconds: 30
      }
    }
    
    source: {
      version: deploymentVersion
      type: 'Jar' // Jar, Container or Source https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/apps/deployments?pivots=deployment-language-bicep#usersourceinfo
      jvmOptions: '-Xms512m -Xmx1024m -Dspring.profiles.active=mysql,key-vault,cloud'
      // https://learn.microsoft.com/en-us/rest/api/azurespringapps/apps/get-resource-upload-url?tabs=HTTP#code-try-0
      // should be a link to a BLOB storage
      // https://github.com/Azure/bicep/issues/9515
      relativePath: 'https://stasapetcliasa.blob.core.windows.net/petcliasa-blob/asa-spring-petclinic-admin-server-2.6.6.jar' // 'spring-petclinic-admin-server/target/petclinic-customers-service-2.6.6.jar' 
      runtimeVersion: 'Java_11'
    }
  }
}

/*
JWT=$(curl -X POST -H 'Content-Type: application/x-www-form-urlencoded' \
https://login.microsoftonline.com/<tenantid>/oauth2/v2.0/token \
-d 'client_id=<clientid>' \
-d 'scope=https://management.core.windows.net/.default' \
-d 'grant_type=client_credentials' \
-d 'client_secret=<clientsecret>' | jq -r .access_token)

RESPONSE=$(curl -X POST "https://management.azure.com/subscriptions/<subscriptionid>/resourceGroups/<resourceGroupName>/providers/Microsoft.AppPlatform/Spring/<asaServiceName>/apps/<appName>/getResourceUploadUrl?api-version=2022-12-01" \
-H "Content-Length: 0" \
-H "Authorization: Bearer $JWT" -H "Content-type: application/json")

uploadUrl=$(echo $RESPONSE | jq -r .uploadUrl)
relativePath=$(echo $RESPONSE | jq -r .relativePath)

jarFilePath=<local jar file path>
azcopy copy "$jarFilePath" "$uploadUrl"

echo $relativePath
*/


resource vetsserviceapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' existing = {
  name: 'vets-service'
  parent: azureSpringApps

}

resource visitsservicerapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' existing = {
  name: 'visits-service'
  parent: azureSpringApps
}

resource apigatewayapp 'Microsoft.AppPlatform/Spring/apps@2022-11-01-preview' existing = {
  name: 'api-gateway'
  parent: azureSpringApps
}


/*
// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/apps/deployments?pivots=deployment-language-bicep
resource customersserviceappdeployment 'Microsoft.AppPlatform/Spring/apps/deployments@2022-11-01-preview' = {
  name: 'aca-${appName}-customers-service-init-v.0.1.0'
  parent: customersserviceapp
  sku: {
    name: azureSpringAppsSkuName
  }
  properties: {
    active: true
    deploymentSettings: {
      addonConfigs: {
        azureMonitor: {
          enabled: true
        }
      }
      environmentVariables: {
        XXX: 'foo'
        ZZZ: 'bar'
      }
      containerProbeSettings: {
        disableProbe: false
      }
      livenessProbe: {
        disableProbe: false
        failureThreshold: 5
        initialDelaySeconds: 30
        periodSeconds: 60
        probeAction: {
          type: 'HTTPGetAction'
        }
        successThreshold: 1
        timeoutSeconds: 30

      }
      readinessProbe: {
        disableProbe: false
        failureThreshold: 5
        initialDelaySeconds: 30
        periodSeconds: 60
        probeAction: {
          type: 'HTTPGetAction'
        }
        successThreshold: 1
        timeoutSeconds: 30
      }
      resourceRequests: {
          cpu: any(1)
          memory: any(1)
      }
    }
    
    source: {
      version: '1.0.0'
      
      
      type: 'Jar' // Jar, Container or Source https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/apps/deployments?pivots=deployment-language-bicep#usersourceinfo
      jvmOptions: '-Dazure.keyvault.uri=${kvURL} -Xms512m -Xmx1024m -Dspring.profiles.active=mysql,key-vault,cloud'
      relativePath: 'spring-petclinic-customers-service' // './target/petclinic-customers-service-2.6.6.jar'
      runtimeVersion: 'Java_11'
      

      type: 'Container' 
      customContainer:  {
        containerImage: 'https://acrpetcliasa.azurecr.io/petclinic/petclinic-customers-service:4242' // Container image of the custom container. This should be in the form of {repository}:{tag} without the server name of the registry	
        command: ['java', '-jar petclinic-customers-service-2.6.6.jar', '--server.port=8080', '--spring.profiles.active=docker,mysql'] 
        server: 'acrpetcliasa.azurecr.io' // 	The name of the registry that contains the container image, Default: docker.io
        imageRegistryCredential: {
          username: 'AcrUserName'
          password: 'AcrPassword'
        }
        languageFramework: 'Java'
        args: '' // Arguments to the entrypoint. The docker image's CMD is used if this is not provided.
      }
      
      type: 'Source' // Jar, Container or Source https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/apps/deployments?pivots=deployment-language-bicep#usersourceinfo
      relativePath: 'spring-petclinic-customers-service'
      runtimeVersion: 'Java_11'
      artifactSelector: 'spring-petclinic-customers-service' // Selector for the artifact to be used for the deployment for multi-module projects. This should be the relative path to the target module/project.
      
    }
  }
}
*/
