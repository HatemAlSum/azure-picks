#$username = 'username'
#$password = 'password'
#$SecurePassword = ConvertTo-SecureString $PASSWORD -AsPlainText -Force
#$Credential = New-Object System.Management.Automation.PSCredential ($USERNAME, $SecurePassword);
$Credential=Get-Credential
Add-AzureAccount -Credential $Credential
Add-AzureRmAccount -Credential $Credential