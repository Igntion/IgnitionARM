# Define variables
$domainName = "Core.Ignition"
$dsrmPassword = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
$postRestartScriptPath = "C:\Users\adminuser\Downloads\ProvisionUsers.ps1"

# Install the Active Directory Domain Services role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Wait until the role installation is complete
while ((Get-WindowsFeature -Name AD-Domain-Services).InstallState -ne 'Installed') {
    Start-Sleep -Seconds 10
}

# Import the ADDSDeployment module
Import-Module ADDSDeployment

# Install AD DS Forest
Install-ADDSForest `
  -CreateDnsDelegation:$false `
  -DatabasePath 'C:\Windows\NTDS' `
  -DomainMode 'WinThreshold' `
  -DomainName $domainName `
  -DomainNetbiosName 'CORE' `
  -ForestMode 'WinThreshold' `
  -InstallDns:$true `
  -LogPath 'C:\Windows\NTDS' `
  -NoRebootOnCompletion:$false `
  -SysvolPath 'C:\Windows\SYSVOL' `
  -SafeModeAdministratorPassword $dsrmPassword `
  -Force:$true


# Restart the server
Restart-Computer -Force
