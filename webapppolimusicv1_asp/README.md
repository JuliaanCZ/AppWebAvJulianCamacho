# Frecuencia · cómo ejecutar la aplicación

La aplicación usa ASP Clásico con VBScript y ADODB. No necesita generar un ejecutable: IIS Express interpreta los archivos `.asp` al abrirlos en el navegador.

## Estado comprobado el 20 de octubre de 2026

| Componente | Estado |
| --- | --- |
| Aplicación real en IIS Express | Iniciada en http://localhost:8098/login.asp. |
| Base original | `Laptop-Julian\JULIAN` → `BDD_PoliMusic`, online, conservada sin cambios. |
| Contenedor `sql-server2025` | Iniciado; publica el puerto del equipo `14333` hacia el puerto `1433` del contenedor. |
| Base en el contenedor | `BDD_PoliMusic`, restaurada y online, con 5 canciones y 4 usuarios. |
| Conexión de la aplicación | **Conectada y verificada** por ADODB en `127.0.0.1,14333`. |

**SSMS es un cliente:** cuando ejecutas una query, esta actúa sobre el servidor seleccionado en el Explorador de objetos. Crear la base en `Laptop-Julian\JULIAN` no la crea también en Docker.

Con tu autorización, se creó un respaldo `COPY_ONLY`, se verificó su checksum y se restauró una copia en `sql-server2025`, sin sobrescribir otra base. Se configuró el login de la copia con las credenciales del proyecto y el mismo SID del usuario restaurado. La revisión de integridad `DBCC CHECKDB` finalizó correctamente. No se ejecutó el script SQL de referencia.

**Son dos bases independientes:** lo que crees o edites desde esta web se guarda en Docker. La base original en `JULIAN` permanece como estaba; no existe sincronización automática entre ambas.

## Qué puedes abrir ahora

