$ErrorActionPreference = 'Stop'
$configPath = Join-Path $PSScriptRoot '.runtime\applicationhost.config'
$running = @(Get-CimInstance Win32_Process -Filter "Name='iisexpress.exe'" | Where-Object {
    $_.CommandLine -and $_.CommandLine.IndexOf($configPath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
})
if ($running.Count -eq 0) { Write-Output 'La aplicacion ya esta detenida.'; exit 0 }
foreach ($serverProcess in $running) {
    Stop-Process -Id $serverProcess.ProcessId
    Write-Output "IIS Express de Frecuencia detenido (PID $($serverProcess.ProcessId))."
}
