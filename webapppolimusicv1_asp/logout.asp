<%@ Language="VBScript" CodePage="65001" %>
<% Option Explicit %>
<!--#include file="conexion.asp"-->
<%
RequireLogin
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    VerifyPost
    Session.Contents.RemoveAll
    Session.Abandon
    Response.Redirect "login.asp"
End If
%>
<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Cerrar sesión · FRECUENCIA</title><link rel="stylesheet" href="styles.css"></head>
<body class="error-page"><main class="error-panel"><span class="eyebrow">HASTA LA PRÓXIMA CANCIÓN</span><h1>¿Cerramos sesión?</h1><p>Podrás volver a tu frecuencia cuando quieras.</p><form action="logout.asp" method="post"><input type="hidden" name="csrf" value="<%= H(Session("Csrf")) %>"><div class="form-actions"><a href="index.asp" class="button button-quiet">Seguir escuchando</a><button type="submit" class="button button-danger"><%= Icon("logout") %> Cerrar sesión</button></div></form></main></body></html>
