<%@ Language="VBScript" CodePage="65001" %>
<% Option Explicit %>
<!--#include file="conexion.asp"-->
<%
RequireAdmin
Dim db, cmd, rs, action, songId, songName, songPath, errorMessage, outcome, posted, fso, folder, file, candidate
posted = (Request.ServerVariables("REQUEST_METHOD") = "POST")
If posted Then
    VerifyPost
    action = TextValue(Request.Form("action"))
    songId = PositiveId(Request.Form("id"))
Else
    action = TextValue(Request.QueryString("action"))
    songId = PositiveId(Request.QueryString("id"))
    If action = "" Then action = "create"
End If
If action <> "create" And action <> "edit" And action <> "delete" Then
    FailPage "400 Bad Request", "Acción no válida", "Abre la gestión desde el catálogo."
End If
If action <> "create" And songId = 0 Then
    FailPage "400 Bad Request", "Canción no válida", "Selecciona una canción desde el catálogo."
End If

' Bloqueo de la canción y limpieza de relaciones en una misma transacción.
' No elimina archivos de disco, álbumes, artistas ni listas del usuario.
Function SaveSong(connection, operation, id, name, path)
    On Error Resume Next
    Dim command, locked, affected, failed, missing
    SaveSong = "error"
    missing = False
    connection.BeginTrans
    If Err.Number <> 0 Then
        Err.Clear
        Exit Function
    End If
    If operation = "create" Then
        Set command = NewCommand(connection, "INSERT INTO dbo.TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) VALUES (?, ?, 0)")
        AddText command, "name", 50, name
        AddText command, "path", 255, path
        command.Execute affected, , adExecuteNoRecords
    Else
        Set command = NewCommand(connection, "SELECT ID_SONG FROM dbo.TBL_SONG WITH (UPDLOCK, HOLDLOCK) WHERE ID_SONG = ?")
        AddInt command, "id", id
        Set locked = command.Execute
        If Err.Number = 0 Then
            missing = locked.EOF
            locked.Close
            Set locked = Nothing
        End If
        If Not missing And Err.Number = 0 Then
            If operation = "delete" Then
                Set command = NewCommand(connection, "DELETE FROM dbo.TBL_PLAYLIST_SONG WHERE ID_SONG = ?")
                AddInt command, "id", id
                command.Execute affected, , adExecuteNoRecords
                If Err.Number = 0 Then
                    Set command = NewCommand(connection, "DELETE FROM dbo.TBL_TRACKLIST WHERE ID_SONG = ?")
                    AddInt command, "id", id
                    command.Execute affected, , adExecuteNoRecords
                End If
                If Err.Number = 0 Then
                    Set command = NewCommand(connection, "DELETE FROM dbo.TBL_PLAYER WHERE ID_SONG = ?")
                    AddInt command, "id", id
                    command.Execute affected, , adExecuteNoRecords
                End If
                If Err.Number = 0 Then
                    Set command = NewCommand(connection, "DELETE FROM dbo.TBL_SONG WHERE ID_SONG = ?")
                    AddInt command, "id", id
                    command.Execute affected, , adExecuteNoRecords
                End If
            Else
                Set command = NewCommand(connection, "UPDATE dbo.TBL_SONG SET SONG_NAME = ?, SONG_PATH = ? WHERE ID_SONG = ?")
                AddText command, "name", 50, name
                AddText command, "path", 255, path
                AddInt command, "id", id
                command.Execute affected, , adExecuteNoRecords
            End If
        End If
    End If
    failed = (Err.Number <> 0)
    Err.Clear
    If failed Or missing Then
        connection.RollbackTrans
        If missing Then SaveSong = "missing"
    Else
        connection.CommitTrans
        If Err.Number = 0 Then
            SaveSong = "ok"
        Else
            Err.Clear
            connection.RollbackTrans
        End If
    End If
    Set command = Nothing
    Set locked = Nothing
    Err.Clear
    On Error GoTo 0
End Function

