# Taller 4 de PoliMusic V3

Implementación de los pasos 11 a 14 del laboratorio N-tier. El paso 15 queda preparado para que el estudiante realice el commit y el push.

## Ejecutar en Visual Studio

1. Abrir `SlnAppPoliMusic.slnx` con Visual Studio y la carga de trabajo de ASP.NET y desarrollo web, con .NET Framework 4.8.
2. Restaurar los paquetes NuGet de la solución.
3. Si falta `WebAppPoliMusicV3/ConnectionStrings.config`, copiar `ConnectionStrings.example.config` con ese nombre y completar la conexión de SQL Server local. Este archivo se excluye de Git.
4. Establecer `WebAppPoliMusicV3` como proyecto de inicio y `Default.aspx` como página inicial.
5. Ejecutar con IIS Express. Se solicita autenticación y, al iniciar sesión, se presenta `Default`; usar el menú **Canciones** para abrir el catálogo.

`PlaylistImages`, `SongFiles` y `UserImages` están incluidas explícitamente en `WebAppPoliMusicV3.csproj`. Si Visual Studio tenía una versión anterior cargada, aceptar **Recargar todo** o cerrar y abrir la solución.

## Implementación

- `EntityLayer.PoliMusicV3`: entidad `User` y utilidades del laboratorio.
- `DAL.PoliMusicV3/Song.cs`: consulta ADO.NET de `dbo.TBL_SONG` con conexiones y comandos desechables.
- `BLL.PoliMusicV3/Song.cs`: llama a la capa DAL.
- `WebAppPoliMusicV3`: login, registro, logout, manejo de archivos y catálogo `Song.aspx`, con `Site.Master`, CSS y JavaScript propios.
- La presentación referencia únicamente BLL y EntityLayer. El catálogo recibe los datos de BLL y no ejecuta SQL.
- Las rutas de audio se limitan a archivos MP3 de `SongFiles`. Los nombres se codifican al mostrarse. Los controles de audio tienen nombres accesibles y solo se reproduce una pista a la vez.

Se conserva SHA-1 para ser compatible con las cuentas y el código exigidos por la guía. La cuenta local `Julián Camacho` tiene el formato de hash esperado; la cuenta distinta `Julian.Camacho` almacena texto plano. No se modificaron las contraseñas ni los registros existentes.

## Archivos y bloques completados

| Ruta desde la raíz del repositorio | Bloque |
| --- | --- |
| `.gitignore` | Exclusiones del trabajo temporal y de la conexión local de V3. |
| `DAL.PoliMusicV3/DAL.PoliMusicV3.csproj` | Inclusión de `Song.cs` en `Compile`. |
| `DAL.PoliMusicV3/Song.cs` | Constructor y método `Read` con consulta de `TBL_SONG`. |
| `BLL.PoliMusicV3/BLL.PoliMusicV3.csproj` | Inclusión de `Song.cs` en `Compile`. |
| `BLL.PoliMusicV3/Song.cs` | Constructor y método `Read` que delega en DAL. |
| `WebAppPoliMusicV3/WebAppPoliMusicV3.csproj` | `Compile`, `Content`, `DependentUpon` y `Folder` de las páginas, los recursos y las tres carpetas. |
| `WebAppPoliMusicV3/FileManagement.cs` | `SaveImageOnServer`, `SaveDefaultImageOnServer` y `SaveSongOnServer` de la guía. |
| `WebAppPoliMusicV3/Login.aspx` y sus archivos `.cs` y `.designer.cs` | Formulario y controles; `Page_Load`, `BtnLogin_Click` y `LinkButtonNewUser_Click`; sesión y autenticación. |
| `WebAppPoliMusicV3/SignUp.aspx` y sus archivos `.cs` y `.designer.cs` | Formulario y controles; `btnSumbit_Click`, `UserFieldsRequiredValidations` e `IsValidEmail`; validación de confirmación, fecha y nombre de archivo. |
| `WebAppPoliMusicV3/Logout.aspx` y sus archivos `.cs` y `.designer.cs` | Página con `Site.Master`; `Page_Load` elimina la sesión y la autenticación. |
| `WebAppPoliMusicV3/Site.Master` | Nombre `PoliMusic - Julian.Camacho`, menús Canciones y Cerrar Sesión, navegación adaptable. |
| `WebAppPoliMusicV3/Web.config` | `appSettings`, conexión externa, límites de carga, autenticación y autorizaciones de Login y SignUp. |
| `WebAppPoliMusicV3/ConnectionStrings.example.config` | Ejemplo de la conexión sin credenciales reales. |
| `WebAppPoliMusicV3/Song.aspx` y `Song.aspx.designer.cs` | Contenido de la página maestra, usuario, GridView y controles HTML5 de audio. |
| `WebAppPoliMusicV3/Song.aspx.cs` | `Page_Load`, `LoadSongs`, `GvSongs_RowDataBound`, `GetLocalResourcePath` y `ShowMessage`. |
| `WebAppPoliMusicV3/Content/Song.css` | Diseño del catálogo, tabla, estados, foco visible y adaptación a pantallas estrechas. |
| `WebAppPoliMusicV3/Scripts/Song.js` | Eventos `play`, `pause`, `ended` y `error`; pausa de reproductores simultáneos y estado accesible. |
| `docs/taller4/LabWebAv04-ProyectoWebApp_NTier_JulianCamacho.docx` | Código de los pasos 11–13, evidencia y pruebas del 14, preparación del 15. |
| `docs/taller4/evidencias/` | Capturas originales del catálogo en ejecución, las carpetas en Visual Studio y los cambios locales de Git. |

La página inicial también quedó configurada en `WebAppPoliMusicV3.csproj.user`, que es una preferencia local excluida de Git. Visual Studio quedó con V3 como proyecto de inicio. Los archivos anteriores a estos pasos y los recursos ya copiados se conservaron.

## Verificación realizada

- Compilación de los cuatro proyectos de V3 en Debug.
- Acceso correcto con la cuenta existente `Julián Camacho` y retorno a `Default`.
- Rechazo de una contraseña incorrecta.
- Acceso anónimo a `Song` redirigido a `Login`.
- Registro accesible sin sesión y validación de campos obligatorios.
- Consulta real de las cinco canciones de `BDD_PoliMusic`.
- Reproducción de `Adventure`: tiempo de reproducción en aumento, duración aproximada de 187 segundos y ningún error del elemento de audio.
- Cierre de sesión con retorno a `Login` y posterior protección del catálogo.
- Menú adaptable verificado en la vista estrecha del navegador.

Solo está disponible `bensound-adventure.mp3`. Las otras cuatro filas corresponden a datos reales de la base y muestran **Archivo de audio no disponible** porque sus MP3 no están en los recursos proporcionados. Para habilitarlas, copiar sus archivos originales con los nombres guardados en la base a `WebAppPoliMusicV3/SongFiles` e incluirlos en el proyecto.

## Commit del paso 15

Revisar los archivos en **Git Changes**. `.user`, `.vs`, `packages`, `bin`, `obj`, los archivos temporales del taller y la conexión local están excluidos de Git. No se ha realizado commit ni push.

Mensaje sugerido: `Third WebApp N-Layer with .NetFramework 4.8`.

Después de realizar el commit y el push, agregar al informe la captura del repositorio publicado solicitada por el docente y volver a exportar el Word a PDF.
