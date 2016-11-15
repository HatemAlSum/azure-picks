#Version           : 1.0.4
#Name              : Azure
#Author            : Hatem ASum
#PowerShellVersion : 3.0
##reference https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-ps-create-preconfigure-windows-resource-manager-vms/
Workflow Create-Steps{
$CPASS = ConvertTo-SecureString 'CLOUD]dkh84wrv' -AsPlainText -Force
$Ccred = New-Object System.Management.Automation.PSCredential ('halsum@cloud9ers.com', $CPASS);
Add-AzureRmAccount -Credential $Ccred
###### Global Variables
$ResourceGroupName = "AZRD-SQL-DEMO"
$Location = "eastus"
$LocationName="East US"

###### Storage
##storageName must be small letters!!
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
$USERNAME ="azpicks"
$PASSWORD ="P@$$w0rd"
###### VM Image
$Publisher ='MicrosoftSQLServer'
$Offer = 'SQL2014SP1-WS2012R2'
$Sku = 'Enterprise'
$Version = '12.0.4100'
$vm_image = Get-AzureRmVMImage -Location $LocationName -PublisherName $Publisher -Offer $Offer -Skus $Sku  -Version $Version

$domainName="azrd-sql-demo"

# Create New Resource Group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
#Create Parallel Workflow Steps

Parallel
{
    Sequence
    {

        # Create New Storage Account
        'BEFORE STA:';$Workflow:StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -Type $StorageType -Location $Location

        "AFTER STA : ($StorageAccount.PrimaryEndpoints.Blob.ToString() -eq $null) ";$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"

    }
    Sequence
    {
    <#
        # Network (set Public static ip, and configure local network)
        $Workflow:PIp = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -DomainNameLabel $domainName -Location $Location -AllocationMethod Static
        $Workflow:SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $VNetSubnetAddressPrefix
        $Workflow:VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
        $Workflow:pInterface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Workflow:VNet.Subnets[0].Id -PublicIpAddressId $Workflow:PIp.Id

        # Pre Compute
        ## Setup local VM object
        $Workflow:SecurePassword = ConvertTo-SecureString $PASSWORD -AsPlainText -Force
        $Workflow:Credential = New-Object System.Management.Automation.PSCredential ($USERNAME, $SecurePassword);
        $Workflow:VMImage = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
        $Workflow:VMCustomData = "echo 'Hello World'"

        $Workflow:vm_config= Set-AzureRmVMOperatingSystem -VM $VMImage -Windows -ComputerName $ComputerName -Credential $Credential -CustomData $VMCustomData -ProvisionVMAgent
        $Workflow:vm_config= Set-AzureRmVMSourceImage -VM $VMImage -PublisherName $Publisher -Offer $Offer -Skus $Sku -Version $Version
        $Workflow:vm_config= Add-AzureRmVMNetworkInterface -VM $VMImage -Id $pInterface.Id
    #>
    }
}


## Create the VM in Azure
#$vm_config= Set-AzureRmVMOSDisk -VM $VMImage -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage
#New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VMImage
#Remove-AzureRmResourceGroup -Name $ResourceGroupName -Force
}

Create-Steps