If Not OpenConnection(db) Then
    CloseConnection db
    FailPage "503 Service Unavailable", "El catálogo está en pausa", "No pudimos conectar con la biblioteca. Inténtalo nuevamente."
End If
If Not EnsureCsrf(db) Then
    CloseConnection db
    FailPage "503 Service Unavailable", "Sesión no disponible", "No se pudo preparar el formulario. Inténtalo de nuevo."
End If
errorMessage = ""
songName = ""
songPath = ""
If posted Then
    songName = Trim(TextValue(Request.Form("song_name")))
    songPath = Trim(TextValue(Request.Form("song_path")))
    If action <> "delete" Then
        If Len(songName) = 0 Or Len(songName) > 50 Then errorMessage = "El nombre debe tener entre 1 y 50 caracteres."
        If Len(songPath) = 0 Or Len(songPath) > 255 Then
            errorMessage = "Selecciona una ruta de audio válida, de hasta 255 caracteres."
        Else
            candidate = AssetPath(songPath, "audio")
            If candidate = "" Then
                errorMessage = "El audio debe ser un archivo .mp3 existente dentro de SongFilesAndImages_resources/SongFiles/."
            Else
                songPath = candidate
            End If
        End If
    End If
    If errorMessage = "" Then
        outcome = SaveSong(db, action, songId, songName, songPath)
        If outcome = "ok" Then
            CloseConnection db
            Select Case action
                Case "create": Response.Redirect "index.asp?ok=created"
                Case "edit": Response.Redirect "index.asp?ok=updated"
                Case "delete": Response.Redirect "index.asp?ok=deleted"
            End Select
        ElseIf outcome = "missing" Then
            CloseConnection db
            FailPage "404 Not Found", "Esta canción ya no está", "Otro administrador pudo haberla eliminado. Vuelve al catálogo."
        Else
            Response.Status = "503 Service Unavailable"
            errorMessage = "No se pudo guardar la operación. Los cambios no se aplicaron; inténtalo de nuevo."
        End If
    Else
        Response.Status = "422 Unprocessable Entity"
    End If
End If
If action <> "create" Then
    Set cmd = NewCommand(db, "SELECT SONG_NAME, SONG_PATH FROM dbo.TBL_SONG WHERE ID_SONG = ?")
    AddInt cmd, "id", songId
    If Not ReadRows(cmd, rs) Then
        CloseRecordset rs
        CloseConnection db
        FailPage "503 Service Unavailable", "Canción no disponible", "No se pudo consultar esta canción. Inténtalo nuevamente."
    End If
    If rs.EOF Then
        CloseRecordset rs
        CloseConnection db
        FailPage "404 Not Found", "Canción no encontrada", "La canción solicitada no existe en el catálogo."
    End If
    If Not posted Or action = "delete" Then
        songName = TextValue(rs("SONG_NAME"))
        songPath = TextValue(rs("SONG_PATH"))
    End If
    CloseRecordset rs
    Set cmd = Nothing
