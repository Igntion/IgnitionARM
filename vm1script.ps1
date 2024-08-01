# Define variables
$domainName = "Core.Ignition"
$dsrmPassword = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
$adminPassword = ConvertTo-SecureString "P@ssw0rd1234" -AsPlainText -Force

# Install the Active Directory Domain Services role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Wait until the role installation is complete
while ((Get-WindowsFeature -Name AD-Domain-Services).InstallState -ne "Installed") {
    Start-Sleep -Seconds 10
}

# Import the ADDSDeployment module
Import-Module ADDSDeployment

# Install AD DS Forest
Install-ADDSForest `
  -CreateDnsDelegation:$false `
  -DatabasePath "C:\Windows\NTDS" `
  -DomainMode "WinThreshold" `
  -DomainName $domainName `
  -DomainNetbiosName "CORE" `
  -ForestMode "WinThreshold" `
  -InstallDns:$true `
  -LogPath "C:\Windows\NTDS" `
  -NoRebootOnCompletion:$false `
  -SysvolPath "C:\Windows\SYSVOL" `
  -SafeModeAdministratorPassword $dsrmPassword `
  -Force:$true

# Restart the server if it hasn't already
Restart-Computer -Force

# Wait for the system to come back online and ensure the AD services are up
Start-Sleep -Seconds 120

# Import the Active Directory module
Import-Module ActiveDirectory

# Create users in AD
$users = @(
    @{FullName="AD1"; LogonName="AD1"; Password=$adminPassword},
    @{FullName="AD2"; LogonName="AD2"; Password=$adminPassword},
    @{FullName="Client10"; LogonName="Client10"; Password=$adminPassword},
    @{FullName="Client11"; LogonName="Client11"; Password=$adminPassword}
)

foreach ($user in $users) {
    New-ADUser -Name $user.FullName `
        -SamAccountName $user.LogonName `
        -UserPrincipalName "$($user.LogonName)@$domainName" `
        -Path "OU=Users,DC=Core,DC=Ignition" `
        -AccountPassword $user.Password `
        -PasswordNeverExpires $true `
        -PassThru | Enable-ADAccount
}

# Add AD1 and AD2 to Domain Admins group
Add-ADGroupMember -Identity "Domain Admins" -Members "AD1", "AD2"

Write-Output "Active Directory setup completed and users added successfully."

