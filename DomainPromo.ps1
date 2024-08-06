# Define variables
$dsrmPassword = ConvertTo-SecureString "P@ssw0rd1234" -AsPlainText -Force

# Install the Active Directory Domain Services role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Wait until the role installation is complete
while ((Get-WindowsFeature -Name AD-Domain-Services).InstallState -ne 'Installed') {
    Start-Sleep -Seconds 10
}

# Import the ADDSDeployment module
Import-Module ADDSDeployment

# Promote to Domain Controller
Install-ADDSDomainController `
    -NoGlobalCatalog:$false `
    -CreateDnsDelegation:$false `
    -Credential (Get-Credential) `
    -CriticalReplicationOnly:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainName "Core.Ignition" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SiteName "Default-First-Site-Name" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword $dsrmPassword `
    -Force:$true
