// See https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.compute/vm-simple-linux/main.bicep
// SSH Test: ssh -i ~/.ssh/$ssh_key $admin_username@$network_interface_pub_ip

/*
https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/
Warning: The `set-output` command is deprecated and will be disabled soon. 
Please upgrade to using Environment Files. For more information see: 
*/

/*
ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/$ssh_key -C "youremail@groland.grd"'

az deployment group create --name asa-gh-self-hosted-runner -f iac/bicep/gh/gh-self-hosted-runner.bicep -g ${{ env.RG_APP }} \
  -p appName=${{ env.APP_NAME }} \
  -p location=${{ env.LOCATION }} \
  -p adminUsername= 'adm_run' \
  -p adminPasswordOrKey=<your SSH public Key>


*/
@description('A UNIQUE name')
@maxLength(20)
param appName string = 'petcliasa${uniqueString(deployment().name)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

param vnetName string = 'vnet-asa'

@description('Linux client VM deployed to the VNet. Computer name cannot be more than 15 characters long')
param linuxVMName string = 'vm-linuxasapetcli'

@allowed([
  'Standard_B2s'
  'Standard_B1s'
])
@description('The size of the VM')
param vmSize string = 'Standard_B1s'

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended. ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/$ssh_key -C "youremail@groland.grd"')
@secure()
param adminPasswordOrKey string

@description('emailRecipient informed before the VM shutdown')
param autoShutdownNotificationEmail string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('${linuxVMName}-${uniqueString(resourceGroup().id)}')

@allowed([
  'Canonical'
  'RedHat'
  'MicrosoftCBLMariner'
])
param publisher string = 'Canonical'

// https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners#supported-architectures-and-operating-systems-for-self-hosted-runners
@allowed([
  'UbuntuServer'
  '0001-com-ubuntu-minimal-jammy'
  '0001-com-ubuntu-server-jammy'
  '0001-com-ubuntu-pro-jammy'
  '0001-com-ubuntu-server-focal'
  '0001-com-ubuntu-minimal-bionic'
  '0001-com-ubuntu-pro-bionic'
])
param offer string =  '0001-com-ubuntu-minimal-jammy'

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  '18.04-LTS'
  '20.04-LTS'
  '22.04-LTS'
  '20_04-lts'
  'minimal-22_04-lts'
])
param ubuntuOSVersion string = 'minimal-22_04-lts'

@description('The VM Admin user name')
param adminUsername string = 'adm_run'

/*
@secure()
@description('The VM password length must be between 12 and 123.')
param adminPassword string = 'changeIT'
*/

param nsgName string = 'nsg-asa-${appName}-app-client'
param nsgRuleName string = 'Allow SSH from local dev station'

@description('The CIDR or source IP range. Asterisk "*" can also be used to match all source IPs. Default tags such as "VirtualNetwork", "AzureLoadBalancer" and "Internet" can also be used. If this is an ingress rule, specifies where network traffic originates from.')
param nsgRuleSourceAddressPrefix string = '*'

@description('The GitHub Runner IP adress')
param ghRunnerIP string

param nicName string = 'nic-asa-${appName}-client-vm'

// https://learn.microsoft.com/en-us/azure/automanage/automanage-linux
var linuxConfiguration = {
  enableVMAgentPlatformUpdates: true
  provisionVMAgent: true
  disablePasswordAuthentication: true
  patchSettings: { // https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-vm-guest-patching#supported-os-images
    assessmentMode: 'ImageDefault'
    /* AutomaticByPlatformSettings cannot be set if the PatchMode is not 'AutomaticByPlatform' 
    automaticByPlatformSettings: {
      rebootSetting: 'IfRequired'
    }
    */
    patchMode: 'ImageDefault'
  }  
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

var osDiskType = 'Standard_LRS'


resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' existing =  {
  name: vnetName
}

output vnetId string = vnet.id
output vnetGUID string = vnet.properties.resourceGuid
output subnetId string = vnet.properties.subnets[0].id

// Resource ID of a subnet for infrastructure components. This subnet must be in the same VNET as the subnet defined in runtimeSubnetId. Must not overlap with any other provided IP ranges.
var infrastructureSubnetID = vnet.properties.subnets[0].id



// https://docs.microsoft.com/en-us/azure/templates/microsoft.network/publicipaddresses?tabs=bicep#publicipaddresssku
resource pip 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: 'pip-vm-asa-petclinic-client'
  location: location
  sku: {
    name: 'Basic' // https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic' // Standard IP muste be STATIC
    deleteOption: 'Delete'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4    
  }  
}
output pipId string = pip.id
output hostname string = pip.properties.dnsSettings.fqdn
output pipGUID string = pip.properties.resourceGuid

