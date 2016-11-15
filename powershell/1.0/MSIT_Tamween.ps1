﻿#Version           : 1.0.4
#Name              : Azure
#Author            : Hatem ASum
#PowerShellVersion : 3.0

##reference https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-ps-create-preconfigure-windows-resource-manager-vms/

###### Global Variables

$ResourceGroupName = "MSITRG"
$AvalabiltySetName = "MSITAS"
$Location = "westeurope"
###### Storage
$StorageName = "msitmainsa"
$StorageType = "Standard_LRS"
###### Network
$Subnet1Name = "msitSubNet"
$VNetNamepub = "msitVNet"
$VNetAddressPrefixpub = "192.168.66.0/24"
$VNetSubnetAddressPrefixpub = "192.168.66.0/24"

###### Compute
$VMList = ('msit-large1','msit-large2')
$VMSize = "Standard_D3_v2"
$USERNAME ="azpicks"
$PASSWORD ="P@$$w0rd"
###### VM Image
$Publisher = 'OpenLogic'
#(Get-AzureRmVMImagePublisher -Location "West US") | select -ExpandProperty PublisherName | where { $_ -like '*canonical*' }
$Offer ='CentOs'
#(Get-AzureRmVMImageOffer -Location "West US" -PublisherName $Publisher) | select -ExpandProperty Offer | where { $_ -like '*UbuntuServer*' }
$Sku ='7.1'
#(Get-AzureRmVMImageSku -Location "West US" -PublisherName $Publisher -Offer $Offer) | select  -ExpandProperty Skus |where { $_ -like '*14.04.2-LTS*' }
$Version ='7.1.20160308'
#(Get-AzureRmVMImage -Location "West US" -Offer $Offer -PublisherName $Publisher -Skus $Sku) | select -ExpandProperty Version | where { $_ -like 'latest' }
$domName="msitsite"

# Create New Resource Group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
# Create Availability Set
New-AzureRmAvailabilitySet -Location $Location -Name $AvalabiltySetName -ResourceGroupName $ResourceGroupName
$AvalabiltySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName

# Create New Storage Account
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -Type $StorageType -Location $Location

# Network (set Public static ip, and configure local network)
$SubnetConfig1 = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $VNetSubnetAddressPrefixpub
$VNet1 = New-AzureRmVirtualNetwork -Name $VNetNamepub -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefixpub -Subnet $SubnetConfig1


# Compute
$SecurePassword = ConvertTo-SecureString $PASSWORD -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($USERNAME, $SecurePassword);
foreach( $vm in $VMList)
{
   $VMName = $vm
   $ComputerName = $vm
   $OSDiskName = $VMName + "OSDisk"
   ##create object "VMImage"
   $VMImage = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $AvalabiltySet.Id
   $VMImage = Set-AzureRmVMOperatingSystem -VM $VMImage -Linux -ComputerName $ComputerName -Credential $Credential
   $VMImage = Set-AzureRmVMSourceImage -VM $VMImage -PublisherName $Publisher -Offer $Offer -Skus $Sku -Version $Version
   $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
   $VMImage = Set-AzureRmVMOSDisk -VM $VMImage -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage
   $InterfaceName1 = $vm +"NIC"

   $PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Static
   $Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet1.Subnets[0].Id  -PublicIpAddressId $PIp.Id
   $VMImage = Add-AzureRmVMNetworkInterface -VM $VMImage -Id $Interface1.Id
   ## Create the VM in Azure
   New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VMImage
}

