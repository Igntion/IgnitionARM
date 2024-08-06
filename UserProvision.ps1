# Define variables
$domainName = "Core.Ignition"
$adminPassword = ConvertTo-SecureString 'P@ssw0rd1234' -AsPlainText -Force

# Wait for the system to come back online and ensure the AD services are up
Start-Sleep -Seconds 120

# Import the Active Directory module
Import-Module ActiveDirectory

# Ensure the Users container exists
$usersContainer = Get-ADOrganizationalUnit -Filter {Name -eq 'Users'} -SearchBase 'DC=Core,DC=Ignition'
if (-not $usersContainer) {
    Write-Error "The 'Users' container does not exist in the domain 'Core.Ignition'."
    exit 1
}

# Create users in AD
$users = @(
    @{FullName='AD1'; LogonName='AD1'; Password=$adminPassword},
    @{FullName='AD2'; LogonName='AD2'; Password=$adminPassword},
    @{FullName='Client10'; LogonName='Client10'; Password=$adminPassword},
    @{FullName='Client11'; LogonName='Client11'; Password=$adminPassword}
)

foreach ($user in $users) {
    try {
        New-ADUser -Name $user.FullName `
            -SamAccountName $user.LogonName `
            -UserPrincipalName "$($user.LogonName)@$domainName" `
            -Path 'OU=Users,DC=Core,DC=Ignition' `
            -AccountPassword $user.Password `
            -PasswordNeverExpires $true `
            -PassThru | Enable-ADAccount
    } catch {
        Write-Error "Failed to create user $($user.FullName): $_"
    }
}

# Add AD1 and AD2 to Domain Admins group
try {
    Add-ADGroupMember -Identity 'Domain Admins' -Members 'AD1', 'AD2'
} catch {
    Write-Error "Failed to add users to Domain Admins group: $_"
}

Write-Output 'Active Directory setup completed and users added successfully.'

# Remove the scheduled task
try {
    Unregister-ScheduledTask -TaskName 'UserProvision' -Confirm:$false
} catch {
    Write-Error "Failed to remove scheduled task 'UserProvision': $_"
}
