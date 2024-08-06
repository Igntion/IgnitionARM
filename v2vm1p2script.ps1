
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
