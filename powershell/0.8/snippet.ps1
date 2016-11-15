
    # CODE BLOCK A - Calculated variables for storage and cloud service names
    # these must be globally unique

    # Generate unique names for storage and cloud service:
    $uniqueNumber = (Get-Date).Ticks.ToString().Substring(12)
    $StorageName = '20533lab12store' + $uniqueNumber
    $CloudsvcName1 = '20533lab12cloudsvc1' + $uniqueNumber
    $CloudsvcName2 = '20533lab12cloudsvc2' + $uniqueNumber

    Write-Output "Calculated variables: "
    Write-Output "Storage account name is: $StorageName"
    Write-Output "Cloud service 1 name is: $CloudsvcName1"
    Write-Output "Cloud service 2 name is: $CloudsvcName2 `n"

    # CODE BLOCK A - END


    # CODE BLOCK B - Get name of latest Windows Server 2012 R2 image and put into a variable

    $WinImage = (Get-AzureVMImage | where {$_.ImageFamily -like "Windows Server 2012 R2*"} | sort PublishedDate -Descending)[0].ImageName

    Write-Output "Retrieved variable: "
    Write-Output "Windows server image is: $WinImage `n"

    # CODE BLOCK B - END


    # CODE BLOCK C - Static variables taken from Azure Automation Assets

    $SubscriptionName = Get-AutomationVariable -Name 'SubscriptionName'
    $AdminName = Get-AutomationVariable -Name 'AdminName'
    $AdminPassword = Get-AutomationVariable -Name 'AdminPassword' 
    $Location = Get-AutomationVariable -Name 'Location'
    $Network = Get-AutomationVariable -Name 'Network'
    $Subnet = Get-AutomationVariable -Name 'Subnet'

    Write-Output "Asset variables: "
    Write-Output "Subscription name is: $SubscriptionName"
    Write-Output "Administrator name is: $AdminName"
    Write-Output "Administrator password is: $AdminPassword"
    Write-Output "Location is: $Location `n"

    # CODE BLOCK C - END


    # CODE BLOCK D - Create storage accounts

    New-AzureStorageAccount -Location $Location -StorageAccountName $StorageName
    Start-Sleep -Seconds 60
    Set-AzureStorageAccount -StorageAccountName $StorageName
    Start-Sleep -Seconds 60
    Set-AzureSubscription -SubscriptionName $SubscriptionName -CurrentStorageAccount $StorageName

    # CODE BLOCK D - END


    # CODE BLOCK E - Create VM

    Parallel {
        Sequence {
            $VMname1 = "Adatum-Svr1"
            New-AzureQuickVM -Windows -ServiceName $CloudsvcName1 -Name $VMname1 -ImageName $WinImage -Password $AdminPassword -InstanceSize Small -AdminUserName $AdminName -Location $Location -VNetName $Network -SubnetNames $Subnet
        }
        Sequence {
            $VMname2 = "Adatum-Svr2"
            New-AzureQuickVM -Windows -ServiceName $CloudsvcName2 -Name $VMname2 -ImageName $WinImage -Password $AdminPassword -InstanceSize Small -AdminUserName $AdminName -Location $Location -VNetName $Network -SubnetNames $Subnet
        }
    }
 
    # CODE BLOCK E - END