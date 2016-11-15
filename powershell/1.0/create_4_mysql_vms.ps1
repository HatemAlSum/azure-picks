#Version           : 1.0.4
#Name              : Azure
#Author            : Hatem ASum
#PowerShellVersion : 3.0
###### Global Variables
$startTime=Get-Date
$ResourceGroupName = "mysql-DEMO"
$Location = "westeurope"

###### Storage ##storageName must be small letters!!
$StorageName = "mysqlc9storageac"
$StorageType = "Standard_LRS"

###### Network
$InterfaceName = "mysqlc9Interface"
$Subnet1Name = "mysqlc9DemoSubnet1"
$VNetName = "mysqlc9DemoVNet"
$VNetAddressPrefix = "10.0.0.0/16"
$VNetSubnetAddressPrefix = "10.0.0.0/24"

###### Compute
$VMSize = "Standard_D1"
$USERNAME ="azpicks"
$PASSWORD ="P@$$w0rd"
###### VM Image
$Publisher = 'Canonical'
$Offer = 'UbuntuServer'
$Sku = '14.04.2-LTS'
$Version = '14.04.201507060'
$domName="azrd-c9-mysql"

# Create New Resource Group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

# Create New Storage Account
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -Type $StorageType -Location $Location

# Network (set Public static ip, and configure local network)
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -DomainNameLabel $domName -Location $Location -AllocationMethod Static
$SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $VNetSubnetAddressPrefix
$VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
#$Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIp.Id

# Compute

## Setup local VM object
$SecurePassword = ConvertTo-SecureString $PASSWORD -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($USERNAME, $SecurePassword);

$mysqlvms = ("mysqlclustermgmtnode","mysqlclusterdatanodeA","mysqlclusterdatanodeB","mysqlclustersqlnode")
foreach( $vm in $mysqlvms)
{
    $VMName = $vm + "_C9"
    $ComputerName = $vm
    $OSDiskName = $VMName + "OSDisk"

    ##create object "VMImage"
    $VMImage = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
    $VMImage = Set-AzureRmVMOperatingSystem -VM $VMImage -Linux -ComputerName $ComputerName -Credential $Credential
    $VMImage = Set-AzureRmVMSourceImage -VM $VMImage -PublisherName $Publisher -Offer $Offer -Skus $Sku -Version $Version

    $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
    $VMImage = Set-AzureRmVMOSDisk -VM $VMImage -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage
    $InterfaceName = $vm +"NIC"

    if ( $vm -eq 'mysqlclustermgmtnode'){
        $Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id  -PublicIpAddressId $PIp.Id
    }
    else{
        $Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id
    }
    $VMImage = Add-AzureRmVMNetworkInterface -VM $VMImage -Id $Interface.Id

    ## Create the VM in Azure
    New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VMImage
}
$finishTime=Get-Date
($afterTime - $startTime).ToString()
#removeAll
$startTime2=Get-Date
Remove-AzureRmResourceGroup -Name $ResourceGroupName -Force
$afterTime2=Get-Date
($afterTime2 - $startTime2).ToString()
($afterTime2 - $startTime).ToString()
