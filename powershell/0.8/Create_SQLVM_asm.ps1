#Version           : 0.8.11
#Name              : Azure
#Author            : Microsoft Corporation
#PowerShellVersion : 3.0

# Set your Variables before working
$resourcegroup ="C9SQLServers"
$servicename ="c9sql"
$storageaccount="c9sqlserversa"
$location="East US"
$dnsname = 'C9SQL-DNS'
$vnet = 'C9SQL-VNET'
$subnet = 'Subnet-1'
$global:adminname = 'azpicks'
$global:adminpassword = 'P@$$w0rd'
$vnetConfig='F:\c9\powershell\0.8\SqlNetworkConfig.txt'
$RDPfilesdir = 'F:\c9\'
$RDPendpoint = 3388 
$PSendpoint = 5985
$iamgeFamily= "SQL Server 2014 SP1 Enterprise*"
$svrname="C9SQL2014SP1"
$instancesize = 'Small'

Switch-AzureMode -Name AzureServiceManagement

$azure_subscription= (Get-AzureSubscription  | Where-Object { $_.IsDefault -eq "True"}) | Select-Object -first 1

#Create Affinity Group
Write-Host "Create Affinity Group" -ForegroundColor Green
New-AzureAffinityGroup -Name $resourcegroup  -Location $location



#Create Network Configuration
Write-Host "Create DNS and virtual network" -ForegroundColor Green
Set-AzureVNetConfig $vnetConfig
$dns = New-AzureDns -IPAddress 10.0.0.4 -Name $dnsname

#Create Storage Account
Write-Host "Create Storage Account" -ForegroundColor Green
New-AzureStorageAccount -StorageAccountName $storageaccount -AffinityGroup $resourcegroup #-Location $location 
# Set Storage account as default
Set-AzureSubscription -SubscriptionName $azure_subscription.SubscriptionName -CurrentStorageAccountName $storageaccount

#Prepare VM Configuration
Write-Host "Get SqlServer Image" -ForegroundColor Green
$sqlVmImage = ((Get-AzureVMImage | Where-Object { $_.ImageFamily -like $imageFamily }| Where-Object { $_.Location.Split(";") -contains $location} | Sort-Object -Property PublishedDate -Descending) | Select-Object -first 1 ).ImageName

$sqlVMconfig = New-AzureVMConfig -name $svrname -InstanceSize $instancesize -ImageName $sqlVmImage | Add-AzureProvisioningConfig -Windows -AdminUsername $adminname -Password $adminpassword | Set-AzureEndpoint -Name "RemoteDesktop" -Protocol tcp -LocalPort 3389 -PublicPort $RDPendpoint | Set-AzureEndpoint -Name "PowerShell" -Protocol tcp -LocalPort 5986 -PublicPort $PSendpoint | Set-AzureSubnet -SubnetNames $subnet | Set-AzureVMBGInfoExtension -ReferenceName 'BGInfo'

#Create VM
New-AzureVM -ServiceName $servicename -Location $location -VMs $sqlVMconfig -VNetName $vnet -WaitForBoot

$VMStatus = Get-AzureVM -ServiceName $servicename -Name $svrname
While ($VMStatus.InstanceStatus -ne "ReadyRole")
{
  Start-Sleep -Seconds 10
  $VMStatus = Get-AzureVM -ServiceName $servicename -Name $svrname
}

# Download the RDP file for this VM
Get-AzureRemoteDesktopFile -ServiceName $servicename -Name $svrname -LocalPath "$RDPfilesdir$svrname.rdp" 
Write-Host "Done ....." -ForegroundColor Green
