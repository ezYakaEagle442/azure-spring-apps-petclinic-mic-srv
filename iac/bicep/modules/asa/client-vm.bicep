// See https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.compute/vm-simple-windows/main.bicep

@description('A UNIQUE name')
@maxLength(23)
param appName string = 'petcliasa${uniqueString(deployment().name)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

param vnetName string = 'vnet-asa'

@description('Resource ID of a subnet for infrastructure components. This subnet must be in the same VNET as the subnet defined in runtimeSubnetId. Must not overlap with any other provided IP ranges.')
param infrastructureSubnetID string

@description('Windows client VM deployed to the VNet. Computer name cannot be more than 15 characters long')
param windowsVMName string = 'vm-winasapetcli'

@secure()
@description('The VM Admin user name')
param adminUsername string

@secure()
@description('The VM password length must be between 12 and 123.')
param adminPassword string 

param nsgName string = 'nsg-asa-${appName}-app-client'
param nsgRuleName string = 'Allow RDP from local dev station'

@description('The CIDR or source IP range. Asterisk "*" can also be used to match all source IPs. Default tags such as "VirtualNetwork", "AzureLoadBalancer" and "Internet" can also be used. If this is an ingress rule, specifies where network traffic originates from.')
param nsgRuleSourceAddressPrefix string

param nicName string = 'nic-asa-${appName}-client-vm'

@description('emailRecipient ainformed before the VM shutdown')
param autoShutdownNotificationEmail string

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing =  {
  name: vnetName
}
output vnetId string = vnet.id
output vnetGUID string = vnet.properties.resourceGuid
output subnetId string = vnet.properties.subnets[0].id

// https://docs.microsoft.com/en-us/azure/templates/microsoft.network/publicipaddresses?tabs=bicep#publicipaddresssku
resource pip 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'pip-vm-asa-petclinic-client'
  location: location
  sku: {
    name: 'Basic' // https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic' // Standard IP muste be STATIC
    deleteOption: 'Delete'
  }
}
output pipId string = pip.id
output pipGUID string = pip.properties.resourceGuid
output pipAddress string = pip.properties.ipAddress

