$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $PSScriptRoot '.preview'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$utf8 = [System.Text.UTF8Encoding]::new($false)
$common = [System.IO.File]::ReadAllText((Join-Path $projectRoot 'conexion.asp'))
$common = [regex]::Match($common, '<%([\s\S]*?)%>').Groups[1].Value
$template = [System.IO.File]::ReadAllText((Join-Path $projectRoot 'index.asp'))
$template = $template.Substring($template.IndexOf('<!doctype html>'))
$stub = @'
Option Explicit
Dim Response, Request, Server, Session
Class PreviewResponse
    Public Buffer, Charset, CodePage, CacheControl, Expires, Stream
    Public Sub AddHeader(name, value)
    End Sub
    Public Sub Write(value)
        Stream.Write CStr(value)
    End Sub
End Class
Class PreviewRequest
    Public Function ServerVariables(name)
        ServerVariables = "/index.asp"
    End Function
End Class
Class PreviewSession
    Public Timeout
    Public Default Property Get Item(name)
        Select Case name
            Case "Usuario": Item = "userAdmin"
            Case "IDUsuario": Item = 2
            Case "Rol": Item = "admin"
            Case "Csrf": Item = String(64, "A")
        End Select
    End Property
End Class
Class PreviewServer
    Public Function HTMLEncode(value)
        Dim text
        text = Replace(value, "&", "&amp;")
        text = Replace(text, "<", "&lt;")
        text = Replace(text, ">", "&gt;")
        text = Replace(text, """", "&quot;")
        HTMLEncode = text
    End Function
    Public Function CreateObject(name)
        Set CreateObject = WScript.CreateObject(name)
    End Function
    Public Function MapPath(path)
        MapPath = WScript.Arguments(0) & "\" & Replace(path, "/", "\")
    End Function
End Class
Set Response = New PreviewResponse
Dim outputFSO
Set outputFSO = WScript.CreateObject("Scripting.FileSystemObject")
Set Response.Stream = outputFSO.CreateTextFile(WScript.Arguments(1), True, True)
Set Request = New PreviewRequest
Set Server = New PreviewServer
Set Session = New PreviewSession
' Aserciones sobre los helpers reales. No se abre ninguna conexión.
' HELPERS_INSERT
Sub AssertTrue(value, message)
    If Not value Then
        WScript.StdErr.WriteLine message
        WScript.Quit 1
    End If
End Sub
AssertTrue PositiveId("2147483647") = 2147483647, "Fallo ID máximo"
AssertTrue PositiveId("2147483648") = 0, "Overflow ID"
AssertTrue PositiveId("1 OR 1=1") = 0, "Inyección ID"
AssertTrue PositiveId("-1") = 0, "ID negativo"
AssertTrue PositiveId(Null) = 0, "ID nulo"
AssertTrue EscapeSql("O'Connor") = "O''Connor", "Escape SQL"
AssertTrue H("<script>""&") = "&lt;script&gt;&quot;&amp;", "Escape HTML"
AssertTrue AssetPath("~/songFiles/bensound-adventure.mp3", "audio") <> "", "Ruta heredada MP3"
AssertTrue AssetPath("SongFilesAndImages_resources/SongFiles/../secret.mp3", "audio") = "", "Path traversal"
AssertTrue AssetPath("https://example.org/audio.mp3", "audio") = "", "Audio remoto"
AssertTrue AssetPath("SongFilesAndImages_resources/SongFiles/missing.mp3", "audio") = "", "Audio inexistente"
AssertTrue AssetPath("SongFilesAndImages_resources/SongFiles/no-extension", "audio") = "", "Sin extension"
AssertTrue AssetPath("SongFilesAndImages_resources/UserImages/root.png", "audio") = "", "Tipo de asset incorrecto"
AssertTrue CoverPath("~/albumImages/album1.png", 1) = "SongFilesAndImages_resources/PlaylistImages/playlist2.png", "Portada alternativa"
Dim db, cmd, rs, total, songId, title, artist, album, cover, audioPath, plays, notice, isAdmin
Dim names, artists, i
Set rs = WScript.CreateObject("ADODB.Recordset")
rs.Fields.Append "ID_SONG", 3
rs.Fields.Append "SONG_NAME", 200, 50
rs.Fields.Append "SONG_PATH", 200, 255
rs.Fields.Append "ARTIST", 200, 255
rs.Fields.Append "ALBUM", 200, 50
rs.Fields.Append "ALBUM_IMAGE_PATH", 200, 255
rs.Fields.Append "PLAYS", 3
rs.Open
names = Array("Adventure", "Dreams", "Energy", "Scifi", "Tomorrow")
artists = Array("Juan Gabriel, Ana Gabriel", "Juan Gabriel, Ana Gabriel", "Juan Gabriel, Mariah Carey", "Juan Gabriel, Elvis Presley", "Juan Gabriel, Edward Sheeran")
For i = 0 To 4
    rs.AddNew
    rs("ID_SONG") = i + 1
    rs("SONG_NAME") = names(i)
    rs("SONG_PATH") = "~/songFiles/bensound-" & LCase(names(i)) & ".mp3"
    rs("ARTIST") = artists(i)
    rs("ALBUM") = "Rock Album"
    rs("ALBUM_IMAGE_PATH") = "~/albumImages/album1.png"
    rs("PLAYS") = i
    rs.Update
Next
rs.MoveFirst
total = 5
notice = "Vista de prueba local: datos aislados, sin SQL Server."
isAdmin = True
' TEMPLATE_INSERT
' Marcador para verificar que WSH completó el render.
Response.Stream.Close
WScript.Echo "PASS helpers y plantilla ASP con Recordset ADODB desconectado."
'@
$stub = $stub.Replace("' HELPERS_INSERT", $common)
$builder = [System.Text.StringBuilder]::new()
$cursor = 0
foreach ($match in [regex]::Matches($template, '<%([\s\S]*?)%>')) {
    $literal = $template.Substring($cursor, $match.Index - $cursor)
    # Conservar saltos de línea sin exceder el límite de línea del motor VBScript.
    $lines = $literal -split "`n"
    for ($lineIndex = 0; $lineIndex -lt $lines.Length; $lineIndex++) {
        $line = $lines[$lineIndex]
        if ($line.Length -gt 0) {
            [void]$builder.AppendLine('Response.Write "' + $line.TrimEnd("`r").Replace('"', '""') + '"')
        }
        if ($lineIndex -lt $lines.Length - 1) { [void]$builder.AppendLine('Response.Write vbLf') }
    }
    $code = $match.Groups[1].Value
    if ($code.StartsWith('=')) { $code = 'Response.Write ' + $code.Substring(1) }
    [void]$builder.AppendLine($code)
    $cursor = $match.Index + $match.Length
}
$last = $template.Substring($cursor)
[void]$builder.AppendLine('Response.Write "' + $last.Replace('"', '""').Replace("`r", '').Replace("`n", '" & vbLf & "') + '"')
$script = $stub.Replace("' TEMPLATE_INSERT", $builder.ToString())
$scriptPath = Join-Path $outputDirectory 'render.vbs'
[System.IO.File]::WriteAllText($scriptPath, $script, [System.Text.Encoding]::Unicode)
$renderedPath = Join-Path $outputDirectory 'rendered.utf16'
$checks = & "$env:WINDIR\System32\cscript.exe" //Nologo $scriptPath $projectRoot $renderedPath 2> (Join-Path $outputDirectory 'checks.txt')
if ($LASTEXITCODE -ne 0) { throw (Get-Content (Join-Path $outputDirectory 'checks.txt') -Raw) }
[System.IO.File]::WriteAllText((Join-Path $outputDirectory 'index.asp'), [System.IO.File]::ReadAllText($renderedPath), $utf8)
Write-Output $checks
$mobileFrame = '<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Prueba movil 390px</title></head><body style="margin:0;background:#0d0f12;color:white;font-family:Arial;padding:20px"><iframe title="Catalogo movil a 390px" src="index.asp" width="390" height="640" style="border:1px solid #454b55;border-radius:8px"></iframe></body></html>'
[System.IO.File]::WriteAllText((Join-Path $outputDirectory 'responsive.asp'), $mobileFrame, $utf8)
Write-Output "Vista previa generada: $outputDirectory\index.asp"
