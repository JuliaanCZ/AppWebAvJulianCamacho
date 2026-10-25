<%
' ADO nativo. Este archivo nunca abre conexiones al ser incluido.
Const adCmdText = 1
Const adParamInput = 1
Const adInteger = 3
Const adVarChar = 200
Const adExecuteNoRecords = 128

Response.Buffer = True
Response.Charset = "utf-8"
Response.CodePage = 65001
Response.CacheControl = "no-cache"
Response.Expires = -1
Response.AddHeader "Cache-Control", "no-store, private"
Response.AddHeader "X-Content-Type-Options", "nosniff"
Response.AddHeader "X-Frame-Options", "DENY"
Response.AddHeader "Referrer-Policy", "same-origin"
Response.AddHeader "Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; media-src 'self'; font-src 'self'; object-src 'none'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'"
Session.Timeout = 30

Function TextValue(value)
    If IsNull(value) Or IsEmpty(value) Then
        TextValue = ""
    Else
        TextValue = CStr(value)
    End If
End Function

Function H(value)
    H = Server.HTMLEncode(TextValue(value))
End Function

' Solo para interoperabilidad heredada. Las consultas de la app usan parámetros.
Function EscapeSql(value)
    EscapeSql = Replace(TextValue(value), "'", "''")
End Function

Function PositiveId(value)
    Dim re, candidate
    PositiveId = 0
    candidate = TextValue(value)
    If Len(candidate) = 0 Or Len(candidate) > 10 Then Exit Function
    Set re = New RegExp
    re.Pattern = "^[1-9][0-9]*$"
    If Not re.Test(candidate) Then Exit Function
    If CDbl(candidate) > 2147483647 Then Exit Function
    PositiveId = CLng(candidate)
End Function

Function OpenConnection(ByRef db)
    On Error Resume Next
    Set db = Server.CreateObject("ADODB.Connection")
    db.ConnectionTimeout = 5
    db.CommandTimeout = 15
    ' Credenciales del SQL de referencia; no se ejecuta ese script.
    db.Open "Provider=MSOLEDBSQL;Data Source=127.0.0.1,14333;Initial Catalog=BDD_PoliMusic;User ID=usr_polimusic;Password=Politecnica1;Use Encryption for Data=True;Trust Server Certificate=True;"
    OpenConnection = (Err.Number = 0)
    Err.Clear
    On Error GoTo 0
End Function

Sub CloseConnection(ByRef db)
    On Error Resume Next
    If IsObject(db) Then
        If Not (db Is Nothing) Then
            If db.State <> 0 Then db.Close
        End If
    End If
    Set db = Nothing
    Err.Clear
    On Error GoTo 0
End Sub

Sub CloseRecordset(ByRef rs)
    On Error Resume Next
    If IsObject(rs) Then
        If Not (rs Is Nothing) Then
            If rs.State <> 0 Then rs.Close
        End If
    End If
    Set rs = Nothing
    Err.Clear
    On Error GoTo 0
End Sub

Function NewCommand(db, sql)
    Dim command
    Set command = Server.CreateObject("ADODB.Command")
    Set command.ActiveConnection = db
    command.CommandType = adCmdText
    command.CommandTimeout = 15
    command.CommandText = sql
    Set NewCommand = command
End Function

Sub AddText(command, name, size, value)
    command.Parameters.Append command.CreateParameter(name, adVarChar, adParamInput, size, value)
End Sub

Sub AddInt(command, name, value)
    command.Parameters.Append command.CreateParameter(name, adInteger, adParamInput, , CLng(value))
End Sub

Function ReadRows(command, ByRef rs)
    On Error Resume Next
    Set rs = command.Execute
    ReadRows = (Err.Number = 0)
    Err.Clear
    On Error GoTo 0
End Function

Function WriteRows(command, ByRef affected)
    On Error Resume Next
    affected = 0
    command.Execute affected, , adExecuteNoRecords
    WriteRows = (Err.Number = 0)
    Err.Clear
    On Error GoTo 0
End Function

Function EnsureCsrf(db)
    Dim command, rs
    EnsureCsrf = False
    If Len(TextValue(Session("Csrf"))) = 64 Then
        EnsureCsrf = True
        Exit Function
    End If
    ' Generador criptográfico de SQL Server; sin tablas ni cambios de esquema.
    Set command = NewCommand(db, "SELECT CONVERT(varchar(64), CRYPT_GEN_RANDOM(32), 2) AS TOKEN")
    If ReadRows(command, rs) Then
        If Not rs.EOF Then Session("Csrf") = CStr(rs("TOKEN"))
    End If
    CloseRecordset rs
    Set command = Nothing
    EnsureCsrf = (Len(TextValue(Session("Csrf"))) = 64)
End Function

Sub FailPage(status, title, message)
    Response.Status = status
    Response.Write "<!doctype html><html lang=""es""><head><meta charset=""utf-8""><meta name=""viewport"" content=""width=device-width,initial-scale=1""><title>" & H(title) & " · FRECUENCIA</title><link rel=""stylesheet"" href=""styles.css""></head><body class=""error-page""><main class=""error-panel""><span class=""eyebrow"">FRECUENCIA / " & H(Left(status, 3)) & "</span><h1>" & H(title) & "</h1><p>" & H(message) & "</p><a class=""button button-primary"" href=""index.asp"">Volver al inicio</a></main></body></html>"
    Response.End
End Sub

Sub RequireLogin()
    If PositiveId(Session("IDUsuario")) = 0 Or Len(TextValue(Session("Usuario"))) = 0 Then
        Response.Redirect "login.asp"
    End If
End Sub

