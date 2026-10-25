<%@ Language="VBScript" CodePage="65001" %>
<% Option Explicit %>
<!--#include file="conexion.asp"-->
<%
Dim db, cmd, rs, errorMessage, username, password, connected, tokenReady, loginOK, userId, authenticatedName, userRole
If PositiveId(Session("IDUsuario")) > 0 Then Response.Redirect "index.asp"
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then VerifyPost
errorMessage = ""
username = ""
connected = OpenConnection(db)
tokenReady = False
If connected Then tokenReady = EnsureCsrf(db)
If Not connected Or Not tokenReady Then
    Response.Status = "503 Service Unavailable"
    errorMessage = "No podemos conectar con el catálogo. Inténtalo de nuevo en unos momentos."
ElseIf Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    username = Trim(TextValue(Request.Form("usuario")))
    password = TextValue(Request.Form("password"))
    If Len(username) = 0 Or Len(username) > 50 Or Len(password) = 0 Or Len(password) > 50 Then
        errorMessage = "Escribe un usuario y una contraseña válidos (máximo 50 caracteres)."
    Else
        ' Compatibilidad exacta con las contraseñas existentes del esquema de referencia.
        Set cmd = NewCommand(db, "SELECT TOP (1) ID_USER, USERNAME, USER_TYPE FROM dbo.TBL_USER WHERE USERNAME COLLATE Latin1_General_100_BIN2 = ? AND [PASSWORD] COLLATE Latin1_General_100_BIN2 = ? AND DATALENGTH([PASSWORD]) = DATALENGTH(?) AND USER_TYPE IN (0, 1)")
        AddText cmd, "username", 50, username
        AddText cmd, "password", 50, password
        AddText cmd, "passwordLength", 50, password
        loginOK = False
        If ReadRows(cmd, rs) Then
            If Not rs.EOF Then
                userId = CLng(rs("ID_USER"))
                authenticatedName = CStr(rs("USERNAME"))
                userRole = "normal"
                If CInt(rs("USER_TYPE")) = 1 Then userRole = "admin"
                loginOK = True
            Else
                errorMessage = "El usuario o la contraseña no son correctos."
            End If
        Else
            Response.Status = "503 Service Unavailable"
            errorMessage = "El servicio no está disponible. Vuelve a intentarlo."
        End If
        CloseRecordset rs
        Set cmd = Nothing
        If loginOK Then
            Session.Contents.RemoveAll
            Session("Usuario") = authenticatedName
            Session("IDUsuario") = userId
            Session("Rol") = userRole
            tokenReady = EnsureCsrf(db)
            If Not tokenReady Then
                Session.Contents.RemoveAll
                CloseConnection db
                FailPage "503 Service Unavailable", "Sesión no disponible", "Vuelve a iniciar sesión en unos momentos."
            End If
            CloseConnection db
            Response.Redirect "index.asp"
        End If
    End If
End If
CloseConnection db
%>
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="theme-color" content="#0d0f12">
    <meta name="description" content="Tu música, en tu frecuencia. Explora un catálogo que se mueve contigo.">
    <title>Iniciar sesión · FRECUENCIA</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body class="login-page">
    <a class="skip-link" href="#login">Saltar al formulario</a>
    <main class="login-layout">
        <section class="login-story" aria-labelledby="story-title">
            <a class="brand" href="login.asp" aria-label="Frecuencia, inicio"><span class="brand-mark" aria-hidden="true"><i></i><i></i><i></i><i></i></span>frecuencia<span class="brand-dot">.</span></a>
            <div class="story-copy"><span class="eyebrow">SUBE EL VOLUMEN. ENCUENTRA TU RITMO.</span><h1 id="story-title">El mundo en pausa.<br><span>Tu música,</span><br>en play.</h1><p>Un espacio para descubrir, volver a escuchar<br>y conectar con eso que te mueve.</p></div>
            <div class="login-record" aria-hidden="true"><div class="record-disc"><span>f.</span></div><div class="record-label"><span>FRECUENCIA ORIGINAL</span><strong>Deja que suene.</strong><span>VOL. 01 &nbsp; / &nbsp; SIN INTERRUPCIONES</span></div></div>
            <p class="story-footer"><span class="status-dot"></span> HECHO PARA ESCUCHAR DIFERENTE</p>
        </section>
        <section class="login-form-panel" id="login" aria-labelledby="login-title">
            <div class="login-form-wrap"><span class="eyebrow muted">TU PRÓXIMA CANCIÓN TE ESPERA</span><h2 id="login-title">Qué bueno verte.</h2><p class="form-intro">Entra y dale play a tu momento.</p>
                <% If errorMessage <> "" Then %><div class="notice notice-error" role="alert"><%= Icon("info") %><span><%= H(errorMessage) %></span></div><% End If %>
                <form method="post" action="login.asp" class="stack-form">
                    <input type="hidden" name="csrf" value="<%= H(Session("Csrf")) %>">
                    <div class="field"><label for="usuario">Usuario</label><input id="usuario" name="usuario" autocomplete="username" placeholder="Tu nombre de usuario" value="<%= H(username) %>" maxlength="50" required autofocus></div>
                    <div class="field"><label for="password">Contraseña</label><input type="password" id="password" name="password" autocomplete="current-password" placeholder="Escribe tu contraseña" maxlength="50" required></div>
                    <button class="button button-primary login-submit" type="submit" <% If Not tokenReady Then Response.Write "disabled" %>>Entrar a mi frecuencia <%= Icon("arrow") %></button>
                </form>
                <p class="login-note">Usa la cuenta asignada por el administrador.<br>Tu sesión se cierra tras 30 minutos de inactividad.</p>
                <div class="login-bottom"><span class="mini-wave" aria-hidden="true">▂ ▅ █ ▃ ▆ ▂</span><span>Música para estar aquí.</span></div>
            </div>
        </section>
    </main>
</body>
</html>