End If
CloseConnection db
%>
<!doctype html>
<html lang="es">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="theme-color" content="#0d0f12"><title>Gestionar canción · FRECUENCIA</title><link rel="stylesheet" href="styles.css"></head>
<body class="management-page">
    <a class="skip-link" href="#song-form">Saltar al formulario</a>
    <header class="management-header"><a class="brand" href="index.asp"><span class="brand-mark" aria-hidden="true"><i></i><i></i><i></i><i></i></span>frecuencia<span class="brand-dot">.</span></a><a class="button button-quiet button-small" href="index.asp">Volver al catálogo <%= Icon("arrow") %></a></header>
    <main class="management-layout">
        <section class="management-intro"><span class="eyebrow muted">ESTUDIO / ADMINISTRACIÓN</span><h1><% Select Case action
            Case "create": Response.Write "Un nuevo sonido."
            Case "edit": Response.Write "Afina los detalles."
            Case "delete": Response.Write "Fuera del catálogo."
        End Select %></h1><p><% If action = "delete" Then %>Revisa la canción antes de confirmar su eliminación.<% Else %>Un buen catálogo empieza con los detalles. Dale a cada canción su lugar.<% End If %></p><div class="management-disc" aria-hidden="true"><span>f.</span></div><div class="admin-identity"><span class="avatar"><%= H(UCase(Left(TextValue(Session("Usuario")),1))) %></span><div><strong><%= H(Session("Usuario")) %></strong><span>Administrador del catálogo</span></div></div></section>
        <section class="form-panel" aria-labelledby="form-title"><span class="eyebrow muted">BIBLIOTECA MUSICAL</span><h2 id="form-title"><% Select Case action
            Case "create": Response.Write "Añadir canción"
            Case "edit": Response.Write "Editar canción"
            Case "delete": Response.Write "Eliminar canción"
        End Select %></h2>
            <% If errorMessage <> "" Then %><div class="notice notice-error" role="alert"><%= Icon("info") %><span><%= H(errorMessage) %></span></div><% End If %>
            <form id="song-form" method="post" action="crud_canciones.asp" class="stack-form">
                <input type="hidden" name="csrf" value="<%= H(Session("Csrf")) %>"><input type="hidden" name="action" value="<%= H(action) %>"><input type="hidden" name="id" value="<%= songId %>">
                <% If action = "delete" Then %>
                    <div class="delete-preview"><span class="delete-icon"><%= Icon("trash") %></span><div><strong><%= H(songName) %></strong><span>Canción #<%= songId %></span></div></div><div class="notice notice-error"><p>Esta acción es permanente. La canción se quitará de los álbumes, asociaciones con artistas y playlists. El archivo de audio permanecerá en el servidor.</p></div>
                <% Else %>
                    <p class="form-intro">Los campos marcados con * son obligatorios.</p>
                    <div class="field"><label for="song-name">Nombre de la canción *</label><input id="song-name" name="song_name" value="<%= H(songName) %>" maxlength="50" required placeholder="Un nombre que quieras volver a escuchar" autofocus><small>Máximo 50 caracteres.</small></div>
                    <div class="field"><label for="song-path">Ruta del archivo MP3 *</label><input id="song-path" name="song_path" value="<%= H(songPath) %>" maxlength="255" list="audio-files" required placeholder="SongFilesAndImages_resources/SongFiles/archivo.mp3" aria-describedby="path-help"><datalist id="audio-files">
                    <% Set fso = Server.CreateObject("Scripting.FileSystemObject")
                    If fso.FolderExists(Server.MapPath("SongFilesAndImages_resources/SongFiles")) Then
                        Set folder = fso.GetFolder(Server.MapPath("SongFilesAndImages_resources/SongFiles"))
                        For Each file In folder.Files
                            If LCase(fso.GetExtensionName(file.Name)) = "mp3" Then
                                candidate = AssetPath("SongFilesAndImages_resources/SongFiles/" & file.Name, "audio")
                                If candidate <> "" Then Response.Write "<option value=""" & H(candidate) & """></option>"
                            End If
                        Next
                        Set folder = Nothing
                    End If
                    Set fso = Nothing %>
                    </datalist><small id="path-help">Selecciona un MP3 existente. Para añadir otro audio, copia primero su archivo en SongFilesAndImages_resources/SongFiles/.</small></div>
                    <div class="form-hint"><%= Icon("info") %><p>Se conservan las reproducciones y relaciones existentes. Las canciones nuevas comienzan con 0 reproducciones y sin álbum ni artista asignados.</p></div>
                <% End If %>
                <div class="form-actions"><a class="button button-quiet" href="index.asp">Cancelar</a><button type="submit" class="button <% If action = "delete" Then %>button-danger<% Else %>button-primary<% End If %>"><% If action = "delete" Then %><%= Icon("trash") %> Sí, eliminar canción<% Else %><%= Icon("plus") %> Guardar canción<% End If %></button></div>
            </form>
        </section>
    </main>
</body>
</html>
