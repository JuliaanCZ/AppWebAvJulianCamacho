param([ValidateRange(1024, 65535)][int]$Port = 8098)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$iisDirectory = Join-Path $env:ProgramFiles 'IIS Express'
$binary = Join-Path $iisDirectory 'iisexpress.exe'
$template = Join-Path $iisDirectory 'config\templates\PersonalWebServer\applicationhost.config'
if (-not (Test-Path -LiteralPath $binary)) { throw 'Instala IIS Express para usar este lanzador.' }
$runtime = Join-Path $PSScriptRoot '.runtime'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
$configPath = Join-Path $runtime 'applicationhost.config'
$running = Get-CimInstance Win32_Process -Filter "Name='iisexpress.exe'" | Where-Object {
    $_.CommandLine -and $_.CommandLine.IndexOf($configPath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
} | Select-Object -First 1
if ($running) {
    [xml]$existingConfig = [System.IO.File]::ReadAllText($configPath)
    $existingBinding = $existingConfig.configuration.'system.applicationHost'.sites.site.bindings.binding.bindingInformation
    $existingPort = ($existingBinding -split ':')[1]
    Write-Output "YA INICIADO: http://localhost:$existingPort/login.asp"
    Write-Output "PID: $($running.ProcessId). Para detener: powershell -NoProfile -ExecutionPolicy Bypass -File tests\stop-local.ps1"
    exit 0
}
$raw = [System.IO.File]::ReadAllText($template)
$raw = $raw.Replace('%IIS_USER_HOME%', $runtime).Replace('%IIS_SITES_HOME%', $runtime).Replace('%AppData%', $runtime).Replace('%TEMP%', $runtime)
[xml]$config = $raw
$hostConfig = $config.configuration.'system.applicationHost'
$pools = $hostConfig.SelectSingleNode('applicationPools')
$pools.RemoveAll()
$pool = $config.CreateElement('add')
$pool.SetAttribute('name', 'FrecuenciaClassic')
$pool.SetAttribute('managedRuntimeVersion', '')
$pool.SetAttribute('managedPipelineMode', 'Classic')
$pools.AppendChild($pool) | Out-Null
$site = $hostConfig.sites.site
$site.SetAttribute('name', 'Frecuencia')
$site.application.SetAttribute('applicationPool', 'FrecuenciaClassic')
$site.application.virtualDirectory.SetAttribute('physicalPath', $projectRoot)
$site.bindings.binding.SetAttribute('bindingInformation', ":${Port}:localhost")
$hostConfig.sites.applicationDefaults.SetAttribute('applicationPool', 'FrecuenciaClassic')
$config.configuration.'system.webServer'.asp.SetAttribute('scriptErrorSentToBrowser', 'true')
$config.Save($configPath)
$log = Join-Path $runtime 'iis.stdout.log'
$errorLog = Join-Path $runtime 'iis.stderr.log'
$serverProcess = Start-Process -FilePath $binary -ArgumentList @("/config:`"$configPath`"", '/site:Frecuencia', '/systray:false') -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $errorLog -PassThru
Start-Sleep -Milliseconds 500
$serverProcess.Refresh()
if ($serverProcess.HasExited) { throw "IIS Express no pudo iniciar. Revisa $log y $errorLog" }
Write-Output "FRECUENCIA: http://localhost:$Port/login.asp"
Write-Output "PID: $($serverProcess.Id). Para detener: powershell -NoProfile -ExecutionPolicy Bypass -File tests\stop-local.ps1"
Write-Output "Logs: $runtime"
