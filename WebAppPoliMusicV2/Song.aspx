<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV2.Song" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml" lang="es">
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Canciones | PoliMusic</title>
    <link href="Song.css" rel="stylesheet" type="text/css" />
    <script src="Song.js" type="text/javascript" defer="defer"></script>
</head>
<body>
    <a class="skip-link" href="#songList">Ir al listado de canciones</a>
    <form id="form1" runat="server">
        <header class="topbar">
            <a class="brand" href="Default.aspx" aria-label="PoliMusic, inicio">
                <span class="brand-mark" aria-hidden="true">P</span> PoliMusic
            </a>
            <div class="account">
                <asp:Image ID="imgUser" runat="server" CssClass="avatar" AlternateText="Foto de perfil" />
                <div class="welcome">Bienvenido<br /><strong><asp:Literal ID="litUserName" runat="server" Mode="Encode" /></strong></div>
                <a class="logout" href="Logout.aspx">Cerrar sesión</a>
            </div>
        </header>
        <main id="songList" class="library" tabindex="-1">
            <section class="intro" aria-labelledby="pageTitle">
                <div>
                    <p class="eyebrow">TU BIBLIOTECA</p>
                    <h1 id="pageTitle">Dale play a tu día.</h1>
                    <p class="description">Explora tus canciones y escucha la que va contigo.</p>
                </div>
                <div class="record" aria-hidden="true"><span></span></div>
            </section>
            <div class="library-heading">
                <h2>Canciones</h2>
                <asp:Label ID="lblSongCount" runat="server" CssClass="song-count" />
            </div>
            <asp:Panel ID="pnlMessage" runat="server" CssClass="notice" Visible="false" role="alert">
                <asp:Literal ID="litMessage" runat="server" Mode="Encode" />
            </asp:Panel>
            <div class="table-scroll" role="region" aria-label="Listado de canciones" tabindex="0">
                <asp:GridView ID="gvSongs" runat="server" AutoGenerateColumns="false"
                    CssClass="song-table" GridLines="None" UseAccessibleHeader="true"
                    DataKeyNames="ID_SONG" OnRowDataBound="GvSongs_RowDataBound"
                    EmptyDataText="Todavía no hay canciones registradas."
                    Caption="Catálogo de canciones de PoliMusic">
                    <Columns>
                        <asp:BoundField DataField="ID_SONG" HeaderText="ID canción" HtmlEncode="true" />
                        <asp:BoundField DataField="SONG_NAME" HeaderText="Nombre" HtmlEncode="true" ItemStyle-CssClass="song-name" />
                        <asp:BoundField DataField="SONG_PATH" HeaderText="Ruta" HtmlEncode="true" ItemStyle-CssClass="song-path" />
                        <asp:BoundField DataField="PLAYS" HeaderText="Reproducciones" HtmlEncode="true" />
                        <asp:TemplateField HeaderText="Reproducir">
                            <ItemTemplate>
                                <audio id="audioSong" runat="server" controls="controls" preload="none">
                                    Tu navegador no admite la reproducción de audio HTML5.
                                </audio>
                                <asp:Label ID="lblMissingAudio" runat="server" CssClass="missing-audio"
                                    Text="Archivo de audio no disponible" Visible="false" />
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
            <p id="nowPlaying" class="now-playing" role="status" aria-live="polite">Selecciona una canción para comenzar.</p>
        </main>
        <footer class="footer">PoliMusic &middot; Tu música, a tu ritmo.</footer>
    </form>
</body>
</html>
