# Laboratorio 03 Creación de la página Song

La sección Song está implementada en `WebAppPoliMusicV2`. Consulta SQL Server mediante las clases BLL y DAL y muestra un GridView con ID, nombre, ruta, reproducciones y audio. También presenta el usuario, su foto y el enlace para cerrar sesión, como en el ejemplo del taller. Las secciones anteriores conservan su implementación.

## Ubicación de los archivos

La distribución actual es correcta; no necesitas mover todo dentro de `WebAppPoliMusicV2`:

```text
AppWebAvJulianCamacho/
  .gitignore                       Reglas del repositorio completo
  SlnAppPoliMusic.slnx              Solución de Visual Studio
  GUIA_LAB03_SONG.md               Esta guía
  WebAppPoliMusicV2/               Proyecto ASP.NET Web Forms del laboratorio 03
    WebAppPoliMusicV2.csproj
    Song.aspx, Song.aspx.cs, Song.aspx.designer.cs
    Song.css, Song.js
    BLL/Song.cs
    DAL/Song.cs
    SongFiles/
  webapppolimusicv1_asp/           Proyecto anterior de ASP clásico
```

`WebAppPoliMusicV2_ASPX_F2.0`, dentro de la solución, es una carpeta virtual de Visual Studio. El taller pide que la solución `.slnx` esté en la raíz del repositorio. El SQL y los scripts de pruebas de `webapppolimusicv1_asp` pertenecen a la versión anterior; sus pruebas no validan esta aplicación ASPX.

## Archivos y bloques implementados

| Archivo | Bloques y comportamiento |
| --- | --- |
| `WebAppPoliMusicV2/DAL/Song.cs` | Constructor y método `Read()`: SELECT de `dbo.TBL_SONG`, conversión de PLAYS nulo a cero y cierre de recursos SQL con `using`. |
| `WebAppPoliMusicV2/BLL/Song.cs` | Constructor y método `Read()`: llamada a DAL y retorno del DataTable. |
| `WebAppPoliMusicV2/Song.aspx` | Cabecera con usuario/foto/logout, diseño propio y `gvSongs` con cinco columnas, incluida una TemplateField de audio HTML5. |
| `WebAppPoliMusicV2/Song.aspx.cs` | `Page_Load`, `LoadSongs`, `GvSongs_RowDataBound`, `GetLocalResourcePath` y `ShowMessage`: sesión, consulta, enlace del GridView, resolución de rutas locales y avisos. |
| `WebAppPoliMusicV2/Song.aspx.designer.cs` | Declaraciones de los controles de servidor de la página. |
| `WebAppPoliMusicV2/Song.css` | Diseño de escritorio y móvil, foco visible y desplazamiento horizontal de la tabla. |
| `WebAppPoliMusicV2/Song.js` | Eventos play/pause/ended/error, estado de reproducción y pausa de otros reproductores. |
| `WebAppPoliMusicV2/WebAppPoliMusicV2.csproj` | Inclusión de `Song.css` y `Song.js` como contenido del proyecto. |
| `.gitignore` | Adición de `*.user`, `packages/` y `obj/`; conserva las exclusiones previas. |

El flujo es `Song.aspx.cs → BLL.Song.Read() → DAL.Song.Read() → BDD_PoliMusic.dbo.TBL_SONG`. Todo continúa dentro del mismo proyecto monolítico con destino .NET Framework 2.0.

La columna Reproducciones muestra el valor almacenado en PLAYS. El taller pide mostrarlo; esta sección no incrementa el contador ni añade CRUD o carga de archivos.

## Ejecutar desde Visual Studio

