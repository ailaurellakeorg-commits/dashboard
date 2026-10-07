$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$serverScript = Join-Path $projectRoot 'tool\lan_server.py'
$webBuild = Join-Path $projectRoot 'build\web\index.html'
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike '*\WindowsApps\*' } | Select-Object -First 1
$python = if ($pythonCommand) { $pythonCommand.Source } else { Join-Path $env:LocalAppData 'Programs\Python\Python313\python.exe' }

if (-not (Test-Path $webBuild)) {
    throw "Web build not found. Run 'flutter build web --release' first."
}
if (-not (Test-Path $python)) {
    throw "Python was not found at $python. Install Python 3.13 or ensure python.exe is on PATH."
}

$taskName = 'Laurel Lake Dashboard Web Server'
$user = "$env:USERDOMAIN\$env:USERNAME"
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
$wasRunning = $null -ne $existingTask -and $existingTask.State -eq 'Running'
$action = New-ScheduledTaskAction -Execute $python -Argument "-u `"$serverScript`"" -WorkingDirectory $projectRoot
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description 'Serves the Laurel Lake Flutter web build on port 8080.' -Force | Out-Null
if (-not $wasRunning) {
    Start-ScheduledTask -TaskName $taskName
}
Write-Output "Startup task installed. Open http://localhost:8080 on this machine."

try {
    New-NetFirewallRule -DisplayName 'Laurel Lake Dashboard HTTP' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8080 -Profile Any -RemoteAddress LocalSubnet -ErrorAction Stop | Out-Null
    Write-Output 'Windows Firewall now allows port 8080 from the local subnet.'
} catch {
    Write-Warning 'The server task is installed, but Windows Firewall could not be changed without administrator permission.'
    Write-Output "In an elevated PowerShell, run: New-NetFirewallRule -DisplayName 'Laurel Lake Dashboard HTTP' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8080 -Profile Any -RemoteAddress LocalSubnet"
}