<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="WebAppPoliMusicV3.Login" %>
<!DOCTYPE html>

<html lang="es" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Login | PoliMusic</title>
</head>
<body>
    <h2>Login</h2>
    <form id="formLogin" runat="server">
        <asp:Label runat="server" AssociatedControlID="txtLogin" Text="Username" />
        <asp:TextBox ID="txtLogin" runat="server" placeholder="Username"></asp:TextBox>
        <br />
        <asp:Label runat="server" AssociatedControlID="txtPassword" Text="Password" />
        <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" placeholder="Password"></asp:TextBox>
        <br />
        <asp:Button ID="btnLogin" runat="server" Text="Login" OnClick="BtnLogin_Click" />
        &nbsp;
        <asp:LinkButton ID="LinkButtonNewUser" runat="server" OnClick="LinkButtonNewUser_Click">Enroll new user</asp:LinkButton>
        <br />
        <asp:Label ID="lblMessage" runat="server" ForeColor="Red"></asp:Label>
</form>
</body>
</html>
