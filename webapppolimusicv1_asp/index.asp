<%@ Language="VBScript" CodePage="65001" %>
<% Option Explicit %>
<!--#include file="conexion.asp"-->
<%
RequireLogin
Dim db, cmd, rs, total, songId, title, artist, album, cover, audioPath, plays, notice, sql, isAdmin
isAdmin = (TextValue(Session("Rol")) = "admin")
If Not OpenConnection(db) Then
    CloseConnection db
    FailPage "503 Service Unavailable", "El catálogo está en pausa", "No podemos conectar con la biblioteca. Vuelve a intentarlo en unos momentos."
End If
If Not EnsureCsrf(db) Then
    CloseConnection db
    FailPage "503 Service Unavailable", "Sesión no disponible", "No se pudo preparar la sesión. Vuelve a intentarlo."
End If
sql = "SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS,0) AS PLAYS, COUNT(*) OVER() AS TOTAL, " & _
      "ISNULL(al.TITLE_ALBUM, 'Sencillo') AS ALBUM, al.ALBUM_IMAGE_PATH, " & _
      "ISNULL(STUFF((SELECT ', ' + a.ARTIST_NAME + CASE WHEN ISNULL(a.ARTIST_LASTNAME,'') = '' THEN '' ELSE ' ' + a.ARTIST_LASTNAME END " & _
      "FROM dbo.TBL_PLAYER p INNER JOIN dbo.TBL_ARTIST a ON a.ID_ARTIST = p.ID_ARTIST WHERE p.ID_SONG = s.ID_SONG ORDER BY a.ID_ARTIST " & _
      "FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 2, ''), 'Artista sin registrar') AS ARTIST " & _
      "FROM dbo.TBL_SONG s OUTER APPLY (SELECT TOP (1) a.TITLE_ALBUM, a.ALBUM_IMAGE_PATH FROM dbo.TBL_TRACKLIST t " & _
      "INNER JOIN dbo.TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM WHERE t.ID_SONG = s.ID_SONG ORDER BY a.ID_ALBUM) al ORDER BY s.ID_SONG"
Set cmd = NewCommand(db, sql)
If Not ReadRows(cmd, rs) Then
    CloseRecordset rs
    Set cmd = Nothing
    CloseConnection db
    FailPage "503 Service Unavailable", "No pudimos cargar las canciones", "Intenta abrir el catálogo nuevamente."
End If
total = 0
If Not rs.EOF Then total = CLng(rs("TOTAL"))
notice = ""
Select Case TextValue(Request.QueryString("ok"))
    Case "created": notice = "La canción ya forma parte del catálogo."
    Case "updated": notice = "Los cambios de la canción se guardaron."
    Case "deleted": notice = "La canción se eliminó del catálogo."
End Select
%>
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="theme-color" content="#0d0f12">
    <meta name="description" content="Descubre tu próxima canción en Frecuencia. Tu espacio para explorar y escuchar.">
    <title>Explorar · FRECUENCIA</title>
    <link rel="stylesheet" href="styles.css">
    <script src="player.js" defer></script>