- **Aplicación ASP real:** [http://localhost:8098/login.asp](http://localhost:8098/login.asp). Ejecuta VBScript en IIS y ya consulta la copia real de SQL Server en Docker. Este es el enlace que debes usar para probar login, catálogo y CRUD.
- La herramienta visual del puerto `8099` es opcional y usa datos aislados. No la necesitas para ejecutar la aplicación real.

## Ejecutar desde PowerShell, paso a paso

### 1. Abrir la carpeta del proyecto

Abre PowerShell y ejecuta:

```powershell
Set-Location 'C:\Users\PERSONAL\Desktop\UNIVERSIDAD\OCTAVO SEMESTRE\Web Avanzadas\AppWebAvJulianCamacho\webapppolimusicv1_asp'
```

Todos los comandos siguientes se ejecutan desde esa carpeta.

### 2. Comprobar SQL Server

Abre Docker Desktop. Para iniciar el contenedor existente y ver su estado:

```powershell
docker start sql-server2025
docker ps
```

Debe aparecer `sql-server2025` con un mapeo como `14333->1433/tcp`. Esto confirma que el motor está encendido; **no confirma que la base del proyecto exista dentro de él**.

Para comprobar exactamente la conexión que usa `conexion.asp`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\check-database.ps1
```

- `CONECTADO: BDD_PoliMusic ...` significa que el usuario configurado pudo entrar y leer las tablas de canciones y usuarios.
- `Login failed for user 'usr_polimusic'` significa que SQL responde pero no acepta ese login. Revisa que estás usando el contenedor correcto y las credenciales configuradas.
- Un error de tiempo de espera indica que el destino no responde o no es accesible.

Esta comprobación solo hace consultas de lectura. Usa la misma cadena de conexión del código ASP.

### 3. Iniciar el servidor web

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\start-local.ps1
```

El comando inicia IIS Express en segundo plano y muestra el enlace. Si ya está abierto para este proyecto, muestra `YA INICIADO` y reutiliza la instancia.

```text
http://localhost:8098/login.asp
```

Abre ese enlace en el navegador. Puedes cerrar la terminal después de iniciar IIS. No abras los `.asp` con doble clic ni con Live Server: esas opciones no ejecutan VBScript del lado servidor.

### 4. Entrar y probar

Estas dos cuentas se probaron correctamente contra la copia de Docker:

| Usuario web | Contraseña de referencia | Permisos |
| --- | --- | --- |
| `userNormal` | `12345678` | Explorar y reproducir. |
| `userAdmin` | `12345678` | Explorar, reproducir y gestionar canciones. |

Estos son usuarios de la página web. `usr_polimusic` es otro usuario: lo utiliza el servidor ASP para acceder a SQL Server y no se escribe en el formulario de login.

Para ver **la misma base que usa la web desde SSMS**, abre una nueva conexión con nombre de servidor `127.0.0.1,14333`, autenticación de SQL Server, usuario `usr_polimusic` y contraseña `Politecnica1`. Expande Bases de datos → `BDD_PoliMusic`. Tu conexión anterior a `JULIAN` seguirá mostrando la base original.

Prueba la búsqueda, el filtro «Con audio», los corazones y la reproducción. Para el administrador, «Nueva canción» abre el formulario; «Editar» conserva las relaciones existentes; «Eliminar» muestra una confirmación antes de enviar el borrado.

### 5. Detener la aplicación

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\stop-local.ps1
```

Este comando detiene únicamente el IIS Express de este proyecto. No detiene SQL Server ni toca sus datos.

## Archivos y configuración

| Archivo | Función |
| --- | --- |
| `conexion.asp` | Conexión ADODB, parámetros SQL, sesiones, roles, CSRF y validación de assets. |
| `login.asp` / `logout.asp` | Autenticación y cierre de sesión. |
| `index.asp` | Catálogo sin tablas HTML, bienvenida, permisos y reproductor. |
| `crud_canciones.asp` | Crear, editar y eliminar canciones; backend limitado al rol admin. |
| `styles.css` | Diseño negro/blanco con verde para reproducción y rojo para likes, errores y eliminación. |
| `player.js` | Audio HTML5, progreso, duración, volumen, cambio de pista, búsqueda y favoritos. |
| `web.config` | Configuración de IIS y bloqueo de descarga del SQL y las herramientas de prueba. |

La cadena actual, en `conexion.asp`, es:

```text
Provider=MSOLEDBSQL;Data Source=127.0.0.1,14333;Initial Catalog=BDD_PoliMusic;User ID=usr_polimusic;Password=Politecnica1;Use Encryption for Data=True;Trust Server Certificate=True;
```

IIS Express y el proveedor OLE DB ya están instalados y su carga fue verificada en este equipo. En otro equipo se necesitan IIS/IIS Express con ASP Clásico, sesiones habilitadas y un proveedor `MSOLEDBSQL` de arquitectura compatible. El lanzador usa un pool sin CLR; los errores detallados se habilitan solo para estas pruebas locales.

**No ejecutes `BDD_PoliMusic.sql` sobre tu base existente:** contiene instrucciones destructivas. Se conserva como referencia del esquema y las credenciales. No se ejecutó durante las comprobaciones.

## Audio y comportamiento

- Solo se entregó `SongFilesAndImages_resources/SongFiles/bensound-adventure.mp3`. Las otras canciones muestran «Audio no disponible» hasta copiar sus MP3.
- Para registrar otro audio, copia primero el archivo a esa carpeta y selecciona su ruta en el formulario del administrador. La app no sube archivos.
- Si falta una portada de álbum, se muestra una imagen local alternativa de `PlaylistImages/`.
- Los likes se guardan por usuario en este navegador, no en SQL Server.
- La duración se obtiene al cargar la pista. No se inventan campos de género o duración en la base.
- `PLAYS` muestra el valor existente y no se incrementa automáticamente. Una canción nueva empieza en 0.
- Al borrar una canción se eliminan sus relaciones con playlists, álbumes y artistas dentro de una transacción. No se borran archivos ni los álbumes, artistas o playlists completos.
- Buscar o filtrar no detiene el audio; cambiar de página sí lo detiene.

## Herramientas de verificación y vista visual

Comprobar la sintaxis sin consultar la base:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\check-asp.ps1
```

Generar y servir nuevamente la vista visual sin base de datos:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\render-preview.ps1
node tests\preview-server.js
```

Abre `http://localhost:8099/index.asp`. Cuando lo ejecutes así, deja esa terminal abierta y usa `Ctrl+C` para detener la vista visual. Node solo sirve esta captura de prueba; el backend real sigue siendo ASP Clásico en IIS.

Los logs de IIS están en `tests/.runtime/iis.stdout.log` y `tests/.runtime/iis.stderr.log`. Estos directorios de pruebas no son accesibles por HTTP desde la aplicación.

Validado: sintaxis VBScript/JavaScript, conexión ADODB real, login normal/admin, bloqueo de CRUD por GET y POST para el usuario normal, rechazo de CSRF incorrecto y cierre de sesión. Contra la copia de Docker se creó, editó y eliminó exclusivamente una fila temporal de prueba; el catálogo conserva sus 5 canciones y 4 usuarios. En el navegador también se comprobó el login real de administrador y la reproducción de Adventure (3:07) desde IIS. Filtros y favoritos se revisaron adicionalmente con datos aislados.

Para repetir las pruebas HTTP sin modificar canciones:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\smoke-http.ps1
```

La opción `-ExerciseCrud` añade una prueba de creación y edición; al terminar elimina únicamente la fila temporal que esa ejecución haya creado. No necesita ejecutarse para iniciar la aplicación.

El respaldo de transferencia y el registro de la copia se conservan dentro de `tests/.runtime/`, que está ignorado por Git y bloqueado por HTTP. No son necesarios para arrancar: la base restaurada ya está dentro del contenedor. Conserva el contenedor y sus datos; `docker start` lo vuelve a encender sin restaurar el respaldo cada vez.

Documentación oficial: [ASP Clásico en IIS](https://learn.microsoft.com/uk-ua/iis/application-frameworks/running-classic-asp-applications-on-iis-7-and-iis-8/scenario-build-a-classic-asp-website-on-iis), [parámetros ADODB](https://learn.microsoft.com/en-us/troubleshoot/developer/webapps/iis/active-server-pages/run-sql-server-stored-procedures-asp-page).
