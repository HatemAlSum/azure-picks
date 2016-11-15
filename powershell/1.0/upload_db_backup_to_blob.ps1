$ResourceGroupName = 'C9-SQL-2014'
$storageaccountname = 'c9mssqlsa2014'
$file ='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\TestDb.bak'
# get storage account key
$key = (Get-AzureRmStorageAccountKey -Name $storageaccountname -ResourceGroupName $ResourceGroupName).Key1
$key  
# create storage context
$storagecontext = New-AzureStorageContext -StorageAccountName $storageaccountname -StorageAccountKey $key
  
# create a container called scripts
New-AzureStorageContainer -Name "backups" -Context $storagecontext
  
#upload the file
Set-AzureStorageBlobContent -Container "backups" -File $file -Blob "TestDb.bak"-BlobType Page -Context $storagecontext -force
 