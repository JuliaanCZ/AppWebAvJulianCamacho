using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Web;
using System.Web.Security;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    public partial class Song : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            Entities.User user = Session[Util.Constants.USER] as Entities.User;
            if (user == null)
            {
                FormsAuthentication.SignOut();
                Response.Redirect("Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetNoStore();

            if (!IsPostBack)
            {
                litUserName.Text = user.UserName;
                string photoPath = GetLocalResourcePath(user.Photo, "UserImages");
                imgUser.ImageUrl = photoPath != null && File.Exists(Server.MapPath(photoPath))
                    ? ResolveUrl(photoPath) : ResolveUrl("~/UserImages/default.jpg");
                LoadSongs();
            }
        }

        private void LoadSongs()
        {
            try
            {
                ConnectionStringSettings settings = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"];
                if (settings == null || string.IsNullOrEmpty(settings.ConnectionString))
                {
                    ShowMessage("Falta configurar la conexión BDD_PoliMusicConnectionString en Web.config.");
                    return;
                }

                DataTable songs = new BLL.Song(settings.ConnectionString).Read();
                gvSongs.DataSource = songs;
                gvSongs.DataBind();
                if (gvSongs.HeaderRow != null)
                {
                    gvSongs.HeaderRow.TableSection = TableRowSection.TableHeader;
                }
                lblSongCount.Text = songs.Rows.Count + (songs.Rows.Count == 1 ? " canción" : " canciones");
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Trace.TraceError("No se pudo consultar el catálogo de canciones: {0}", ex);
                ShowMessage("No se pudo cargar el catálogo. Comprueba que SQL Server esté iniciado y revisa la conexión a BDD_PoliMusic en Web.config.");
            }
        }

        protected void GvSongs_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow)
            {
                return;
            }

            DataRowView song = (DataRowView)e.Row.DataItem;
            HtmlGenericControl audio = (HtmlGenericControl)e.Row.FindControl("audioSong");
            Label missingAudio = (Label)e.Row.FindControl("lblMissingAudio");
            string songPath = GetLocalResourcePath(Convert.ToString(song["SONG_PATH"]), "SongFiles");
            bool fileExists = songPath != null &&
                string.Equals(Path.GetExtension(songPath), ".mp3", StringComparison.OrdinalIgnoreCase) &&
                File.Exists(Server.MapPath(songPath));

            audio.Visible = fileExists;
            missingAudio.Visible = !fileExists;
            if (fileExists)
            {
                audio.Attributes["src"] = ResolveUrl(songPath);
                audio.Attributes["aria-label"] = "Reproducir " + Convert.ToString(song["SONG_NAME"]);
                audio.Attributes["data-song-title"] = Convert.ToString(song["SONG_NAME"]);
            }
        }

        private static string GetLocalResourcePath(string storedPath, string folder)
        {
            if (string.IsNullOrEmpty(storedPath))
            {
                return null;
            }

            // La base del taller contiene rutas tanto ~/songFiles/ como ../songFiles/.
            string relativePath = storedPath.Trim().Replace('\\', '/');
            if (relativePath.StartsWith("~/", StringComparison.Ordinal))
            {
                relativePath = relativePath.Substring(2);
            }
            else if (relativePath.StartsWith("../", StringComparison.Ordinal))
            {
                relativePath = relativePath.Substring(3);
            }

            string prefix = folder + "/";
            if (!relativePath.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            {
                return null;
            }

            string fileName = relativePath.Substring(prefix.Length);
            if (string.IsNullOrEmpty(fileName) || fileName.IndexOfAny(new char[] { '/', ':', '?', '#', '%' }) >= 0 ||
                fileName == "." || fileName == "..")
            {
                return null;
            }

            return "~/" + folder + "/" + fileName;
        }

        private void ShowMessage(string message)
        {
            pnlMessage.Visible = true;
            litMessage.Text = message;
            lblSongCount.Text = "Catálogo no disponible";
        }
    }
}
