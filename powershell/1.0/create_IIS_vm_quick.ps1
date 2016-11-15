#Version           : 1.0.4
#Name              : Azure
#Author            : Hatem ASum
#PowerShellVersion : 3.0
. "F:\c9\powershell\1.0\Configure-AzureWinRMHTTPS.ps1"


##reference https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-ps-create-preconfigure-windows-resource-manager-vms/
$startTime=Get-Date
###### Global Variables
$ResourceGroupName = "C9-IIS-ASPdemo"
$Location = "eastus"
$LocationName="East US"

###### Storage	##storageName must be small letters!!
$StorageName = "c9iisaspsa"
$StorageType = "Standard_LRS"

###### Network
$InterfaceName = "C9IISNic"
$Subnet1Name = "C9IISSubnet1"
$VNetName = "C9IISVNet"
$VNetAddressPrefix = "10.0.0.0/16"
$VNetSubnetAddressPrefix = "10.0.0.0/24"

###### Compute
$VMName = "C9IISDEMO"
$ComputerName = "C9IISDEMO"
$VMSize = "Standard_A1"
$OSDiskName = $VMName + "OSDisk"
$USERNAME ="azpicks"
$PASSWORD ="P@$$w0rd"
###### VM Image
$Publisher ='MicrosoftWindowsServer'
$Offer = 'WindowsServer'
$Sku = '2012-R2-Datacenter'
$Version = '4.0.20160126'
$domainName="c9-iis-asp-demo"
$DNSName=$domainName+'.'+$Location+'.cloudapp.azure.com'

#$Publisher = (Get-AzureRmVMImagePublisher -Location $locationname) | select -ExpandProperty PublisherName | where { $_ -like 'MicrosoftWindowsServer' }
#$Offer = (Get-AzureRmVMImageOffer -Location $locationname -PublisherName $Publisher) | select -ExpandProperty Offer | where { $_ -like 'WindowsServer' }
#$Sku = (Get-AzureRmVMImageSku -Location $locationname -PublisherName $Publisher -Offer $Offer) | select  -ExpandProperty Skus |where { $_ -like '2012-R2-Datacenter' }
#$Version = (Get-AzureRmVMImage -Location $locationname -Offer $Offer -PublisherName $Publisher -Skus $Sku) | select -ExpandProperty Version | where { $_ -like '4.0.20160126' }
$vm_image = Get-AzureRmVMImage -Location $LocationName -PublisherName $Publisher -Offer $Offer -Skus $Sku  -Version $Version

# Create New Resource Group
Write-Host "Creating Resource Group : Start " -ForegroundColor Yellow
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Verbose
Write-Host "Creating Resource Group : Done " -ForegroundColor Green

# Create New Storage Account
Write-Host "Creating Storage Account : Start " -ForegroundColor Yellow
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -Type $StorageType -Location $Location -Verbose
Write-Host "Creating Storage Account : Done " -ForegroundColor Green

# Network (set Public static ip, and configure local network)
Write-Host "Configure Network : Start " -ForegroundColor Yellow
$PIp = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -DomainNameLabel $domainName -Location $Location -AllocationMethod Static
$SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $VNetSubnetAddressPrefix
$VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
$Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIp.Id
Write-Host "Configure Network : Done" -ForegroundColor Green
# Compute

## Setup local VM object
#$Credential = Get-Credential
$SecurePassword = ConvertTo-SecureString $PASSWORD -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($USERNAME, $SecurePassword);
##create object "VMImage"
$VMImage = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
$VMCustomData = "echo 'Hello World'"
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VMImage = Set-AzureRmVMOperatingSystem -VM $VMImage -Windows -ComputerName $ComputerName -Credential $Credential -CustomData $VMCustomData  -WinRMHttp -ProvisionVMAgent
$VMImage = Set-AzureRmVMSourceImage -VM $VMImage -PublisherName $Publisher -Offer $Offer -Skus $Sku -Version $Version
$VMImage = Add-AzureRmVMNetworkInterface -VM $VMImage -Id $Interface.Id
$VMImage = Set-AzureRmVMOSDisk -VM $VMImage -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage 

## Create the VM in Azure
Write-Host "Creating VM : Start " -ForegroundColor Yellow
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VMImage -Verbose
Write-Host "Creating VM : Done " -ForegroundColor Green

Get-AzureRmRemoteDesktopFile -ResourceGroupName $ResourceGroupName -Name $VMName -LocalPath "F:\$vmname.rdp"
#Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force
#Remove-AzureRmResourceGroup -Name $ResourceGroupName -Force

Configure-AzureWinRMHTTPS $VMName $ResourceGroupName $DNSName

Invoke-Command -ComputerName $DNSName -Credential $credential -UseSSL -SessionOption (New-PsSessionOption -SkipCACheck -SkipCNCheck)  -FilePath F:\c9\powershell\1.0\Install_IIS.ps1 
$finishTime=Get-Date
($finishTime - $startTime).ToString()

Write-Host "Done !! " -ForegroundColor Green
