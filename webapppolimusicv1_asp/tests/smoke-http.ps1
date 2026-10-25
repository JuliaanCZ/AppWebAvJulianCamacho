param([string]$BaseUrl = 'http://localhost:8098', [switch]$ExerciseCrud)
$ErrorActionPreference = 'Stop'
function Get-Csrf([string]$Html) {
    $token = [regex]::Match($Html, 'name="csrf" value="([A-F0-9]{64})"').Groups[1].Value
    if (-not $token) { throw 'No se encontro un token CSRF valido.' }
    return $token
}
function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Get-HttpStatus([string]$Url, $Session, [string]$Method = 'GET', $Body = $null) {
    try { return [int](Invoke-WebRequest -UseBasicParsing -Uri $Url -WebSession $Session -Method $Method -Body $Body).StatusCode }
    catch {
        if ($null -ne $_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
        throw
    }
}
$normalSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$login = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/login.asp" -WebSession $normalSession
$normalIndex = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/login.asp" -Method POST -WebSession $normalSession -Body @{ usuario = 'userNormal'; password = '12345678'; csrf = (Get-Csrf $login.Content) }
Assert-True ($normalIndex.Content.Contains('data-track-id="')) 'El usuario normal no pudo entrar al catalogo.'
Assert-True (-not $normalIndex.Content.Contains('class="card-admin"')) 'Se mostraron controles de administrador al usuario normal.'
Assert-True ((Get-HttpStatus "$BaseUrl/crud_canciones.asp" $normalSession) -eq 403) 'El CRUD no rechazo al usuario normal.'
Assert-True ((Get-HttpStatus "$BaseUrl/crud_canciones.asp" $normalSession 'POST' @{ action = 'create'; csrf = (Get-Csrf $normalIndex.Content); song_name = 'Unauthorized'; song_path = 'invalid' }) -eq 403) 'El backend permitio un POST de usuario normal.'
Write-Output 'PASS: usuario normal entra; controles admin ocultos; GET y POST de CRUD devuelven 403.'

$adminSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$login = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/login.asp" -WebSession $adminSession
$adminIndex = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/login.asp" -Method POST -WebSession $adminSession -Body @{ usuario = 'userAdmin'; password = '12345678'; csrf = (Get-Csrf $login.Content) }
Assert-True ($adminIndex.Content.Contains('class="card-admin"')) 'El administrador no pudo entrar con sus permisos.'
$form = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/crud_canciones.asp" -WebSession $adminSession
Assert-True ($form.StatusCode -eq 200) 'No se pudo abrir el formulario de administrador.'
Assert-True ((Get-HttpStatus "$BaseUrl/crud_canciones.asp" $adminSession 'POST' @{ action = 'create'; csrf = 'invalid'; song_name = 'Invalid'; song_path = 'invalid' }) -eq 403) 'El backend no rechazo CSRF invalido.'
Write-Output 'PASS: administrador entra al catalogo y formulario; CSRF invalido devuelve 403.'

if ($ExerciseCrud) {
    # Solo se modifica una fila temporal creada por esta misma ejecucion.
    $testName = 'FRECUENCIA_TEST_' + [guid]::NewGuid().ToString('N').Substring(0,12)
    $testId = $null
    try {
        $created = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/crud_canciones.asp" -Method POST -WebSession $adminSession -Body @{ action = 'create'; id = '0'; csrf = (Get-Csrf $form.Content); song_name = $testName; song_path = 'SongFilesAndImages_resources/SongFiles/bensound-adventure.mp3' }
        $pattern = '<article class="song-card" data-track-id="(\d+)" data-title="' + [regex]::Escape($testName) + '"'
        $testId = [regex]::Match($created.Content, $pattern).Groups[1].Value
        Assert-True ([bool]$testId) 'No se encontro la cancion temporal despues de crearla.'
        $editForm = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/crud_canciones.asp?action=edit&id=$testId" -WebSession $adminSession
        Assert-True ($editForm.Content.Contains($testName)) 'La fila temporal no coincide con la creada.'
        $editedName = $testName + '_EDIT'
        $edited = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/crud_canciones.asp" -Method POST -WebSession $adminSession -Body @{ action = 'edit'; id = $testId; csrf = (Get-Csrf $editForm.Content); song_name = $editedName; song_path = 'SongFilesAndImages_resources/SongFiles/bensound-adventure.mp3' }
        Assert-True ($edited.Content.Contains('data-title="' + $editedName + '"')) 'No se guardo la edicion temporal.'
        Write-Output 'PASS: insercion y edicion de una cancion temporal.'
    } finally {
        if ($testId) {
            $deleteForm = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/crud_canciones.asp?action=delete&id=$testId" -WebSession $adminSession
            Assert-True ($deleteForm.Content.Contains($testName)) 'Se cancelo la limpieza: el ID ya no corresponde a la fila temporal.'
            $deleted = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/crud_canciones.asp" -Method POST -WebSession $adminSession -Body @{ action = 'delete'; id = $testId; csrf = (Get-Csrf $deleteForm.Content) }
            Assert-True (-not $deleted.Content.Contains('data-track-id="' + $testId + '"')) 'No se limpio la cancion temporal.'
            Write-Output 'PASS: eliminacion exclusiva de la fila temporal; catalogo original conservado.'
        }
    }
}
$logoutCsrf = Get-Csrf $adminIndex.Content
$afterLogout = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/logout.asp" -Method POST -WebSession $adminSession -Body @{ csrf = $logoutCsrf }
Assert-True ($afterLogout.Content.Contains('name="usuario"')) 'El logout no regreso al formulario de login.'
$protected = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/index.asp" -WebSession $adminSession
Assert-True ($protected.Content.Contains('name="usuario"')) 'La sesion seguia teniendo acceso al catalogo despues del logout.'
Write-Output 'PASS: logout invalida la sesion y el catalogo vuelve a exigir login.'
