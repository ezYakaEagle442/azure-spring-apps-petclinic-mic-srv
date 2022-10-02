---
page_type: sample
languages:
- java
products:
- Azure Spring Apps
description: "Deploy Spring Boot apps using Azure Spring Apps & MySQL"
urlFragment: "spring-petclinic-microservices"
---

# Deploy Spring Boot apps using Azure Spring Apps and MySQL 

Azure Spring Apps enables you to easily run a Spring Boot applications on Azure.

This quickstart shows you how to deploy an existing Java Spring Apps application to Azure. When 
you're finished, you can continue to manage the application via the Azure CLI or switch to using the 
Azure Portal.

* [Deploy Spring Boot apps using Azure Spring Apps and MySQL](#deploy-spring-boot-apps-using-azure-spring-apps-and-mysql)
  * [What will you experience](#what-will-you-experience)
  * [What you will need](#what-you-will-need)
  * [Install the Azure CLI extension](#install-the-azure-cli-extension)
  * [Clone and build the repo](#clone-and-build-the-repo)
  * [Unit 1 - Deploy and monitor Spring Boot apps](#unit-1---deploy-and-monitor-spring-boot-apps)
  * [Unit 2 - AUTOMATE deployments using GitHub Actions](#unit-2---automate-deployments-using-github-actions)
  * [Unit 3 - Manage application secrets using Azure KeyVault](#unit-3---manage-application-secrets-using-azure-keyvault)
  * [Next Steps](#next-steps)

## What will you experience
You will:
- Build existing Spring Boot applications
- Provision an Azure Spring Apps service instance. If you prefer Terraform, you may also provision using Terraform, see [`README-terraform`](./terraform/README-terraform.md) or **[Bicep](./iac/bicep/README.md)**. Check [API breaking changes](https://docs.microsoft.com/en-us/azure/spring-cloud/breaking-changes)
- Deploy applications to Azure
- Bind applications to Azure Database for MySQL
- Open the application
- Monitor applications
- Automate deployments using GitHub Actions
- Manage application secrets using Azure KeyVault

## What you will need

In order to deploy a Java app to cloud, you need 
an Azure subscription. If you do not already have an Azure 
subscription, you can activate your 
[MSDN subscriber benefits](https://azure.microsoft.com/pricing/member-offers/msdn-benefits-details/) 
or sign up for a 
[free Azure account]((https://azure.microsoft.com/free/)).

In addition, you will need the following:

| [Azure CLI version 2.17.1 or higher](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) 
| [Java 11](https://learn.microsoft.com/java/openjdk/download)
| [Maven](https://maven.apache.org/download.cgi) 
| [MySQL CLI](https://dev.mysql.com/downloads/shell/)
| [Git](https://git-scm.com/)
| [`jq` utility](https://stedolan.github.io/jq/download/)
|

Note -  The [`jq` utility](https://stedolan.github.io/jq/download/). On Windows, download [this Windows port of JQ](https://github.com/stedolan/jq/releases) and add the following to the `~/.bashrc` file: 
           ```bash
           alias jq=<JQ Download location>/jq-win64.exe
           ```

Note - The Bash shell. While Azure CLI should behave identically on all environments, shell 
semantics vary. Therefore, only bash can be used with the commands in this repo. 
To complete these repo steps on Windows, use Git Bash that accompanies the Windows distribution of 
Git. Use only Git Bash to complete this training on Windows. Do not use WSL.

### OR Use Azure Cloud Shell

Or, you can use the Azure Cloud Shell. Azure hosts Azure Cloud Shell, an interactive shell 
environment that you can use through your browser. You can use the Bash with Cloud Shell 
to work with Azure services. You can use the Cloud Shell pre-installed commands to run the 
code in this README without having to install anything on your local environment. To start Azure 
Cloud Shell: go to [https://shell.azure.com](https://shell.azure.com), or select the 
Launch Cloud Shell button to open Cloud Shell in your browser.

To run the code in this article in Azure Cloud Shell:

1. Start Cloud Shell.

1. Select the Copy button on a code block to copy the code.

1. Paste the code into the Cloud Shell session by selecting Ctrl+Shift+V on Windows and Linux or by selecting Cmd+Shift+V on macOS.

1. Select Enter to run the code.

## Install the Azure CLI extension

Install the Azure Spring Apps extension for the Azure CLI using the following command

```bash
    az extension add --name spring
```
Note - `spring` CLI extension `1.1.2` or later is a pre-requisite to enable the
latest Java in-process agent for Application Insights. If you already 
have the CLI extension, you may need to upgrade to the latest

```bash
    az extension update --name spring
```

## Clone and build the repo

### Create a new folder and clone the sample app repository to your Azure Cloud account  

```bash
    mkdir source-code
    git clone https://github.com/ezYakaEagle442/azure-spring-apps-petclinic-mic-srv
```

### Change directory and build the project with Maven

TODO: add ASA Maven Plugin [https://github.com/microsoft/azure-maven-plugins/wiki/Azure-Spring-Apps:-Deploy](https://github.com/microsoft/azure-maven-plugins/wiki/Azure-Spring-Apps:-Deploy)
 
```bash
    cd azure-spring-apps-petclinic-mic-srv
    mvn clean package -DskipTests -Denv=cloud
```
This will take a few minutes.


## Deploy Azure Spring Apps instance and the petclinic microservices Apps with IaC

See **[Bicep](./iac/bicep/README.md)**

<span style="color:red">**Be aware that the MySQL DB is NOT deployed in a VNet but network FireWall Rules are Set. So ensure to allow ASA Outbound IP addresses or check the option "Allow public access from any Azure service within Azure to this server" in the Azure Portal / your MySQL DB / Networking / Firewall rules**</span>

## Deploy a Windows VM Client in the VNet

### VM
```sh

nsg="vnet-azure-spring-apps-snet-app-nsg-${location}" # "nsg-app-client"
YOUR_RG="rg-iac-asa-petclinic-mic-srv" # "rg-asa-apps-petclinic"

az network nsg rule create --access Allow --destination-port-range 3389 --name "Allow RDP from local dev station" --nsg-name $nsg -g ${YOUR_RG} --priority 121 --source-address-prefixes "<Your IP Adress>"

# az vm list-sizes --location $location --output table
# az vm image list-publishers --location $location --output table | grep -i "Microsoft"
# az vm image list-offers --publisher MicrosoftWindowsServer --location $location --output table
# az vm image list --publisher MicrosoftWindowsServer --offer WindowsServer --location $location --output table

# az vm image list-publishers --location $location --output table | grep -i Canonical
# az vm image list-offers --publisher Canonical --location $location --output table
# az vm image list --publisher Canonical --offer UbuntuServer --location $location --output table
# az vm image list --publisher Canonical --offer 0001-com-ubuntu-server-focal --location northeurope --output table --all

# az vm image list-publishers --location northeurope --output table | grep -i "Mariner"
# az vm image list-offers --publisher MicrosoftCBLMariner --location $location --output table
# az vm image list --publisher MicrosoftCBLMariner --offer cbl-mariner --location $location --output table --all

# --image The name of the operating system image as a URN alias, URN, custom image name or ID, custom image version ID, or VHD blob URI. In addition, it also supports shared gallery image. This parameter is required unless using `--attach-os-disk.`  Valid URN format: "Publisher:Offer:Sku:Version". For more information, see https: //docs.microsoft.com/azure/virtual-machines/linux/cli-ps-findimage.  Values from: az vm image list, az vm image show, az sig image-version show-shared.
# --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:20.04.202203220

az vm image list-offers --publisher MicrosoftWindowsDesktop --location $location --output table
az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-11 --location $location --output table

win_client_vm_name="vm-win-pet-cli" #Windows computer name cannot be more than 15 characters long,
win_vm_admin_username="adm_asa"
win_vm_admin_pwd="IsTrator4224!" # The password length must be between 12 and 123. 
rg_name="rg-iac-asa-petclinic-mic-srv"
vnet_name="vnet-azure-spring-apps"
appSubnet="snet-app"
nsg="vnet-azure-spring-apps-snet-app-nsg-${location}"

az vm create --name $win_client_vm_name \
    --image MicrosoftWindowsDesktop:windows-11:win11-21h2-pron:22000.556.220303 \
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

network_interface_id=$(az vm show --name $win_client_vm_name -g $rg_name --query 'networkProfile.networkInterfaces[0].id' -o tsv)
echo "ASA Pet Clinic windows Client VM Network Interface ID :" $network_interface_id

network_interface_private_ip=$(az resource show --ids $network_interface_id \
    --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
echo "Network Interface private IP :" $network_interface_private_ip

network_interface_pub_ip_id=$(az resource show --ids $network_interface_id \
    --query 'properties.ipConfigurations[0].properties.publicIPAddress.id' -o tsv)

network_interface_pub_ip=$(az network public-ip show -g $rg_name --id $network_interface_pub_ip_id --query "ipAddress" -o tsv)
echo "Network Interface public  IP :" $network_interface_pub_ip
```
You can now use RDP to connect to your Windows client VM.

Note: you can not setup WSL2 on all Azure VM , D_v3 should support nested virtualization , see :
- [https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/nested-virtualization](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/nested-virtualization)
- [https://docs.microsoft.com/en-us/answers/questions/442463/error-when-enabling-wsl2-in-azure-vm.html](https://docs.microsoft.com/en-us/answers/questions/442463/error-when-enabling-wsl2-in-azure-vm.html)




Now, the Bicep IaC should have configured the Azure Private DNS Zone, as explained in the [docs](https://learn.microsoft.com/en-us/azure/spring-apps/access-app-virtual-network?tabs=azure-portal)

```sh
rg_name="rg-iac-asa-petclinic-mic-srv"
rg_ASA_apps_name="rg-asa-apps-petclinic"
rg_ASA_svc_run_name="rg-asa-svc-run-petclinic"

ASA_INSTANCE_NAME="asa-aspetcliasa"
PRIVATE_DNS_ZONE="private.azuremicroservices.io"
ASA_PRIVATE_DNS_LINK_NAME="dns-lnk-asa"
vnet_name="vnet-azure-spring-apps"
az network private-dns zone create --name ${PRIVATE_DNS_ZONE} -g  $rg_name
az network private-dns link vnet list -g $rg_name --zone-name ${PRIVATE_DNS_ZONE}

vnet_id=$(az network vnet show --resource-group $rg_name --name $vnet_name --query id -o tsv)
echo "VNet Id :" $vnet_id

az network private-dns link vnet create \
  --resource-group $rg_name \
  --zone-name ${PRIVATE_DNS_ZONE} \
  --name $ASA_PRIVATE_DNS_LINK_NAME \
  --virtual-network $vnet_id \
  --registration-enabled false

private_dns_link_id=$(az network private-dns link vnet show --name $ASA_PRIVATE_DNS_LINK_NAME --zone-name ${PRIVATE_DNS_ZONE} -g $rg_name --query "id" --output tsv)
echo "Azure Spring Apps Private-Link DNS ID :" $private_dns_link_id

APPS_AKS_LB_FRONT_IP_ID=$(az network lb show --name "kubernetes-internal" -g $rg_ASA_apps_name --query 'frontendIpConfigurations[0].id' --output tsv)
APPS_AKS_LB_FRONT_IP_NAME=$(az network lb show --name "kubernetes-internal" -g $rg_ASA_apps_name --query "frontendIpConfigurations[0].name" --output tsv)

ASA_SVC_RUN_AKS_LB_FRONT_IP_ID=$(az network lb show --name "kubernetes-internal" -g $rg_ASA_svc_run_name --query 'frontendIpConfigurations[0].id' --output tsv)
ASA_SVC_RUN_AKS_LB_FRONT_IP_NAME=$(az network lb show --name "kubernetes-internal" -g $rg_ASA_svc_run_name --query "frontendIpConfigurations[0].name" --output tsv)

ASA_APPS_LB_PRV_IP=$(az network lb frontend-ip show --lb-name "kubernetes-internal" --name $APPS_AKS_LB_FRONT_IP_NAME -g $rg_ASA_apps_name --query privateIpAddress -o tsv)

ASA_SVC_RUN_LB_PRV_IP=$(az network lb frontend-ip show --lb-name "kubernetes-internal" --name $ASA_SVC_RUN_AKS_LB_FRONT_IP_NAME -g $rg_ASA_svc_run_name --query privateIpAddress -o tsv)

az network private-dns record-set a create --name $ASA_INSTANCE_NAME --zone-name ${PRIVATE_DNS_ZONE}  -g $rg_name

az network private-dns record-set a add-record -g $rg_name \
  --record-set-name $ASA_INSTANCE_NAME \
  --zone-name ${PRIVATE_DNS_ZONE} \
  --ipv4-address $ASA_APPS_LB_PRV_IP

az network private-dns record-set a add-record -g $rg_name \
  --record-set-name "$ASA_INSTANCE_NAME.test" \
  --zone-name ${PRIVATE_DNS_ZONE} \
  --ipv4-address $ASA_APPS_LB_PRV_IP

#az network private-dns record-set a add-record -g $rg_name \
#  --record-set-name $xxx \
#  --zone-name ${PRIVATE_DNS_ZONE} \
#  --ipv4-address $ASA_SVC_RUN_LB_PRV_IP
```

Now Validate private DNS link connection
From the windows client VM inside athe Azure Spring Apps VNet with private zone, then nslookup will resolve to the private ip.

```sh
nslookup ${ASA_INSTANCE_NAME}.${PRIVATE_DNS_ZONE}
nslookup $ASA_INSTANCE_NAME
```


### Create MySQL Database

Create a MySQL database in Azure Database for MySQL.

```sh
    // create mysql server
    az mysql server create --resource-group ${RESOURCE_GROUP} \
     --name ${MYSQL_SERVER_NAME}  --location ${REGION} \
     --admin-user ${MYSQL_SERVER_ADMIN_NAME} \
     --admin-password ${MYSQL_SERVER_ADMIN_PASSWORD} \
     --sku-name GP_Gen5_2 \
     --ssl-enforcement Disabled \
     --version 5.7
    
    // allow access from Azure resources
    az mysql server firewall-rule create --name allAzureIPs \
     --server ${MYSQL_SERVER_NAME} \
     --resource-group ${RESOURCE_GROUP} \
     --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
    
    // allow access from your dev machine for testing
    az mysql server firewall-rule create --name devMachine \
     --server ${MYSQL_SERVER_NAME} \
     --resource-group ${RESOURCE_GROUP} \
     --start-ip-address <ip-address-of-your-dev-machine> \
     --end-ip-address <ip-address-of-your-dev-machine>
    
    // increase connection timeout
    az mysql server configuration set --name wait_timeout \
     --resource-group ${RESOURCE_GROUP} \
     --server ${MYSQL_SERVER_NAME} --value 2147483
    
    // SUBSTITUTE values
    mysql -u ${MYSQL_SERVER_ADMIN_LOGIN_NAME} \
     -h ${MYSQL_SERVER_FULL_NAME} -P 3306 -p
    
    Enter password:
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 64379
    Server version: 5.6.39.0 MySQL Community Server (GPL)
    
    Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.
    
    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.
    
    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
    
    mysql> CREATE DATABASE petclinic;
    Query OK, 1 row affected (0.10 sec)
    
    mysql> CREATE USER 'root' IDENTIFIED BY 'petclinic';
    Query OK, 0 rows affected (0.11 sec)
    
    mysql> GRANT ALL PRIVILEGES ON petclinic.* TO 'root';
    Query OK, 0 rows affected (1.29 sec)
    
    mysql> CALL mysql.az_load_timezone();
    Query OK, 3179 rows affected, 1 warning (6.34 sec)
    
    mysql> SELECT name FROM mysql.time_zone_name;
    ...
    
    mysql> quit
    Bye
    
    
    az mysql server configuration set --name time_zone \
     --resource-group ${RESOURCE_GROUP} \
     --server ${MYSQL_SERVER_NAME} --value "US/Pacific"
```


### Deploy Spring Boot applications and set environment variables

Deploy Spring Boot applications to Azure 
<span style="color:red">**You do NOT need to deploy a self-hosted GitHub Action runner in the VM created previously**</span>

```bash
# https://github.com/MicrosoftDocs/azure-docs/issues/90220 : production deployment must be created first

az spring app deployment create --name production --app admin-server -s asa-aspetcliasa --artifact-path  spring-petclinic-admin-server/target/spring-petclinic-admin-server-2.6.3.jar -g rg-iac-asa-petclinic-mic-srv --version 2.6.3 --runtime-version Java_11 --cpu 500m --memory 512Mi --instance-count 3 --disable-probe false 

# This query is wrong but should returns as many instance-count as decleared at app deployment creation : 3
appInstances="$(az spring app show --name admin-server -g rg-iac-asa-petclinic-mic-srv --service asa-aspetcliasa --query "[?properties.activeDeployment.name=='production'].properties.activeDeployment.properties.instances.name" -o tsv | head -1)"

az spring app logs --name discovery-server \
                         --resource-group rg-iac-asa-petclinic-mic-srv \
                         --service asa-aspetcliasa \
                         --deployment default \
                         --instance discovery-server-default-16-58fbbf89bf-47kvr \
                         --limit 2048 \
                         --lines 100 \
                         --since 60m


az spring app deploy --name admin-server --artifact-path spring-petclinic-admin-server/target/spring-petclinic-admin-server-2.6.3.jar --jvm-options="-Xms512m -Xmx512m -Dspring.profiles.active=mysql" -g rg-iac-asa-petclinic-mic-srv --service asa-aspetcliasa --verbose

az spring app show --name api-gateway -g rg-iac-asa-petclinic-mic-srv --service asa-aspetcliasa

az spring app logs --name admin-server --resource-group rg-iac-asa-petclinic-mic-srv --service asa-aspetcliasa --deployment production --instance admin-server-production-12-7c4c79b658-8bvfb --limit 2048 --lines 100 --since 60m

az spring app show-deploy-log --deployment production --name admin-server -g rg-iac-asa-petclinic-mic-srv --service asa-aspetcliasa

```

```bash
    az spring app show --name ${API_GATEWAY} | grep url
```

Navigate to the URL provided by the previous command to open the Pet Clinic application.
    
![](./media/petclinic.jpg)

### Monitor Spring Boot applications

#### Use the Petclinic application and make a few REST API calls

Open the Petclinic application and try out a few tasks - view pet owners and their pets, 
vets, and schedule pet visits:

```bash
open https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/
```

You can also `curl` the REST API exposed by the Petclinic application. The admin REST
API allows you to create/update/remove items in Pet Owners, Pets, Vets and Visits.
You can run the following curl commands:

```bash
curl -X GET https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners
curl -X GET https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/4
curl -X GET https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/ 
curl -X GET https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/petTypes
curl -X GET https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/3/pets/4
curl -X GET https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/6/pets/8/
curl -X GET https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/vet/vets
curl -X GET https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/visit/owners/6/pets/8/visits
curl -X GET https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/visit/owners/6/pets/8/visits
```

#### Get the log stream for API Gateway and Customers Service

Use the following command to get the latest 100 lines of app console logs from Customers Service. 
```bash
az spring app logs -n ${CUSTOMERS_SERVICE} --lines 100
```
By adding a `-f` parameter you can get real-time log streaming from the app. Try log streaming for the API Gateway app.
```bash
az spring app logs -n ${API_GATEWAY} -f
```
You can use `az spring app logs -h` to explore more parameters and log stream functionalities.

#### Open Actuator endpoints for API Gateway and Customers Service apps

Spring Boot includes a number of additional features to help you monitor and manage your application when you push it to production ([Spring Boot Actuator: Production-ready Features](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#actuator)). You can choose to manage and monitor your application by using HTTP endpoints or with JMX. Auditing, health, and metrics gathering can also be automatically applied to your application.

Actuator endpoints let you monitor and interact with your application. By default, Spring Boot application exposes `health` and `info` endpoints to show arbitrary application info and health information. Apps in this project are pre-configured to expose all the Actuator endpoints.

You can try them out by opening the following app actuator endpoints in a browser:

```bash
open https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/actuator/
open https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/actuator/env
open https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/actuator/configprops

open https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator
open https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator/env
open https://${AZURE_SPRING_APPS_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator/configprops
```

#### Start monitoring Spring Boot apps and dependencies - in Application Insights

Open the Application Insights created by Azure Spring Apps and start monitoring 
Spring Boot applications. You can find the Application Insights in the same Resource Group where
you created an Azure Spring Apps service instance.

Navigate to the `Application Map` blade:
![](./media/distributed-tracking-new-ai-agent.jpg)

Navigate to the `Performance` blade:
![](./media/petclinic-microservices-performance.jpg)

Navigate to the `Performance/Dependenices` blade - you can see the performance number for dependencies, 
particularly SQL calls:
![](./media/petclinic-microservices-insights-on-dependencies.jpg)

Click on a SQL call to see the end-to-end transaction in context:
![](./media/petclinic-microservices-end-to-end-transaction-details.jpg)

Navigate to the `Failures/Exceptions` blade - you can see a collection of exceptions:
![](./media/petclinic-microservices-failures-exceptions.jpg)

Click on an exception to see the end-to-end transaction and stacktrace in context:
![](./media/end-to-end-transaction-details.jpg)

Navigate to the `Metrics` blade - you can see metrics contributed by Spring Boot apps, 
Spring Cloud modules, and dependencies. 
The chart below shows `gateway-requests` (Spring Cloud Gateway), `hikaricp_connections`
 (JDBC Connections) and `http_client_requests`.
 
![](./media/petclinic-microservices-metrics.jpg)

Spring Boot registers a lot number of core metrics: JVM, CPU, Tomcat, Logback... 
The Spring Boot auto-configuration enables the instrumentation of requests handled by Spring MVC.
All those three REST controllers `OwnerResource`, `PetResource` and `VisitResource` have been instrumented by the `@Timed` Micrometer annotation at class level.

* `customers-service` application has the following custom metrics enabled:
  * @Timed: `petclinic.owner`
  * @Timed: `petclinic.pet`
* `visits-service` application has the following custom metrics enabled:
  * @Timed: `petclinic.visit`

You can see these custom metrics in the `Metrics` blade:
![](./media/petclinic-microservices-custom-metrics.jpg)

You can use the Availability Test feature in Application Insights and monitor 
the availability of applications:
![](./media/petclinic-microservices-availability.jpg)

Navigate to the `Live Metrics` blade - you can see live metrics on screen with low latencies < 1 second:
![](./media/petclinic-microservices-live-metrics.jpg)

#### Start monitoring Petclinic logs and metrics in Azure Log Analytics

Open the Log Analytics that you created - you can find the Log Analytics in the same 
Resource Group where you created an Azure Spring Apps service instance.

In the Log Analyics page, selects `Logs` blade and run any of the sample queries supplied below 
for Azure Spring Apps.

Type and run the following Kusto query to see application logs:
```sql
    AppPlatformLogsforSpring 
    | where TimeGenerated > ago(24h) 
    | limit 500
    | sort by TimeGenerated
```

Type and run the following Kusto query to see `customers-service` application logs:
```sql
    AppPlatformLogsforSpring 
    | where AppName has "customers"
    | limit 500
    | sort by TimeGenerated
```

Type and run the following Kusto query  to see errors and exceptions thrown by each app:
```sql
    AppPlatformLogsforSpring 
    | where Log contains "error" or Log contains "exception"
    | extend FullAppName = strcat(ServiceName, "/", AppName)
    | summarize count_per_app = count() by FullAppName, ServiceName, AppName, _ResourceId
    | sort by count_per_app desc 
    | render piechart
```

Type and run the following Kusto query to see all in the inbound calls into Azure Spring Apps:
```sql
    AppPlatformIngressLogs
    | project TimeGenerated, RemoteAddr, Host, Request, Status, BodyBytesSent, RequestTime, ReqId, RequestHeaders
    | sort by TimeGenerated
```

Type and run the following Kusto query to see all the logs from the managed Spring Apps
Config Server managed by Azure Spring Apps:
```sql
    AppPlatformSystemLogs
    | where LogType contains "ConfigServer"
    | project TimeGenerated, Level, LogType, ServiceName, Log
    | sort by TimeGenerated
```

Type and run the following Kusto query to see all the logs from the managed Spring Apps
Service Registry managed by Azure Spring Apps:
```sql
    AppPlatformSystemLogs
    | where LogType contains "ServiceRegistry"
    | project TimeGenerated, Level, LogType, ServiceName, Log
    | sort by TimeGenerated
```

## Unit-2 - Automate deployments using GitHub Actions
### Prerequisites 
To get started with deploying this sample app from GitHub Actions, please:
1. Complete the sections above with your MySQL, Azure Spring Apps instances and apps created.
2. Fork this repository and turn on GitHub Actions in your fork

Read :
- [https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)
- [https://github.com/actions/virtual-environments](https://github.com/actions/virtual-environments)
- [https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-java-with-maven](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-java-with-maven)
- []()

### Prepare secrets in your Key Vault

Read those doc/samples below :
- [https://github.com/Azure-Samples/azure-spring-boot-samples/tree/spring-cloud-azure_4.0.0/keyvault/spring-cloud-azure-starter-keyvault-secrets](https://github.com/Azure-Samples/azure-spring-boot-samples/tree/spring-cloud-azure_4.0.0/keyvault/spring-cloud-azure-starter-keyvault-secrets)
- [https://microsoft.github.io/spring-cloud-azure/current/reference/html/index.html#secret-management](https://microsoft.github.io/spring-cloud-azure/current/reference/html/index.html#secret-management)

The Config-server uses the config declared on the repo at [https://github.com/ezYakaEagle442/spring-petclinic-microservices-config/blob/main/application.yml](https://github.com/ezYakaEagle442/spring-petclinic-microservices-config/blob/main/application.yml) and need a Service Principal to be able to read secrets from KeyVault.
  'Key Vault Administrator'
  'Key Vault Reader'
  'Key Vault Secrets User' 

```bash
az ad sp create-for-rbac --role "Key Vault Reader" --scopes /subscriptions/${SUBSCRIPTION}/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.KeyVault/vaults/<KEY_VAULT>  > git-cnf-spn.txt
```

Then the KV access policies must be set to allow the above SPN to access your KV. This should be set already in Azure Bicep.



If you do not have a Key Vault yet, run the following commands to provision a Key Vault:
```bash
    az keyvault create --name ${KEY_VAULT} -g ${RESOURCE_GROUP}
```

Add the MySQL secrets to your Key Vault:
```bash
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL_SERVER_NAME" --value ${MYSQL_SERVER_NAME}
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-SERVER-FULL-NAME" --value ${MYSQL_SERVER_FULL_NAME}
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-SERVER-ADMIN-NAME" --value ${MYSQL_SERVER_ADMIN_NAME}
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-SERVER-ADMIN-LOGIN-NAME" --value ${MYSQL_SERVER_ADMIN_LOGIN_NAME}
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-SERVER-ADMIN-PASSWORD" --value ${MYSQL_SERVER_ADMIN_PASSWORD}
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-DATABASE-NAME" --value ${MYSQL_DATABASE_NAME}
```

Create a service principle with enough scope/role to manage your Azure Spring Apps instance:
```bash
    az ad sp create-for-rbac --role contributor --scopes /subscriptions/${SUBSCRIPTION} --sdk-auth > spn.txt
```
With results:
```json
    {
        "clientId": "<GUID>",
        "clientSecret": "<GUID>",
        "subscriptionId": "<GUID>",
        "tenantId": "<GUID>",
        "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
        "resourceManagerEndpointUrl": "https://management.azure.com/",
        "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
        "galleryEndpointUrl": "https://gallery.azure.com/",
        "managementEndpointUrl": "https://management.core.windows.net/"
    }
```
```bash
    #  For GitHub Action Runner: https://aka.ms/azadsp-cli
    appName="gha_run"
    # other way to create the SPN :
    SP_PWD=$(az ad sp create-for-rbac --name $appName --role contributor --scopes /subscriptions/${SUBSCRIPTION} --query password --output tsv)
    #SP_ID=$(az ad sp show --id http://$appName --query objectId -o tsv)
    #SP_ID=$(az ad sp list --all --query "[?appDisplayName=='${appName}'].{appId:appId}" --output tsv)
    SP_ID=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName}'].{id:appId}" --output tsv)
    TENANT_ID=$(az ad sp list --show-mine --query "[?appDisplayName=='${appName}'].{t:appOwnerTenantId}" --output tsv)
```

Add them as secrets to your Key Vault:
```bash
    az keyvault secret set --vault-name ${KEY_VAULT} --name "AZURE-CREDENTIALS-FOR-SPRING" --file spn.txt # --value "<results above>"

    az keyvault secret set --vault-name ${KEY_VAULT} --name "GHA-RUN-SPN-APP" --value $SP_ID
    az keyvault secret set --vault-name ${KEY_VAULT} --name "GHA-RUN-SPN-PWD" --value $SP_PWD
    az keyvault secret set --vault-name ${KEY_VAULT} --name "GHA-RUN-SPN-TNT" --value $TENANT_ID
```

### Grant access to Key Vault with Service Principal
To generate a key to access the Key Vault, execute command below:
```bash
    az ad sp create-for-rbac --role contributor --scopes /subscriptions/${SUBSCRIPTION}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.KeyVault/vaults/${KEY_VAULT} --sdk-auth
```
Then, follow [the steps here](https://docs.microsoft.com/azure/spring-cloud/spring-cloud-github-actions-key-vault#add-access-policies-for-the-credential) to add access policy for the Service Principal.

```sh
az keyvault set-policy -n $KV_NAME --secret-permissions get list --spn <clientId from the Azure SPN JSON>
```

In the end, add this service principal as secret named "AZURE_CREDENTIALS" in your forked GitHub repo following [the steps here](https://docs.microsoft.com/azure/spring-cloud/how-to-github-actions?pivots=programming-language-java#set-up-github-repository-and-authenticate-1).

You can also read [Use GitHub Actions to connect to Azure documentation](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows) to add the AZURE_CREDENTIALS to your repo.

Also add your AZURE_SUBSCRIPTION to your GH repo secrets / Actions secrets / Repository secrets

### Customize your workflow
Read [GitHub Action for deploying to Azure Spring Apps](https://github.com/marketplace/actions/azure-spring-cloud)
Finally, edit the workflow file `.github/workflows/action.yml` in your forked repo to fill in the Azure Spring Apps instance name, and Key Vault name that you just created:
```yml
env:
  AZURE_SPRING_APPS_SERVICE: azure-spring-apps-name # name of your Azure Spring Apps instance
  KEYVAULT: your-keyvault-name # customize this
  DEPLOYMENT_JVM_OPTIONS: -Dazure.keyvault.uri=https://<your-keyvault-name>.vault.azure.net -Xms512m -Xmx1024m -Dspring.profiles.active=mysql,key-vault,cloud

```


Once you push this change, you will see GitHub Actions triggered to build and deploy all the apps in the repo to your Azure Spring Apps instance.
![](./media/automate-deployments-using-github-actions.png)

## Unit-3 - Manage application secrets using Azure KeyVault

Use Azure Key Vault to store and load secrets to connect to MySQL database.

### Create Azure Key Vault and store secrets

If you skipped the [Automation step](#automate-deployments-using-github-actions), create an Azure Key Vault and store database connection secrets.

```bash
    az keyvault create --name ${KEY_VAULT} -g ${RESOURCE_GROUP}
    export KEY_VAULT_URI=$(az keyvault show --name ${KEY_VAULT} | jq -r '.properties.vaultUri')
```

Store database connection secrets in Key Vault.

```bash
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-SERVER-FULL-NAME" --value ${MYSQL_SERVER_FULL_NAME}
        
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-DATABASE-NAME" --value ${MYSQL_DATABASE_NAME}
        
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-SERVER-ADMIN-LOGIN-NAME" --value ${MYSQL_SERVER_ADMIN_LOGIN_NAME}
        
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-SERVER-ADMIN-PASSWORD" --value ${MYSQL_SERVER_ADMIN_PASSWORD}
```                      

### Enable Managed Identities for applications in Azure Spring Apps

Enable System Assigned Identities for applications and export identities to environment.

```bash
    az spring app identity assign --name ${CUSTOMERS_SERVICE}
    export CUSTOMERS_SERVICE_IDENTITY=$(az spring app show --name ${CUSTOMERS_SERVICE} | jq -r '.identity.principalId')
    
    az spring app identity assign --name ${VETS_SERVICE}
    export VETS_SERVICE_IDENTITY=$(az spring app show --name ${VETS_SERVICE} | jq -r '.identity.principalId')
    
    az spring app identity assign --name ${VISITS_SERVICE}
    export VISITS_SERVICE_IDENTITY=$(az spring app show --name ${VISITS_SERVICE} | jq -r '.identity.principalId')
```

### Grant Managed Identities with access to Azure Key Vault

Add an access policy to Azure Key Vault to allow Managed Identities to read secrets.

```bash
    az keyvault set-policy --name ${KEY_VAULT} \
        --object-id ${CUSTOMERS_SERVICE_IDENTITY} --secret-permissions get list
        
    az keyvault set-policy --name ${KEY_VAULT} \
        --object-id ${VETS_SERVICE_IDENTITY} --secret-permissions get list
        
    az keyvault set-policy --name ${KEY_VAULT} \
        --object-id ${VISITS_SERVICE_IDENTITY} --secret-permissions get list
```

### Activate applications to load secrets from Azure Key Vault

Activate applications to load secrets from Azure Key Vault.

```bash
    # DO NOT FORGET to replace the value for "azure.keyvault.uri" JVM startup parameter with your Key Vault URI
    az spring app update --name ${CUSTOMERS_SERVICE} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql,key-vault -Dazure.keyvault.uri=https://petclinic-keyvault.vault.azure.net/' \
        --env
    
    # DO NOT FORGET to replace the value for "azure.keyvault.uri" JVM startup parameter with your Key Vault URI    
    az spring app update --name ${VETS_SERVICE} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql,key-vault -Dazure.keyvault.uri=https://petclinic-keyvault.vault.azure.net/' \
        --env
    
    # DO NOT FORGET to replace the value for "azure.keyvault.uri" JVM startup parameter with your Key Vault URI       
    az spring app update --name ${VISITS_SERVICE} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql,key-vault -Dazure.keyvault.uri=https://petclinic-keyvault.vault.azure.net/' \
        --env
```

## Troubleshoot

If you face this error :
```console
Caused by: java.sql.SQLException: Connections using insecure transport are prohibited while --require_secure_transport=ON.
```

It might be related to the Spring Config configured at [https://github.com/Azure-Samples/spring-petclinic-microservices-config/blob/master/application.yml](https://github.com/Azure-Samples/spring-petclinic-microservices-config/blob/master/application.yml) which on-profile: mysql is set with datasource url :
jdbc:mysql://${MYSQL_SERVER_FULL_NAME}:3306/${MYSQL_DATABASE_NAME}?**useSSL=false**

Check the [MySQL connector doc](https://dev.mysql.com/doc/connector-j/5.1/en/connector-j-reference-using-ssl.html)
Your JBCC URL should look like this for instance:
url: jdbc:mysql://localhost:3306/petclinic?useSSL=false
url: jdbc:mysql://${MYSQL_SERVER_FULL_NAME}:3306/${MYSQL_DATABASE_NAME}??useSSL=true
url: jdbc:mysql://petclinic-mysql-server.mysql.database.azure.com:3306/petclinic?useSSL=true
url: jdbc:mysql://petclinic-mysql-server.mysql.database.azure.com:3306/petclinic?useSSL=true&requireSSL=true&enabledTLSProtocols=TLSv1.2&verifyServerCertificate=true    



## Next Steps

In this quickstart, you've deployed an existing Spring Boot-based app using Azure CLI, Terraform and GitHub Actions. To learn more about Azure Spring Apps, go to:

- [Azure Spring Apps](https://azure.microsoft.com/en-us/products/spring-apps)
- [Azure Spring Apps docs](https://learn.microsoft.com/en-us/azure/spring-apps/)
- [Deploy Spring microservices from scratch](https://github.com/microsoft/azure-spring-cloud-training)
- [Deploy existing Spring microservices](https://github.com/Azure-Samples/azure-spring-cloud)
- [Azure for Java Cloud Developers](https://learn.microsoft.com/en-us/azure/developer/java)
- [Spring Cloud for Azure](https://spring.io/projects/spring-cloud-azure)
- [Spring Cloud](https://spring.io/projects/spring-cloud)

## Credits

This Spring microservices sample is forked from 
[Azure Samples spring-petclinic/spring-petclinic-microservices](https://github.com/Azure-Samples/spring-petclinic-microservices) - see [Petclinic README](./README-petclinic.md). 

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
