
@description('A UNIQUE name')
@maxLength(20)
param appName string = 'iacdemo${uniqueString(resourceGroup().id)}'

@description('The location of the MySQL DB.')
param location string = resourceGroup().location

@secure()
@description('The MySQL DB Admin Login.')
param administratorLogin string = 'mys_adm'

@secure()
@description('The MySQL DB Admin Password.')
param administratorLoginPassword string

@secure()
@description('The MySQL DB Server name.')
param serverName string

@description('Azure Spring Apps Outbound Public IPs as an Array')
param azureSpringAppsOutboundPubIP array

@description('Should a MySQL Firewall be set to allow client workstation for local Dev/Test only')
param setFwRuleClient bool = false

@description('Allow client workstation for local Dev/Test only')
param clientIPAddress string

@description('Allow Azure Spring Apps from Apps subnet to access MySQL DB')
param startIpAddress string

@description('Allow Azure Spring Apps from Apps subnet to access MySQL DB')
param endIpAddress string

var databaseSkuName = 'Standard_B1ms' //  'GP_Gen5_2' for single server
var databaseSkuTier = 'Burstable' // 'GeneralPurpose'
var mySqlVersion = '5.7' // https://docs.microsoft.com/en-us/azure/mysql/concepts-supported-versions

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

// Allow client workstation with IP 'clientIPAddress' for local Dev/Test only
resource fwRuleClientIPAddress 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-12-01-preview' = if (setFwRuleClient)  {
  name: 'client-ip-address'
  parent: mysqlserver
  properties: {
    startIpAddress: clientIPAddress
    endIpAddress: clientIPAddress
  }
}

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
