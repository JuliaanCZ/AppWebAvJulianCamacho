using System;
using System.Web.Security;

namespace WebAppPoliMusicV3
{
public partial class Logout : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        Session.Clear();
        Session.Abandon();
        FormsAuthentication.SignOut();
        Response.Redirect("~/Login");
    }
}
}
