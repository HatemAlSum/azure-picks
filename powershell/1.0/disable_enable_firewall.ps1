# Disable Windows Firewall:
Invoke-Command -ComputerName $DNSName -Credential $credential -UseSSL -SessionOption (New-PsSessionOption -SkipCACheck -SkipCNCheck)  -ScriptBlock {
  Set-NetFirewallProfile -All -Enabled False 
}

# Enable Windows Firewall:
Invoke-Command -ComputerName $DNSName -Credential $credential -UseSSL -SessionOption (New-PsSessionOption -SkipCACheck -SkipCNCheck)  -ScriptBlock {
  Set-NetFirewallProfile -All -Enabled True 
}
