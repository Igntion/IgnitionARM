# Define variables
$domainName = "Core.Ignition"
$domainUser = "AD2@Core.Ignition"
$domainPassword = "P@ssw0rd1234"
$securePassword = ConvertTo-SecureString $domainPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($domainUser, $securePassword)

# Log the domain join attempt
Write-Output "Attempting to join domain '$domainName' with user '$domainUser'."

# Join the domain
try {
    Add-Computer -DomainName $domainName -Credential $credential -Force -Restart
    Write-Output "Successfully joined the domain '$domainName'."
} catch {
    Write-Error "Failed to join the domain '$domainName': $_"
}
