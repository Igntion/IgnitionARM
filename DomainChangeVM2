# Define variables
$domainName = "Core.Ignition"
$domainUser = "AD1"
$domainPassword = "P@ssw0rd"
$securePassword = ConvertTo-SecureString $domainPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$domainName\$domainUser", $securePassword)

# Join the domain
Add-Computer -DomainName $domainName -Credential $credential -Force -Restart
