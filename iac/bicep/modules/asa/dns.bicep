/*
Test with
az deployment group create --name iac-101-asa-dns -f ./asa/dns.bicep -g rg-iac-asa-petclinic-mic-srv \
    -p azureSpringAppsInstanceName=petcliasa --debug 
 --what-if to test like a dry-run
*/

@description('A UNIQUE name')
@maxLength(20)
param appName string = '101-${uniqueString(deployment().name)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

param vnetName string = 'vnet-azure-spring-apps'

@description('The Azure Spring Apps instance name')
param azureSpringAppsInstanceName string = 'asa-${appName}'

resource azureSpringApps 'Microsoft.AppPlatform/Spring@2022-05-01-preview' existing =  {
  name: azureSpringAppsInstanceName
}

@description('The resource group where all network resources for apps will be created in')
param appNetworkResourceGroup string = 'rg-asa-apps-petclinic'

@description('The resource group where all network resources for Azure Spring Apps service runtime will be created in')
param serviceRuntimeNetworkResourceGroup string = 'rg-asa-svc-run-petclinic'

resource asaPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'private.azuremicroservices.io'
  location:location
  // properties: {}
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' existing =  {
  name: vnetName
}
output vnetId string = vnet.id

resource dnsLinklnkASA 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'dns-lnk-asa-petclinic'
  location: location
  parent: asaPrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

output private_dns_link_id string = dnsLinklnkASA.id


resource appNetworkRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: appNetworkResourceGroup
  scope: subscription()
}

resource serviceRuntimeNetworkRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: serviceRuntimeNetworkResourceGroup
  scope: subscription()
}

resource appsAksLb 'Microsoft.Network/loadBalancers@2022-05-01' existing = {
  scope: appNetworkRG
  name: 'kubernetes-internal'
}
output appsAksLbFrontEndIpConfigId string = appsAksLb.properties.frontendIPConfigurations[0].id
output appsAksLbFrontEndIpConfigName string = appsAksLb.properties.frontendIPConfigurations[0].name
output appsAksLbFrontEndIpPrivateIpAddress string = appsAksLb.properties.frontendIPConfigurations[0].properties.privateIPAddress

resource asaServiceRuntime_AksLb 'Microsoft.Network/loadBalancers@2022-05-01' existing = {
  scope: serviceRuntimeNetworkRG
  name: 'kubernetes-internal'
}
output asaServiceRuntime_AksLbFrontEndIpConfigId string = asaServiceRuntime_AksLb.properties.frontendIPConfigurations[0].id
output asaServiceRuntime_AksLbFrontEndIpConfigName string = asaServiceRuntime_AksLb.properties.frontendIPConfigurations[0].name


resource asaAppsRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: azureSpringAppsInstanceName
  parent: asaPrivateDnsZone
  properties: {
    aRecords: [
      {
        ipv4Address: appsAksLb.properties.frontendIPConfigurations[0].properties.privateIPAddress
      }
    ]
    cnameRecord: {
      cname: azureSpringAppsInstanceName
    }
    ttl: 360
  }
}

resource asaAppsTestRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${azureSpringAppsInstanceName}.test'
  parent: asaPrivateDnsZone
  properties: {
    aRecords: [
      {
        ipv4Address: appsAksLb.properties.frontendIPConfigurations[0].properties.privateIPAddress
      }
    ]
    cnameRecord: {
      cname: azureSpringAppsInstanceName
    }
    ttl: 360
  }
}
