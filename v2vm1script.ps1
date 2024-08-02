# Define variables
$domainName = "Core.Ignition"
$dsrmPassword = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
$adminPassword = ConvertTo-SecureString "P@ssw0rd1234" -AsPlainText -Force
$postRestartScriptPath = "C:\Users\adminuser\Downloads\post-restart-script.ps1"

# Create the post-restart script
$postRestartScript = @"
# Wait for the system to come back online and ensure the AD services are up
Start-Sleep -Seconds 120

# Import the Active Directory module
Import-Module ActiveDirectory

# Ensure the OU exists
if (-not (Get-ADOrganizationalUnit -Filter {Name -eq "Users"} -SearchBase "DC=Core,DC=Ignition")) {
    New-ADOrganizationalUnit -Name "Users" -Path "DC=Core,DC=Ignition"
}

# Define the admin password
\$adminPassword = ConvertTo-SecureString "P@ssw0rd1234" -AsPlainText -Force

# Create users in AD
\$users = @(
    @{FullName="AD1"; LogonName="AD1"; Password=\$adminPassword},
    @{FullName="AD2"; LogonName="AD2"; Password=\$adminPassword},
    @{FullName="Client10"; LogonName="Client10"; Password=\$adminPassword},
    @{FullName="Client11"; LogonName="Client11"; Password=\$adminPassword}
)

foreach (\$user in \$users) {
    try {
        New-ADUser -Name \$user.FullName `
            -SamAccountName \$user.LogonName `
            -UserPrincipalName "\$($user.LogonName)@$domainName" `
            -Path "OU=Users,DC=Core,DC=Ignition" `
            -AccountPassword \$user.Password `
            -PasswordNeverExpires \$true `
            -PassThru | Enable-ADAccount
    } catch {
        Write-Error "Failed to create user \$($user.FullName): \$_"
    }
}

# Add AD1 and AD2 to Domain Admins group
Add-ADGroupMember -Identity "Domain Admins" -Members "AD1", "AD2"

Write-Output "Active Directory setup completed and users added successfully."

# Remove the scheduled task
Unregister-ScheduledTask -TaskName "PostRestartScript" -Confirm:\$false
"@

# Save the post-restart script to a file
$postRestartScript | Out-File -FilePath $postRestartScriptPath -Force

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

# Create a scheduled task to run the post-restart script after restart
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-File $postRestartScriptPath"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
Register-ScheduledTask -TaskName "PostRestartScript" -InputObject $task

# Restart the server
Restart-Computer -Force
