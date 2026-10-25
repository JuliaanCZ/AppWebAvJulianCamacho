$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$source = [System.IO.File]::ReadAllText((Join-Path $projectRoot 'conexion.asp'))
$connectionString = [regex]::Match($source, 'db\.Open "([^"]+)"').Groups[1].Value
if (-not $connectionString) { throw 'No se encontro la conexion en conexion.asp.' }
$connectionProbe = $null
$recordProbe = $null
try {
    $connectionProbe = New-Object -ComObject ADODB.Connection
    $connectionProbe.ConnectionTimeout = 3
    $connectionProbe.CommandTimeout = 5
    $connectionProbe.Open($connectionString)
    $recordProbe = $connectionProbe.Execute('SELECT DB_NAME() AS DATABASE_NAME, (SELECT COUNT(*) FROM dbo.TBL_SONG) AS SONGS, (SELECT COUNT(*) FROM dbo.TBL_USER) AS USERS')
    Write-Output ('CONECTADO: {0} en 127.0.0.1,14333' -f $recordProbe.Fields.Item('DATABASE_NAME').Value)
    Write-Output ('Canciones: {0} | Usuarios: {1}' -f $recordProbe.Fields.Item('SONGS').Value, $recordProbe.Fields.Item('USERS').Value)
} catch {
    Write-Output ('SIN CONEXION: ' + $_.Exception.Message)
    if ($_.Exception.Message -match 'Login failed|Error de inicio de sesi') {
        Write-Output 'SQL Server responde, pero rechaza el usuario configurado. Verifica que existan BDD_PoliMusic y usr_polimusic con las credenciales del proyecto.'
    } else {
        Write-Output 'Comprueba: docker ps, el puerto 14333->1433 y que BDD_PoliMusic este disponible.'
    }
    exit 1
} finally {
    if ($null -ne $recordProbe) { if ($recordProbe.State -ne 0) { $recordProbe.Close() } }
    if ($null -ne $connectionProbe) { if ($connectionProbe.State -ne 0) { $connectionProbe.Close() } }
}