resource NSG 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: nsgRuleName
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: nsgRuleSourceAddressPrefix
          destinationAddressPrefix: 'VirtualNetwork' // pip.properties.ipAddress
          access: 'Allow'
          priority: 121
          direction: 'Inbound'
        }
      }
    ]
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networkinterfaces?tabs=bicep
resource NIC1 'Microsoft.Network/networkInterfaces@2021-08-01' = {
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

// https://github.com/bhummerstone/azure-templates/blob/master/arm/compute/vms/vmlargerdisk.json#L53
var unattendAutoLogonXML = '<AutoLogon><Password><Value>\'{adminPassword}\')</Value></Password><Domain></Domain><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>\'${adminUsername}\'</Username></AutoLogon>\')]'
var unattendFirstRunXML = '<FirstLogonCommands><SynchronousCommand><CommandLine>powershell.exe -Command Write-Output \\"select disk 0 \' select partition 1 \' extend\\" | Out-File C:\\diskpart.txt</CommandLine><Description>Create diskpart input file</Description><Order>1</Order></SynchronousCommand><SynchronousCommand><CommandLine>diskpart.exe /s C:\\diskpart.txt</CommandLine><Description>Extend partition</Description><Order>2</Order></SynchronousCommand></FirstLogonCommands>'

// XML is trying to set something in the "Microsoft-Windows-International-Core" component, which isn't exposed.
// the only accepted values for the settingName are AutoLogon and FirstLogonCommands as per https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines?tabs=bicep#additionalunattendcontent
// See also https://docs.microsoft.com/en-us/troubleshoot/system-center/vmm/regional-settings-default-english#resolution-2
// https://docs.microsoft.com/en-us/powershell/module/international/set-windefaultinputmethodoverride?view=windowsserver2022-ps
// https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-input-locales-for-windows-language-packs?view=windows-11
// ==> fr-FR: French (040c:0000040c)
// var unattendSetLocalRegion = '<settings pass=\\"oobeSystem\\"><component name=\\"Microsoft-Windows-International-Core\\" processorArchitecture=\\"amd64\\" publicKeyToken=\\"31bf3856ad364e35\\" language=\\"neutral\\" versionScope=\\"nonSxS\\" xmlns:wcm=\\"http://schemas.microsoft.com/WMIConfig/2002/State\\" xmlns:xsi=\\"http://www.w3.org/2001/XMLSchema-instance\\"><InputLocale>fr-FR</InputLocale><SystemLocale>fr-FR</SystemLocale><UILanguage>fr-FR</UILanguage><UILanguageFallback>fr-FR</UILanguageFallback><UserLocale>fr-FR</UserLocale></component></settings><cpi:offlineImage cpi:source=\\"wim:c:/install.wim#Windows 11 Pro\\" xmlns:cpi=\\"urn:schemas-microsoft-com:cpi\\" />'
var unattendSetLocalRegionFirstRunXML = '<FirstLogonCommands><SynchronousCommand><CommandLine> powershell.exe -Command Set-WinUserLanguageList -LanguageList fr-FR, en-US -Force</CommandLine><Description>Change language defaults</Description><Order>1</Order></SynchronousCommand></FirstLogonCommands>'

// see also https://github.com/stuartpreston/arm-vm-customregion
// https://docs.microsoft.com/en-us/windows/win32/intl/table-of-geographical-locations + https://docs.microsoft.com/en-us/powershell/module/international/set-winsystemlocale?view=windowsserver2022-ps
var customScript = 'Set-WinSystemLocale fr-FR\\r\\nSet-WinUserLanguageList -LanguageList fr-FR -Force\\r\\nSet-Culture -CultureInfo fr-FR\\r\\nSet-WinHomeLocation -GeoId 84\\r\\nRestart-Computer -Force'

// https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines?tabs=bicep
resource windowsVM 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: windowsVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    // userData: [base64(customScript)]
    osProfile: {
      computerName: windowsVMName // Defaults to the name of the VM.
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: base64(customScript)
      windowsConfiguration: { // https://github.com/Azure/bicep/issues/7520
        enableAutomaticUpdates: true
        patchSettings: {
          enableHotpatching: false // The selected VM Windows-11 image is not supported for hotpatching. Learn more at: https://aka.ms/HotpatchCompatibility
          patchMode: 'AutomaticByOS'
        }
        timeZone: 'Romance Standard Time' // GMT Standard Time ==> Run in CMD: tzutil /l https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-time-zones?view=windows-11
        // see sample at https://github.com/bhummerstone/azure-templates/blob/master/arm/compute/vms/vmlargerdisk.json#L183
        additionalUnattendContent: [
          /*
          {
            passName: 'OobeSystem'
            componentName: 'Microsoft-Windows-Shell-Setup'
            content: unattendAutoLogonXML
            settingName: 'AutoLogon'
          }
          {
            passName: 'OobeSystem'
            componentName: 'Microsoft-Windows-Shell-Setup'
            content: unattendFirstRunXML
            settingName: 'FirstLogonCommands'
          } 
          */  
          {
            passName: 'OobeSystem'
            componentName: 'Microsoft-Windows-Shell-Setup'
            content: unattendSetLocalRegionFirstRunXML
            settingName: 'FirstLogonCommands'
          }  
        ]
      }
    }
    licenseType: 'Windows_Client'
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-11'
        sku: 'win11-22h2-pro'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: NIC1.id
          properties: {
            // primary: contains(nic, 'Primary')
            deleteOption: 'Delete'
          }          
        }
        
      ]
    }
  }
}


// https://docs.microsoft.com/en-us/azure/templates/microsoft.devtestlab/schedules?tabs=bicep
resource AutoShutdownSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${windowsVMName}'
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
    targetResourceId: windowsVM.id
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
# az vm image list --publisher Canonical --offer UbuntuServer --location $location --output table
# az vm image list --publisher Canonical --offer 0001-com-ubuntu-server-focal --location northeurope --output table --all

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

win_client_vm_name="vm-win-pet-cli" #Windows computer name cannot be more than 15 characters long,
win_vm_admin_username="adm_asa"
win_vm_admin_pwd="XXX" # The password length must be between 12 and 123. 
rg_name="rg-iac-asa-petclinic-mic-srv"
vnet_name="vnet-azure-container-apps"
appSubnet="snet-app"
nsg="vnet-azure-container-apps-snet-app-nsg-${location}"

az vm create --name $win_client_vm_name \
    --image MicrosoftWindowsDesktop:windows-11:win11-21h2-pron:22000.739.220608 \
    --admin-username $win_vm_admin_username \
    --admin-password $win_vm_admin_pwd \
    --resource-group $rg_name \
    --vnet-name $vnet_name \
    --subnet $appSubnet \
    --nsg $nsg \
    --size Standard_B2s \
    --location $location \
    --output table
    # --zone 1
*/

