<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SignUp.aspx.cs" Inherits="WebAppPoliMusicV3.SignUp" %>

<!DOCTYPE html>
<html lang="es" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>SignUp | PoliMusic</title>
</head>
<body>
    <h2>Register new user</h2>
<form id="formLogin" runat="server">
        <div>
            <fieldset>

            <table>
                <tr>
                    <td>User name*:<br /><asp:Label runat="server" AssociatedControlID="txtUserName" Text="User name" />
        <asp:TextBox ID="txtUserName" runat="server"></asp:TextBox></td>
                    <td></td>
                </tr>
                <tr>
                    <td>Email*:<br /><asp:Label runat="server" AssociatedControlID="txtEmail" Text="Email" />
        <asp:TextBox ID="txtEmail" runat="server"></asp:TextBox></td>
                    <td>
                        </td>
                </tr>
                <tr>
                    <td>Password*:<br /><asp:Label runat="server" AssociatedControlID="txtPassword" Text="Password" />
        <asp:TextBox ID="txtPassword" runat="server" TextMode="Password"/></td>
                    <td></td>
                </tr>
                <tr>
                    <td>Confirm Password*:<br /><asp:Label runat="server" AssociatedControlID="txtConfirmPassword" Text="Confirm password" />
        <asp:TextBox ID="txtConfirmPassword" TextMode="Password" runat="server"/></td>
                    <td></td>
                </tr>
                <tr>
        <td>
            Birth Date (dd/MM/yyyy):<br /><asp:Label runat="server" AssociatedControlID="txtBirthDate" Text="Birth date dd/MM/yyyy" />
        <asp:TextBox ID="txtBirthDate" runat="server" />
        </td>
        <td>
            
        </td>
    </tr>
                <tr>
        <td>
            Photo:<br /><asp:Label runat="server" AssociatedControlID="fupPhoto" Text="Photo" />
        <asp:FileUpload ID="fupPhoto" runat="server" />
        </td>
        <td>
            
        </td>
    </tr>
                <tr>
        <td>
            <asp:Button ID="btnSumbit" runat="server" Text="Submit" OnClick="btnSumbit_Click" /><br /> 
            <asp:HyperLink ID="HyperLink1" NavigateUrl="~/Login.aspx" runat="server">Back to Login</asp:HyperLink>
        </td>
                    <td>
                        </td>
    </tr>
            </table>
                </fieldset>

        </div>
        <div>
            <asp:Panel ID="frmConfirmation" Visible="true" Runat="server">
                            <asp:Label id="lblMessage" ForeColor="Red" Font-Bold="true" Runat="server"></asp:Label>
                        </asp:Panel>
        </div>
    </form>
</body>
</html>
