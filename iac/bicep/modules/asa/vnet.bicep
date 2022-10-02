param location string = 'westeurope'

param vnetName string = 'vnet-azure-spring-apps'
param vnetCidr string = '10.42.0.0/21 '
param appSubnetCidr string = '10.42.1.0/28'
param serviceRuntimeSubnetCidr string = '10.42.2.0/28'
param serviceRuntimeSubnetName string = 'snet-svc-run'
param appSubnetName string = 'snet-app' // used for the AKS nodes

// https://docs.microsoft.com/en-us/azure/spring-cloud/how-to-deploy-in-azure-virtual-network?tabs=azure-portal#virtual-network-requirements
var serviceRuntimeSubnet = {
  name: serviceRuntimeSubnetName
  cidr: serviceRuntimeSubnetCidr
}

var appSubnet = {
  name: appSubnetName
  cidr: appSubnetCidr
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetCidr
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: serviceRuntimeSubnet.name
        properties: {
          addressPrefix: serviceRuntimeSubnet.cidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.KeyVault'
              locations: [
                '*'
              ]
            }            
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }        
      }
      {
        name: appSubnet.name
        properties: {
          addressPrefix: appSubnet.cidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.KeyVault'
              locations: [
                '*'
              ]
            }            
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }      
    ]
    enableDdosProtection: false
  }
}

output vnetId string = vnet.id
output serviceRuntimeSubnetId string = vnet.properties.subnets[0].id
output serviceRuntimeSubnetAddressPrefix string = vnet.properties.subnets[0].properties.addressPrefix
output appSubnetSubnetId string = vnet.properties.subnets[1].id
output appSubnetAddressPrefix string = vnet.properties.subnets[1].properties.addressPrefix
