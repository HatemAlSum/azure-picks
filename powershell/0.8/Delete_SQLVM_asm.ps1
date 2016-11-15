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
$vnetConfig='D:\c9\SqlNetworkConfig.txt'
$RDPfilesdir = 'D:\c9\'
$RDPendpoint = 3388
$PSendpoint = 5985
$iamgeFamily= "SQL Server 2014 SP1 Enterprise*"
$svrname="C9SQL2014SP1"
$instancesize = 'Small'


Switch-AzureMode -Name AzureServiceManagement

Stop-AzureVM -ServiceName $servicename -Name $svrname -Force
Remove-AzureVM  -ServiceName $servicename -Name $svrname -DeleteVHD
Remove-AzureDns -Name $dnsname -ServiceName $servicename -Force
Remove-AzureVNetGateway -VNetName $vnet
Remove-AzureVNetConfig
$vhds = Get-AzureStorageBlob -Container vhds
foreach($vhd in $vhds)
{
    if ($vhd.name -like 'c9sql*')
    {
         Remove-AzureStorageBlob -Container vhds -Blob $vhd.name -Force
    }
}
Remove-AzureStorageAccount -StorageAccountName $storageaccount
Remove-AzureService -ServiceName $servicename -Force
Remove-AzureAffinityGroup -Name $resourcegroup

# Delete all resource groups
Switch-AzureMode AzureResourceManager
Remove-AzureResourceGroup 'Default-Networking'
Remove-AzureResourceGroup 'Default-Storage-EastUS'
Switch-AzureMode -Name AzureServiceManagement
