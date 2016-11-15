$username = 'azpicks@me.com'
$password = 'P@$$w0rd'

$SecurePassword = ConvertTo-SecureString $PASSWORD -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($USERNAME, $SecurePassword);
Add-AzureAccount -Credential $Credential
Add-AzureRmAccount -Credential $Credential