resource NSG 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: nsgRuleName
        properties: {
          priority: 121
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: nsgRuleSourceAddressPrefix // Need to Allow access from local workstation
          sourcePortRange: '*'
          destinationAddressPrefix: '*' // 'VirtualNetwork'
          destinationPortRange: '22'
        }
      }  
      {
        name: 'Allow SSH from the GH Runner'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: ghRunnerIP // // Need to Allow the GH Runner IP
          destinationAddressPrefix: '*' // 'VirtualNetwork' 
          access: 'Allow'
          priority: 142
          direction: 'Inbound'
        }      
      }
    ]
  }
}
output nsgId string = NSG.id
output nsgsecurityRule0 string = NSG.properties.securityRules[0].name
output nsgsecurityRule1 string = NSG.properties.securityRules[1].name

// https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networkinterfaces?tabs=bicep
resource NIC1 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  location: location
  name: nicName
  properties: {
    enableAcceleratedNetworking: false // Standard_B2s, which is not compatible with enabling accelerated networking on network interface(s) on the VM
    ipConfigurations: [
      {
        name: 'ipcfg-vm-asa-petcli'
        properties: {
          publicIPAddress: {
            id: pip.id // https://github.com/Azure/bicep/issues/285
          }
          privateIPAllocationMethod: 'Dynamic'
          primary: true
          subnet: {
            id: infrastructureSubnetID
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: NSG.id
    }
  }
}

output nicId string = NIC1.id
// output nicPublicIPAddressId string = NIC1.properties.ipConfigurations[0].properties.publicIPAddress.id

// https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines?tabs=bicep
resource linuxVM 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: linuxVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: linuxVMName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: publisher
        offer: offer
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: NIC1.id
        }
      ]
    }
  }
}

output adminUsername string = adminUsername
output sshCommand string = 'ssh ${adminUsername}@${pip.properties.dnsSettings.fqdn}'

// https://docs.microsoft.com/en-us/azure/templates/microsoft.devtestlab/schedules?tabs=bicep
resource AutoShutdownSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${linuxVMName}'
  location: location
  properties: {
    dailyRecurrence: {
      time: '19:00'
    }
    notificationSettings: {
      emailRecipient: autoShutdownNotificationEmail
      notificationLocale: 'EN'
      status: 'Enabled'
      timeInMinutes: 30
    }
    status: 'Enabled'
    targetResourceId: linuxVM.id
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'Romance Standard Time'
  }
}


/*
resource nsgrule 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = {
  name: nsgRuleName
  parent: nsg
  properties: {
    description: 'description'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '3389'
    sourceAddressPrefix: 'xxx'
    access: 'Allow'
    priority: 121
    direction: 'Inbound'
  }
}
*/

/*
# az vm list-sizes --location $location --output table
# az vm image list-publishers --location $location --output table | grep -i "Microsoft"
# az vm image list-offers --publisher MicrosoftWindowsServer --location $location --output table
# az vm image list --publisher MicrosoftWindowsServer --offer WindowsServer --location $location --output table --all

# az vm image list-publishers --location $location --output table | grep -i Canonical
# az vm image list-offers --publisher Canonical --location $location --output table
# az vm image list --publisher Canonical --offer UbuntuServer --location $location --output table --all
# az vm image list --publisher Canonical --offer 0001-com-ubuntu-server-focal --location northeurope --output table --all
# az vm image list --publisher Canonical --offer 0001-com-ubuntu-pro-jammy --location northeurope --output table --all

# az vm image list-publishers --location $location --output table | grep -i RedHat
# az vm image list-offers --publisher RedHat --location $location --output table
# az vm image list --publisher RedHat --offer rh-rhel-8-main-2 --location $location --output table --all

# az vm image list-publishers --location northeurope --output table | grep -i "Mariner"
# az vm image list-offers --publisher MicrosoftCBLMariner --location $location --output table
# az vm image list --publisher MicrosoftCBLMariner --offer cbl-mariner --location $location --output table --all

# --image The name of the operating system image as a URN alias, URN, custom image name or ID, custom image version ID, or VHD blob URI. In addition, it also supports shared gallery image. This parameter is required unless using `--attach-os-disk.`  Valid URN format: "Publisher:Offer:Sku:Version". For more information, see https: //docs.microsoft.com/azure/virtual-machines/linux/cli-ps-findimage.  Values from: az vm image list, az vm image show, az sig image-version show-shared.
# --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:20.04.202203220

az vm image list-offers --publisher MicrosoftWindowsDesktop --location $location --output table
az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-11 --location $location --output table --all

# --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:20.04.202203220

az vm create --name $self_hosted_runner_vm_name \
    --image UbuntuLTS \
    --admin-username adm_run \
    --resource-group $rg_name \
    --vnet-name $vnet_name \
    --subnet $appSubnet \
    --nsg $nsg \
    --size Standard_B1s \
    --zone 1 \
    --location $location \
    --ssh-key-values ~/.ssh/$ssh_key.pub
    # --generate-ssh-keys


*/