Sub RequireAdmin()
    RequireLogin
    If TextValue(Session("Rol")) <> "admin" Then
        FailPage "403 Forbidden", "Acceso restringido", "La gestión del catálogo está disponible solo para administradores."
    End If
End Sub

Sub VerifyPost()
    If Request.ServerVariables("REQUEST_METHOD") <> "POST" Then
        Response.AddHeader "Allow", "POST"
        FailPage "405 Method Not Allowed", "Solicitud no permitida", "Utiliza el formulario para realizar esta acción."
    End If
    If Len(TextValue(Session("Csrf"))) <> 64 Or TextValue(Request.Form("csrf")) <> TextValue(Session("Csrf")) Then
        FailPage "403 Forbidden", "El formulario ha caducado", "Recarga la página y vuelve a intentarlo."
    End If
End Sub

Function AssetPath(rawPath, kind)
    Dim candidate, re, fso, folder, extension, dotPosition
    AssetPath = ""
    candidate = Replace(Trim(TextValue(rawPath)), "\", "/")
    If Left(candidate, 2) = "~/" Then candidate = Mid(candidate, 3)
    If kind = "audio" Then
        folder = "SongFiles"
    ElseIf kind = "user" Then
        folder = "UserImages"
    ElseIf kind = "album" Then
        folder = "AlbumImages"
    Else
        folder = "PlaylistImages"
    End If
    If LCase(Left(candidate, Len(folder) + 1)) = LCase(folder & "/") Then
        candidate = "SongFilesAndImages_resources/" & candidate
    End If
    If LCase(Left(candidate, Len("SongFilesAndImages_resources/" & folder & "/"))) <> LCase("SongFilesAndImages_resources/" & folder & "/") Then Exit Function
    If InStr(candidate, "..") > 0 Then Exit Function
    Set re = New RegExp
    re.Pattern = "^[A-Za-z0-9_/ .()-]+$"
    If Not re.Test(candidate) Then Exit Function
    dotPosition = InStrRev(candidate, ".")
    If dotPosition = 0 Then Exit Function
    extension = LCase(Mid(candidate, dotPosition))
    If kind = "audio" Then
        If extension <> ".mp3" Then Exit Function
    Else
        If extension <> ".jpg" And extension <> ".jpeg" And extension <> ".png" And extension <> ".webp" And extension <> ".gif" Then Exit Function
    End If
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(Server.MapPath(candidate)) Then AssetPath = candidate
    Set fso = Nothing
End Function

Function CoverPath(rawPath, songId)
    Dim cover
    cover = AssetPath(rawPath, "album")
    If cover = "" Then cover = "SongFilesAndImages_resources/PlaylistImages/playlist" & ((CLng(songId) Mod 5) + 1) & ".png"
    CoverPath = cover
End Function

' Iconos SVG locales, sin librerías ni solicitudes externas.
Function Icon(name)
    Dim path
    Select Case name
        Case "play": path = "<path d='m9 5 11 7-11 7z' fill='currentColor' stroke='none'/>"
        Case "pause": path = "<path d='M8 5v14M16 5v14' stroke-width='4'/>"
        Case "next": path = "<path d='m5 5 10 7-10 7z' fill='currentColor' stroke='none'/><path d='M19 5v14'/>"
        Case "previous": path = "<path d='m19 5-10 7 10 7z' fill='currentColor' stroke='none'/><path d='M5 5v14'/>"
        Case "heart": path = "<path d='M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z'/>"
        Case "search": path = "<circle cx='10.5' cy='10.5' r='6.5'/><path d='m16 16 5 5'/>"
        Case "home": path = "<path d='m3 10 9-7 9 7v11h-6v-7H9v7H3z'/>"
        Case "music": path = "<path d='M9 18V5l12-2v13M9 9l12-2'/><ellipse cx='5.5' cy='18' rx='3.5' ry='3'/><ellipse cx='17.5' cy='16' rx='3.5' ry='3'/>"
        Case "grid": path = "<rect x='3' y='3' width='7' height='7' rx='1'/><rect x='14' y='3' width='7' height='7' rx='1'/><rect x='3' y='14' width='7' height='7' rx='1'/><rect x='14' y='14' width='7' height='7' rx='1'/>"
        Case "logout": path = "<path d='M9 4H4v16h5M13 8l4 4-4 4M9 12h12'/>"
        Case "plus": path = "<path d='M12 5v14M5 12h14'/>"
        Case "edit": path = "<path d='m15 4 5 5M4 20l5-1L21 7l-5-5L4 14z'/>"
        Case "trash": path = "<path d='M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7M14 10v7'/>"
        Case "arrow": path = "<path d='M5 12h14m-6-6 6 6-6 6'/>"
        Case "volume": path = "<path d='m11 4-6 5H2v6h3l6 5zM15 8a6 6 0 0 1 0 8M18 5a10 10 0 0 1 0 14'/>"
        Case "shuffle": path = "<path d='M3 6h3l12 12h3M17 14l4 4-4 4M3 18h3l4-4M14 10l4-4h3M17 2l4 4-4 4'/>"
        Case "repeat": path = "<path d='m17 2 4 4-4 4M3 11V9a3 3 0 0 1 3-3h15M7 22l-4-4 4-4M21 13v2a3 3 0 0 1-3 3H3'/>"
        Case Else: path = "<circle cx='12' cy='12' r='9'/><path d='M12 8v5M12 16h.01'/>"
    End Select
    Icon = "<svg class=""icon"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""1.7"" stroke-linecap=""round"" stroke-linejoin=""round"" aria-hidden=""true"">" & path & "</svg>"
End Function

If LCase(Right(Request.ServerVariables("SCRIPT_NAME"), 13)) = "/conexion.asp" Then
    Response.Status = "404 Not Found"
    Response.End
End If
%>
