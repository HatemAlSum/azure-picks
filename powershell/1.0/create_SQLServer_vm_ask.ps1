#Version           : 1.0.4
#Name              : Azure
#Author            : Hatem ASum
#PowerShellVersion : 3.0
##reference https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-ps-create-preconfigure-windows-resource-manager-vms/
###### Global Variables
$ResourceGroupName = "AZRD-SQL-DEMO"
$Location = "eastus"
$locationname="East US"

###### Storage	##storageName must be small letters!!
$StorageName = "c9sqlsa"
$StorageType = "Standard_LRS"

###### Network
$InterfaceName = "C9SqlNic"
$Subnet1Name = "C9SqlSubnet1"
$VNetName = "C9SqlVNet"
$VNetAddressPrefix = "10.0.0.0/16"
$VNetSubnetAddressPrefix = "10.0.0.0/24"

###### Compute
$VMName = "C9SQL2014"
$ComputerName = "C9SQL2014srv"
$VMSize = "Standard_A1"
$OSDiskName = $VMName + "OSDisk"
###### VM Image
$Publisher = (Get-AzureRmVMImagePublisher -Location $locationname) | select -ExpandProperty PublisherName | where { $_ -like 'MicrosoftSQLServer' }
$Offer = (Get-AzureRmVMImageOffer -Location $locationname -PublisherName $Publisher) | select -ExpandProperty Offer | where { $_ -like 'SQL2014SP1*' }
$Sku = (Get-AzureRmVMImageSku -Location $locationname -PublisherName $Publisher -Offer $Offer) | select  -ExpandProperty Skus |where { $_ -like 'Enterprise' }
$Version = (Get-AzureRmVMImage -Location $locationname -Offer $Offer -PublisherName $Publisher -Skus $Sku) | select -ExpandProperty Version | where { $_ -like '12.0.4100' }

#$vm_image = (Get-AzureRmVMImage -Location "East US" -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "14.04.2-LTS" | Sort-Object -Property Version -Descending ) | Select-Object -First 1
#$vm_image = Get-AzureRmVMImage -Location "East US" -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "14.04.2-LTS"  -Version "14.04.201507060"


$domName="azrd-ps-demo"

# Create New Resource Group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

# Create New Storage Account
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -Type $StorageType -Location $Location

# Network (set Public static ip, and configure local network)
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -DomainNameLabel $domName -Location $Location -AllocationMethod Static
$SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $VNetSubnetAddressPrefix
$VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
$Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIp.Id

# Compute

## Setup local VM object
#list of images(publisher,verion,Skus ...)here https://azure.microsoft.com/en-us/documentation/articles/resource-groups-vm-searching/
$Credential = Get-Credential
##create object "VMImage"
$VMImage = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
$VMImage = Set-AzureRmVMOperatingSystem -VM $VMImage -Linux -ComputerName $ComputerName -Credential $Credential
$VMImage = Set-AzureRmVMSourceImage -VM $VMImage -PublisherName $Publisher -Offer $Offer -Skus $Sku -Version $Version
$VMImage = Add-AzureRmVMNetworkInterface -VM $VMImage -Id $Interface.Id
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VMImage = Set-AzureRmVMOSDisk -VM $VMImage -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage

## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VMImage
