## Deploy a Self-Hosted Runner in the VNet

### VM
```sh
az network nsg rule create --access Allow --destination-port-range 22 --source-address-prefixes "Your IP Adress" --name "Allow SSH from local dev station" --nsg-name $nsg -g ${YOUR_RG} --priority 142

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

ssh-keygen -t rsa -b 4096 -N $ssh_passphrase -f ~/.ssh/$ssh_key -C "youremail@groland.grd"

# --image The name of the operating system image as a URN alias, URN, custom image name or ID, custom image version ID, or VHD blob URI. In addition, it also supports shared gallery image. This parameter is required unless using `--attach-os-disk.`  Valid URN format: "Publisher:Offer:Sku:Version". For more information, see https: //docs.microsoft.com/azure/virtual-machines/linux/cli-ps-findimage.  Values from: az vm image list, az vm image show, az sig image-version show-shared.
# --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:20.04.202203220


az vm image list-publishers --location $location --output table | grep -i Canonical
az vm image list-offers --publisher Canonical --location $location --output table
az vm image list --publisher Canonical --offer UbuntuServer --location $location --output table --all
az vm image list --publisher Canonical --offer 0001-com-ubuntu-server-focal --location northeurope --output table --all

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

network_interface_id=$(az vm show --name $self_hosted_runner_vm_name -g $rg_name --query 'networkProfile.networkInterfaces[0].id' -o tsv)
echo "Self-hosted Runner VM Network Interface ID :" $network_interface_id

network_interface_private_ip=$(az resource show --ids $network_interface_id \
  --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' -o tsv)
echo "Network Interface private IP :" $network_interface_private_ip

network_interface_pub_ip_id=$(az resource show --ids $network_interface_id \
  --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.publicIPAddress.id' -o tsv)

network_interface_pub_ip=$(az network public-ip show -g $rg_name --id $network_interface_pub_ip_id --query "ipAddress" -o tsv)
echo "Network Interface public  IP :" $network_interface_pub_ip

# test
ssh -i ~/.ssh/$ssh_key $admin_username@$network_interface_pub_ip

# Once you have successfully connected to the VM, install the DevTools

# AZ CLI + AzureSpring Cloud extension
sudo apt-get install -y apt-transport-https
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt-get update
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | 
    sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-get update
sudo apt-get install azure-cli
az upgrade
az version

az bicep install
az bicep upgrade
az bicep version
az bicep --help

az login
az account set --subscription "<your subscription name>"
az provider register --namespace 'Microsoft.AppPlatform'
az extension add --name spring-cloud

# Java
# https://docs.microsoft.com/en-us/java/openjdk/containers
# https://docs.microsoft.com/en-us/java/openjdk/install#install-on-ubuntu 
# Valid values are only '18.04' and '20.04'
# For other versions of Ubuntu, please use the tar.gz package
ubuntu_release=`lsb_release -rs`
wget https://packages.microsoft.com/config/ubuntu/${ubuntu_release}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb

sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install msopenjdk-11 --yes
java -version

# jq
sudo apt-get install jq --yes

# Maven
sudo apt install maven --yes
mvn -version

# Git
git clone https://github.com/ezYakaEagle442/azure-spring-cloud-petclinic-mic-srv

# Maven Build
cd azure-spring-cloud-petclinic-mic-srv
mvn clean package -DskipTests -Denv=cloud

# Self-hosted Runner requires Docker
# see also https://docs.github.com/en/actions/hosting-your-own-runners/monitoring-and-troubleshooting-self-hosted-runners#troubleshooting-containers-in-self-hosted-runners
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

 sudo apt-get update
 sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io --yes
sudo docker --version

service --status-all
sudo service docker start
sudo service docker status

sudo systemctl is-active docker.service

# If your job fails with the following error:https://docs.github.com/en/actions/hosting-your-own-runners/monitoring-and-troubleshooting-self-hosted-runners#checking-the-docker-permissions
# dial unix /var/run/docker.sock: connect: permission denied
# https://gist.github.com/didof/be97b600ba3f9d1725b8c6d1c643c745

# https://docs.github.com/en/actions/hosting-your-own-runners/configuring-the-self-hosted-runner-application-as-a-service#installing-the-service
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status

# To view the systemd configuration, you can locate the service file here: /etc/systemd/system/actions.runner.<org>-<repo>.<runnerName>.service
ll /etc/systemd/system/actions.runner*
sudo systemctl show -p User actions.runner.octo-org-octo-repo.runner01.service
sudo systemctl show -p User actions.runner.ezYakaEagle442-azure-spring-cloud-petclinic-mic-srv.gh-action-runner.service

systemctl --type=service | grep actions.runner
sudo journalctl -u actions.runner.octo-org-octo-repo.runner01.service -f

```

```sh
ll /var/run/docker.sock
```

```console
srw-rw---- 1 root docker 0 Mar 23 17:10 /var/run/docker.sock=
```

```sh
less /etc/passwd | grep -i "<your username>"
less /etc/group | grep -i "docker"
sudo usermod -a -G docker <your username>

# https://gist.github.com/didof/be97b600ba3f9d1725b8c6d1c643c745
# to apply changes, log in and out
sudo su
sudo su [USER]

# and restart docker
sudo systemctl restart docker

#4. Give read and write permissions to docker socket
sudo chmod 666 /var/run/docker.sock

id
```


Read [https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners](https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners)

- Downloading and extracting the self-hosted runner application.
- Running the config script to configure the self-hosted runner application and register it with GitHub Actions. The config script requires the destination URL and an automatically-generated time-limited token to authenticate the request.
- Check your [Limits & Runner quotas](https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration#usage-limits) 
```console

--------------------------------------------------------------------------------
|        ____ _ _   _   _       _          _        _   _                      |
|       / ___(_) |_| | | |_   _| |__      / \   ___| |_(_) ___  _ __  ___      |
|      | |  _| | __| |_| | | | | '_ \    / _ \ / __| __| |/ _ \| '_ \/ __|     |
|      | |_| | | |_|  _  | |_| | |_) |  / ___ \ (__| |_| | (_) | | | \__ \     |
|       \____|_|\__|_| |_|\__,_|_.__/  /_/   \_\___|\__|_|\___/|_| |_|___/     |
|                                                                              |
|                       Self-hosted runner registration                        |
|                                                                              |
--------------------------------------------------------------------------------

# Authentication


√ Connected to GitHub

# Runner Registration

Enter the name of the runner group to add this runner to: [press Enter for Default]

Enter the name of runner: [press Enter for gh-action-runner]

This runner will have the following labels: 'self-hosted', 'Linux', 'X64'
Enter any additional labels (ex. label-1,label-2): [press Enter to skip]

√ Runner successfully added
√ Runner connection is good

# Runner settings

Enter name of work folder: [press Enter for _work]

√ Settings Saved.

```

The self-hosted runner application must be active for the runner to accept jobs. When the runner application is connected to GitHub and ready to receive jobs, you will see the following message on the machine's terminal.
```console
√ Connected to GitHub

Current runner version: '2.288.1'
2022-03-23 16:37:04Z: Listening for Jobs
```

You can monitor the status of the self-hosted runner application and its activities. Log files are kept in the _diag directory


After completing the steps to add a self-hosted runner, the runner and its status are now listed under "Runners".
#### CleanUp: Remove the self-hosted Runner
Read [https://docs.github.com/en/actions/hosting-your-own-runners/removing-self-hosted-runners#removing-a-runner-from-a-repository](https://docs.github.com/en/actions/hosting-your-own-runners/removing-self-hosted-runners#removing-a-runner-from-a-repository)