1. Abre `SlnAppPoliMusic.slnx` desde la raíz del repositorio.
2. En el Explorador de soluciones, clic derecho en **WebAppPoliMusicV2 → Establecer como proyecto de inicio**.
3. Clic derecho en **Default.aspx → Establecer como página de inicio**.
4. En Propiedades del proyecto, confirma el destino **.NET Framework 2.0**. Usa IIS Express y el esquema HTTP ya configurado.
5. Ejecuta **Compilar → Compilar solución**. Para esta versión necesitas el soporte de .NET 2.0/3.5 y las herramientas de desarrollo web de Visual Studio.
6. Inicia SQL Server y verifica la conexión `BDD_PoliMusicConnectionString` de `WebAppPoliMusicV2/Web.config`. En esta revisión, `localhost` y `BDD_PoliMusic` respondieron correctamente. No necesitas cambiar a Docker para repetir esta configuración.
7. Pulsa **Ctrl+F5**. La URL usa el puerto que muestre Visual Studio; el proyecto tiene configurado `http://localhost:51402/`.
8. Aparecerá Login. Usa una cuenta de tipo normal. En esta revisión funcionó **username1 / 12345678**, una cuenta de ejemplo del SQL. Si cambiaste esa cuenta, usa tu cuenta normal o registra otra desde SignUp.
9. Después del login, `Default.aspx` redirige a `Song.aspx`. El taller menciona una vez `Songs.aspx`, pero el archivo solicitado y utilizado por el proyecto es **Song.aspx**, en singular.

La cuenta `Julian.Camacho` que Login precarga en DEBUG fue rechazada durante la prueba. Cambia los campos antes de iniciar sesión. Además, las cuentas `userNormal` y `userAdmin` del SQL original tienen contraseña en texto plano, mientras este Login compara un hash SHA-1, por lo que no son una referencia fiable para probar V2. La cuenta `username1` sí tiene el hash esperado.

Usa un usuario normal para esta sección: el login existente envía a los administradores a `DesktopAdmin.aspx`, una página que no está en el proyecto y que no forma parte de Song.

## Pruebas de funcionalidad

En SSMS, conéctate a la misma instancia que usa Web.config y ejecuta únicamente esta consulta de lectura:

```sql
USE BDD_PoliMusic;
SELECT ID_SONG, SONG_NAME, SONG_PATH, ISNULL(PLAYS, 0) AS PLAYS
FROM dbo.TBL_SONG
ORDER BY ID_SONG;
```

Compara los resultados con el GridView. No ejecutes `webapppolimusicv1_asp/BDD_PoliMusic.sql` para comprobar el listado: ese archivo incluye `DROP DATABASE IF EXISTS [BDD_PoliMusic]` y recrea la base.

| Prueba | Pasos | Resultado esperado |
| --- | --- | --- |
| Acceso sin sesión | En una ventana privada, abre directamente Song.aspx. | Redirección a Login.aspx. |
| Login válido | Ingresa con una cuenta normal. | Se abre Song, muestra el usuario y su foto o la imagen predeterminada. |
| Consulta real | Compara la tabla con el SELECT anterior. | Coinciden ID, nombre, ruta y reproducciones. En la base revisada existen cinco canciones. |
| Reproducción | Pulsa Play en Adventure. Después pausa, reanuda y cambia la posición. | El audio se escucha, el tiempo avanza y el estado indica la canción. |
| Archivo ausente | Revisa las filas cuyo MP3 no está en SongFiles. | Se muestra “Archivo de audio no disponible”; la fila sigue en el catálogo. |
| Otra canción | Cuando dispongas de al menos dos MP3, inicia uno y después otro. | El primero se pausa automáticamente. |
| Cierre de sesión | Pulsa Cerrar sesión y vuelve a abrir Song.aspx. | Se muestra Login y no se permite consultar Song sin autenticarse. |
| Teclado y móvil | Navega con Tab y prueba un ancho de 390 px. | Foco visible; la tabla se desplaza horizontalmente dentro de su contenedor. |

### MP3 que faltan

La base consultada tiene Adventure, Dreams, Energy, Scifi y Tomorrow, pero solo está incluido `WebAppPoliMusicV2/SongFiles/bensound-adventure.mp3`. Para reproducir las cinco, añade los recursos originales del taller con estos nombres:

```text
WebAppPoliMusicV2/SongFiles/bensound-dreams.mp3
WebAppPoliMusicV2/SongFiles/bensound-energy.mp3
WebAppPoliMusicV2/SongFiles/bensound-scifi.mp3
WebAppPoliMusicV2/SongFiles/bensound-tomorrow.mp3
```

Después, en Visual Studio usa **Mostrar todos los archivos → Incluir en el proyecto** sobre los nuevos MP3 y recarga Song. No es necesario inventar registros ni alterar las rutas de las cinco canciones existentes.

### Validación realizada

El 1 de noviembre de 2026 se comprobaron:

