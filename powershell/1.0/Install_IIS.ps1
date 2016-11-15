#Intall IIS
#Install-WindowsFeature -Name Web-Server -IncludeManagementTools -Source C:\Windows\WinSxS
Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature  -Source C:\Windows\WinSxS

#Install-WindowsFeature Net-Framework-Core  -IncludeAllSubFeature -Source C:\Windows\WinSxS
Install-WindowsFeature -Name NET-Framework-45-Core -IncludeAllSubFeature
# Disable Windows Firewall:
#Set-NetFirewallProfile -All -Enabled False