</head>
<body class="app-page" data-user-id="<%= H(Session("IDUsuario")) %>">
    <a class="skip-link" href="#main">Saltar al catálogo</a>
    <aside class="sidebar" aria-label="Navegación principal">
        <a class="brand" href="index.asp" aria-label="Frecuencia, inicio"><span class="brand-mark" aria-hidden="true"><i></i><i></i><i></i><i></i></span>frecuencia<span class="brand-dot">.</span></a>
        <span class="nav-label">TU ESPACIO</span>
        <nav class="main-nav">
            <a href="index.asp" class="nav-link active" aria-current="page"><%= Icon("home") %> Explorar <span class="nav-active-dot"></span></a>
            <button type="button" class="nav-link" data-view="all"><%= Icon("music") %> Todas las canciones <span class="nav-count"><%= total %></span></button>
            <button type="button" class="nav-link" data-view="favorites"><%= Icon("heart") %> Tus favoritas <span class="nav-count" id="favorite-count">0</span></button>
            <% If Session("Rol") = "admin" Then %><a href="crud_canciones.asp" class="nav-link"><%= Icon("grid") %> Gestionar catálogo</a><% End If %>
        </nav>
        <div class="sidebar-library"><span class="nav-label">A TU MANERA</span><div class="library-note"><div class="mini-cover"><%= Icon("heart") %></div><div><strong>Lo que te mueve</strong><span>Guarda tus favoritas con un ♥</span></div></div><p>Tus likes se guardan en este navegador para tu usuario.</p></div>
        <div class="sidebar-bottom"><div class="sidebar-station"><span class="station-lines" aria-hidden="true">▂ ▆ ▃ █ ▅</span><div><strong>Tu propia frecuencia</strong><span>Sin prisa. Sin ruido.</span></div></div><span class="sidebar-version">FRECUENCIA &nbsp; / &nbsp; VOL. 01</span></div>
    </aside>
    <div class="app-content">
        <header class="topbar">
            <div class="breadcrumb">Tu espacio <span>/</span> <strong>Explorar</strong></div>
            <div class="search-box"><%= Icon("search") %><label class="sr-only" for="search">Buscar canciones, artistas o álbumes</label><input id="search" type="search" placeholder="Canciones, artistas, álbumes…" autocomplete="off"><kbd aria-hidden="true">/</kbd></div>
            <div class="user-menu"><span class="avatar" aria-hidden="true"><%= H(UCase(Left(TextValue(Session("Usuario")), 1))) %></span><span class="user-info"><strong><%= H(Session("Usuario")) %></strong><small><% If isAdmin Then %>Administrador<% Else %>Cuenta personal<% End If %></small></span><form method="post" action="logout.asp"><input type="hidden" name="csrf" value="<%= H(Session("Csrf")) %>"><button type="submit" class="icon-button logout-button" aria-label="Cerrar sesión" title="Cerrar sesión"><%= Icon("logout") %></button></form></div>
        </header>
        <main id="main">
            <% If notice <> "" Then %><div class="notice notice-success" role="status"><%= Icon("info") %><%= H(notice) %></div><% End If %>
            <div class="welcome-row"><div><span class="eyebrow muted">ENCUENTRA TU FRECUENCIA</span><h1>Hola, <span><%= H(Session("Usuario")) %></span><span class="greeting-dot">.</span></h1><p>Hay una canción para este momento. Encuentra la tuya.</p></div><span class="edition">TU DOSIS DIARIA<br><strong>DE BUENA MÚSICA</strong></span></div>
            <section class="hero" aria-labelledby="hero-title">
                <div class="hero-copy"><span class="hero-kicker"><span class="live-dot"></span> EN EL RADAR <span class="hero-number">/ 001</span></span><h2 id="hero-title">Baja el ruido.<br><span>Sube tu música.</span></h2><p>Desconecta de todo.<br>Conecta con lo que suena a ti.</p><div class="hero-actions"><button class="button button-primary" id="hero-play" type="button" disabled><%= Icon("play") %> Dale play</button><a class="hero-link" href="#catalogo">Explorar catálogo <%= Icon("arrow") %></a></div></div>
                <div class="hero-art" aria-hidden="true"><span class="art-orbit orbit-one"></span><span class="art-orbit orbit-two"></span><div class="vinyl"><div class="vinyl-label"><span>f.</span><small>EST. 2026</small></div></div><span class="art-caption">EL SONIDO<br>DE SER TÚ.</span><span class="art-coordinates">33⅓ RPM &nbsp; • &nbsp; STEREO</span></div>
            </section>
            <section class="catalog-section" id="catalogo" aria-labelledby="catalog-title">
                <div class="section-heading"><div><span class="eyebrow muted">DALE ESPACIO A OTROS SONIDOS</span><h2 id="catalog-title">Tu próxima obsesión<span class="section-dot">.</span></h2></div><% If Session("Rol") = "admin" Then %><a class="button button-quiet button-small" href="crud_canciones.asp"><%= Icon("plus") %> Nueva canción</a><% Else %><span class="catalog-total"><%= total %> canciones en tu radar</span><% End If %></div>
                <div class="catalog-toolbar"><div class="filter-tabs" role="group" aria-label="Filtrar catálogo"><button type="button" class="filter-tab selected" data-filter="all" aria-pressed="true">Todo el catálogo</button><button type="button" class="filter-tab" data-filter="available" aria-pressed="false">Con audio</button><button type="button" class="filter-tab" data-filter="favorites" aria-pressed="false">Favoritas <%= Icon("heart") %></button></div><span id="result-count" class="result-count" role="status"><%= total %> canciones</span></div>
                <div class="song-grid" id="song-grid">
                    <% Do While Not rs.EOF
                        songId = CLng(rs("ID_SONG"))
                        title = TextValue(rs("SONG_NAME"))
                        artist = TextValue(rs("ARTIST"))
                        album = TextValue(rs("ALBUM"))
                        cover = CoverPath(rs("ALBUM_IMAGE_PATH"), songId)
                        audioPath = AssetPath(rs("SONG_PATH"), "audio")
                        plays = CLng(rs("PLAYS"))
                    %>
                    <article class="song-card" data-track-id="<%= songId %>" data-title="<%= H(title) %>" data-artist="<%= H(artist) %>" data-album="<%= H(album) %>" data-cover="<%= H(cover) %>" data-audio="<%= H(audioPath) %>">
                        <div class="song-art"><img src="<%= H(cover) %>" alt="" loading="lazy" width="400" height="400"><span class="art-index"><%= Right("0" & songId, 2) %></span><button type="button" class="song-like icon-button" data-like="<%= songId %>" aria-label="Me gusta: <%= H(title) %>" aria-pressed="false"><%= Icon("heart") %></button><button type="button" class="card-play" data-play="<%= songId %>" aria-label="Reproducir <%= H(title) %>" <% If audioPath = "" Then Response.Write "disabled" %>><%= Icon("play") %></button><% If audioPath = "" Then %><span class="unavailable-badge">Audio no disponible</span><% End If %></div>
                        <div class="song-meta"><div class="song-title-line"><h3><%= H(title) %></h3><span class="playing-bars" aria-hidden="true"><i></i><i></i><i></i></span></div><p class="song-artist" title="<%= H(artist) %>"><%= H(artist) %></p><div class="song-details"><span title="<%= H(album) %>"><%= H(album) %></span><span data-duration="<%= songId %>">—:—</span></div><span class="song-plays"><%= plays %> reproducciones registradas</span></div>
                        <% If Session("Rol") = "admin" Then %><div class="card-admin"><a href="crud_canciones.asp?action=edit&amp;id=<%= songId %>" aria-label="Editar <%= H(title) %>"><%= Icon("edit") %> Editar</a><a class="text-danger" href="crud_canciones.asp?action=delete&amp;id=<%= songId %>" aria-label="Eliminar <%= H(title) %>"><%= Icon("trash") %> Eliminar</a></div><% End If %>
                    </article>
                    <% rs.MoveNext
                    Loop
                    CloseRecordset rs
                    Set cmd = Nothing
                    CloseConnection db
                    %>
                </div>
                <div id="empty-state" class="empty-state" <% If total > 0 Then Response.Write "hidden" %>><%= Icon("music") %><h3>No hay canciones para mostrar</h3><p id="empty-description">El catálogo está esperando su próxima canción.</p><% If isAdmin Then %><a href="crud_canciones.asp" class="button button-quiet">Añadir una canción</a><% End If %></div>
                <noscript><div class="notice notice-error">Activa JavaScript para reproducir, buscar canciones y guardar favoritos.</div></noscript>
            </section>
            <footer class="content-footer"><span>Hecho para escuchar diferente.</span><span>FRECUENCIA © 2026</span></footer>
        </main>
    </div>
    <section class="player" aria-label="Reproductor de música">
        <div class="player-track"><div class="player-cover-placeholder" id="player-placeholder"><%= Icon("music") %></div><img id="player-cover" class="player-cover" alt="" width="56" height="56" hidden><div class="player-track-text"><strong id="player-title">Tu momento empieza aquí</strong><span id="player-artist">Elige una canción para escuchar</span></div><button id="player-like" class="icon-button player-like" type="button" aria-label="Me gusta la canción actual" aria-pressed="false" disabled><%= Icon("heart") %></button></div>
        <div class="player-center"><div class="player-controls"><button id="shuffle" type="button" class="icon-button secondary-control" aria-label="Reproducción aleatoria" aria-pressed="false" disabled><%= Icon("shuffle") %></button><button id="previous" type="button" class="icon-button" aria-label="Canción anterior" disabled><%= Icon("previous") %></button><button id="toggle-play" class="main-play" type="button" aria-label="Reproducir" disabled><%= Icon("play") %></button><button id="next" type="button" class="icon-button" aria-label="Canción siguiente" disabled><%= Icon("next") %></button><button id="repeat" type="button" class="icon-button secondary-control" aria-label="Repetir canción" aria-pressed="false" disabled><%= Icon("repeat") %></button></div><div class="player-timeline"><span id="elapsed">0:00</span><label for="progress" class="sr-only">Posición de reproducción</label><input id="progress" type="range" min="0" max="1000" value="0" step="1" disabled><span id="duration">0:00</span></div></div>
        <div class="player-right"><span class="player-quality">AUDIO / MP3</span><button id="mute" class="icon-button" type="button" aria-label="Silenciar" aria-pressed="false"><%= Icon("volume") %></button><label for="volume" class="sr-only">Volumen</label><input id="volume" type="range" min="0" max="1" value="0.7" step="0.01"></div>
        <audio id="audio" preload="metadata"></audio>
        <p id="player-status" class="player-status" role="status" aria-live="polite"></p>
    </section>
</body>
</html>
