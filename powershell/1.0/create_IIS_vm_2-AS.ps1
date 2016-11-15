#Version           : 1.0.4
#Name              : Azure
#Author            : Hatem ASum
#PowerShellVersion : 3.0
. "F:\c9\powershell\1.0\Configure-AzureWinRMHTTPS.ps1"

$startTime=Get-Date
###### Global Variables
$ResourceGroupName = "MOF"
$AvalabiltySetName = "MOFIIS"
$Location = "westeurope"
###### Storage	##storageName must be small letters!!
$StorageName = "mofsa"
$StorageType = "Standard_LRS"
###### Network
$Subnet1Name = "MOFSubNet1"
$VNetNamepub = "MOFVNet"
$VNetAddressPrefixpub = "192.168.1.0/24"
$VNetSubnetAddressPrefixpub = "192.168.1.0/26"
$Subnet2Name = "MOFSubNet2"
$VNetAddressPrefixprv = "192.168.1.0/24"
$VNetSubnetAddressPrefixprv = "192.168.1.128/26"
###### Compute
$VMList = ('MOF-IIS-Node1','MOF-IIS-Node2')
$VMSize = "Standard_D2"
$USERNAME ="azpicks"
$PASSWORD ="P@$$w0rd"
###### VM Image
$Publisher ='MicrosoftWindowsServer'
$Offer = 'WindowsServer'
$Sku = '2012-R2-Datacenter'
$Version = '4.0.20160126'
$domainName="c9-iis-mof-demo"
$DNSName=$domainName+'.'+$Location+'.cloudapp.azure.com'
###### VM Image
#$Publisher = (Get-AzureRmVMImagePublisher -Location $locationname) | select -ExpandProperty PublisherName | where { $_ -like 'MicrosoftWindowsServer' }
#$Offer = (Get-AzureRmVMImageOffer -Location $locationname -PublisherName $Publisher) | select -ExpandProperty Offer | where { $_ -like 'WindowsServer' }
#$Sku = (Get-AzureRmVMImageSku -Location $locationname -PublisherName $Publisher -Offer $Offer) | select  -ExpandProperty Skus |where { $_ -like '2012-R2-Datacenter' }
#$Version = (Get-AzureRmVMImage -Location $locationname -Offer $Offer -PublisherName $Publisher -Skus $Sku) | select -ExpandProperty Version | where { $_ -like '4.0.20160126' }
#$vm_image = Get-AzureRmVMImage -Location $LocationName -PublisherName $Publisher -Offer $Offer -Skus $Sku  -Version $Version


# Create New Resource Group
Write-Host "Creating Resource Group : Start " -ForegroundColor Yellow
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Verbose
Write-Host "Creating Resource Group : Done " -ForegroundColor Green

# Create Availability Set
Write-Host "Creating Availability Set : Start " -ForegroundColor Yellow
New-AzureRmAvailabilitySet -Location $Location -Name $AvalabiltySetName -ResourceGroupName $ResourceGroupName
$AvalabiltySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName
Write-Host "Creating Availability Set : Done " -ForegroundColor Green
# Create New Storage Account
Write-Host "Creating Storage Account : Start " -ForegroundColor Yellow
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -Type $StorageType -Location $Location -Verbose
Write-Host "Creating Storage Account : Done " -ForegroundColor Green

# Network (set Public static ip, and configure local network)
Write-Host "Configure Network : Start " -ForegroundColor Yellow
$SubnetConfig1 = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $VNetSubnetAddressPrefixpub
$VNet1 = New-AzureRmVirtualNetwork -Name $VNetNamepub -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefixpub -Subnet $SubnetConfig1
Add-AzureRmVirtualNetworkSubnetConfig -Name $Subnet2Name -AddressPrefix $VNetSubnetAddressPrefixprv -VirtualNetwork $VNet1
$VNet1 = Set-AzureRmVirtualNetwork -VirtualNetwork $VNet1
Write-Host "Configure Network : Done " -ForegroundColor Green

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
   $VMCustomData = "echo 'Cloud9ers Implementation of MOF'"
   $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
   $VMImage = Set-AzureRmVMOperatingSystem -VM $VMImage -Windows -ComputerName $ComputerName -Credential $Credential -CustomData $VMCustomData  -WinRMHttp -ProvisionVMAgent
   $VMImage = Set-AzureRmVMSourceImage -VM $VMImage -PublisherName $Publisher -Offer $Offer -Skus $Sku -Version $Version
   $VMImage = Set-AzureRmVMOSDisk -VM $VMImage -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage 

   $InterfaceName1 = $vm +"Nic1"
   $InterfaceName2 = $vm +"Nic2"
   $PIp = New-AzureRmPublicIpAddress -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
   $Interface1 = New-AzureRmNetworkInterface -Name $InterfaceName1 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet1.Subnets[0].Id  -PublicIpAddressId $PIp.Id
   $Interface2 = New-AzureRmNetworkInterface -Name $InterfaceName2 -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet1.Subnets[1].Id
   $VMImage = Add-AzureRmVMNetworkInterface -VM $VMImage -Id $Interface1.Id
   $VMImage = Add-AzureRmVMNetworkInterface -VM $VMImage -Id $Interface2.Id
   $VMImage.NetworkProfile.NetworkInterfaces.Item(0).primary = $true

   ## Create the VM in Azure
   Write-Host "Creating VM : Start " -ForegroundColor Yellow
   New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VMImage -Verbose
   Write-Host "Creating VM : Done " -ForegroundColor Green
   Get-AzureRmRemoteDesktopFile -ResourceGroupName $ResourceGroupName -Name $VMName -LocalPath "F:\$vmname.rdp"
   Configure-AzureWinRMHTTPS $VMName $ResourceGroupName $ComputerName
   #Invoke-Command -ComputerName $DNSName -Credential $credential -UseSSL -SessionOption (New-PsSessionOption -SkipCACheck -SkipCNCheck)  -FilePath F:\c9\powershell\1.0\Install_IIS.ps1 
}
$finishTime=Get-Date
($finishTime - $startTime).ToString()

Write-Host "Done !! " -ForegroundColor Green