- Compilación del proyecto C# con MSBuild y destino .NET Framework 2.0.
- Precompilación de las páginas con `aspnet_compiler.exe` de .NET 2.0.
- Sintaxis de Song.js.
- SELECT de lectura sobre la base local, con cinco canciones.
- Prueba de navegador aislado sobre IIS Express con runtime v2.0: acceso anónimo, login con username1, listado real, foto, carga y avance del audio Adventure, pausa entre reproductores, vista móvil y cierre de sesión, sin errores JavaScript.

La pausa entre dos reproductores se verificó duplicando temporalmente el reproductor en el navegador; no se añadieron archivos ni registros. Aún debes comprobar el sonido en tus parlantes y reproducir los otros cuatro temas cuando incorpores sus MP3.

## Qué colocar en el documento del taller

Dentro de **Creación de página web Song**, reemplaza los textos de indicación del documento por:

1. Código completo de `DAL/Song.cs`.
2. Código completo de `BLL/Song.cs`.
3. Tu diseño: código de `Song.aspx`, `Song.css` y `Song.js`, y una captura de la página funcionando. Sustituye la pantalla de ejemplo del taller.
4. Código completo de `Song.aspx.cs` en el apartado Code Behind. El `.designer.cs` es auxiliar de Visual Studio y no sustituye este código.

En **Pruebas de funcionalidad**, incluye capturas del Login, Song con usuario y catálogo, y Adventure reproduciéndose con el tiempo avanzado. Para demostrar la consulta, puedes añadir la captura del SELECT en SSMS. Explica que los registros sin MP3 se señalan como no disponibles si todavía no has añadido los recursos faltantes.

## Commit y push desde Visual Studio

1. Abre **Ver → Cambios de Git**.
2. Revisa `.gitignore`: deben quedar excluidos `.vs`, `bin`, `obj`, `packages` y los archivos `*.user`.
3. **Antes de publicar, revisa Web.config:** actualmente contiene una contraseña local de SQL Server en texto plano. Evita publicar una credencial privada. Si tu instancia y tu cuenta permiten autenticación Windows, puedes usar una cadena sin contraseña, como `Data Source=localhost;Initial Catalog=BDD_PoliMusic;Integrated Security=True`, y probar de nuevo el login. Otra opción es separar la configuración local de credenciales antes del commit. La implementación de Song no modificó tu cadena de conexión.
4. Revisa y prepara los cambios. Actualmente toda la carpeta V2 y `SlnAppPoliMusic.slnx` están sin seguimiento; debes incluir **el proyecto V2 completo y la solución**, además de Song, para que el repositorio se pueda compilar. Conserva el proyecto ASP anterior en su carpeta.
5. Comprueba que el listado de archivos preparados incluya el código fuente, `.csproj`, `.slnx`, recursos y guía, y que no incluya `bin`, `obj`, `.vs` ni `.user`.
6. Escribe un mensaje, por ejemplo: **Second WebApp Monolithic One Layer with .NetFramework 2.0**.
7. Selecciona **Commit Staged and Push / Confirmar cambios preparados e insertar**. Si Visual Studio presenta acciones separadas, primero confirma y después pulsa Push.
8. Abre tu repositorio en GitHub, selecciona la rama publicada y verifica el commit, la solución y los archivos de Song dentro de V2.

### Alternativa desde terminal

Después de revisar la configuración y completar las pruebas, ejecuta estos comandos desde la raíz `AppWebAvJulianCamacho`, uno por uno:

```powershell
git status --short
git add -- .gitignore SlnAppPoliMusic.slnx GUIA_LAB03_SONG.md WebAppPoliMusicV2
git diff --cached --stat
git diff --cached
git commit -m "Second WebApp Monolithic One Layer with .NetFramework 2.0"
git push -u origin main
```

La rama revisada es `main`. Si cambias de rama antes de seguir esta guía, usa su nombre en el push. Si Git solicita autenticación, complétala con tu cuenta. Si rechaza el push porque hay cambios remotos, revisa el estado y sincroniza desde Visual Studio; no utilices `--force`.

En **Commit y Push** del taller, coloca la URL real del repositorio publicado y una captura de GitHub donde se vea el commit y la carpeta V2. Finalmente exporta el documento completado a PDF, que es el entregable solicitado por el taller.

Esta revisión implementó Song y preparó esta guía. No realizó commit, push ni modificaciones al archivo Word.
