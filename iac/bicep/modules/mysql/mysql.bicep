
@description('A UNIQUE name')
@maxLength(23)
param appName string = 'petcliasa${uniqueString(resourceGroup().id)}'

@description('The location of the MySQL DB.')
param location string = resourceGroup().location

@description('The MySQL DB Admin Login.')
param administratorLogin string = 'mys_adm'

@secure()
@description('The MySQL DB Admin Password.')
param administratorLoginPassword string

@description('The MySQL DB Server name.')
param serverName string = appName

@description('Azure Spring Apps Outbound Public IPs as an Array')
param azureSpringAppsOutboundPubIP array
// https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-deploy-on-azure-free-account
@description('Azure Database for MySQL SKU')
@allowed([
  'Standard_D4s_v3'
  'Standard_D2s_v3'
  'Standard_B1ms'
])
param databaseSkuName string = 'Standard_B1ms' //  'GP_Gen5_2' for single server

@description('Azure Database for MySQL pricing tier')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param databaseSkuTier string = 'Burstable'

@description('MySQL version see https://learn.microsoft.com/en-us/azure/mysql/concepts-version-policy')
@allowed([
  '8.0'
  '5.7'
])
param mySqlVersion string = '5.7' // https://docs.microsoft.com/en-us/azure/mysql/concepts-supported-versions

resource mysqlserver 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  name: serverName
  location: location
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    // availabilityZone: '1'
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    createMode: 'Default'
    highAvailability: {
      mode: 'Disabled'
    }
    replicationRole: 'None'
    version: mySqlVersion
  }
}

output mySQLResourceID string = mysqlserver.id

// Add firewall config to allow Azure Spring Apps :
// virtualNetwork FirewallRules to Allow public access from Azure services
/*
resource fwRuleAzureSpringApps 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-12-01-preview' = {
  name: 'Allow-Azure-Spring-Apps'
  parent: mysqlserver
  properties: {
    startIpAddress: startIpAddress
    endIpAddress: endIpAddress
  }
}
*/


 // Allow Azure Spring Apps
 resource fwRuleAllowAzureSpringAppsIP1 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-12-01-preview' = {
  name: 'allow-asa-ip1'
  parent: mysqlserver
  properties: {
    startIpAddress: azureSpringAppsOutboundPubIP[0] // /!\ has 2 IP separated from a coma, ex: 20.31.114.2,20.238.165.131
    endIpAddress: azureSpringAppsOutboundPubIP[0]
  }
}

resource fwRuleAllowAzureSpringAppsIP2 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-12-01-preview' = {
  name: 'allow-asa-ip2'
  parent: mysqlserver
  properties: {
    startIpAddress: azureSpringAppsOutboundPubIP[1] // /!\ has 2 IP separated from a coma, ex: 20.31.114.2,20.238.165.131
    endIpAddress: azureSpringAppsOutboundPubIP[1]
  }
}



 // /!\ SECURITY Risk: Allow ANY HOST for local Dev/Test only
 /*
 // Allow public access from any Azure service within Azure to this server
 // This option configures the firewall to allow connections from IP addresses allocated to any Azure service or asset,
 // including connections from the subscriptions of other customers.
 resource fwRuleAllowAnyHost 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-12-01-preview' = {
  name: 'Allow Any Host'
  parent: mysqlserver
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

 resource fwRuleAllowAnyHost 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-12-01-preview' = {
  name: 'Allow Any Host'
  parent: mysqlserver
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}
*/
