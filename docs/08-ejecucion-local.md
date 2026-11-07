# 08 · Ejecución local y escenarios de prueba

Objetivo: arrancar cualquier app en local en un clic, con la base de datos en el estado exacto que necesita la prueba.

## Servidor
- Siempre con **PostgreSQL 18 embebido** (zonky): BD temporal, se crea al arrancar y se borra al parar. Sin Docker.
- Puerto API `8080`. BD en `localhost:15432` (usuario y BD `postgres`, sin contraseña) para inspeccionarla con un cliente mientras corre.
- Lanzador: clase `LocalBracketyApplication` (en `server/src/test`, nunca llega al jar de producción).
- Perfil Spring `local`: CORS abierto a `localhost` y red local (192.168.x, 10.x, 172.x).
- Parada brusca (stop del IDE): el siguiente arranque mata el Postgres huérfano por su `postmaster.pid` y empieza de cero.
- Comprobar conexión y reloj: `GET /api/v1/info` → `{"name":"brackety","today":"…"}`.
- Primera vez en Windows: aceptar el aviso del firewall para Java (red privada) si se va a usar desde el móvil.

## Escenarios
Cada escenario es una clase `Scenario` en `server/src/test/java/dev/rgal/brackety/devdata/scenarios/`.
- Se elige con `--brackety.scenario=<nombre>` (por defecto `empty`).
- Nombre desconocido → el servidor no arranca y lista los disponibles.
- Fechas **siempre relativas al reloj** (`ctx.today()`, `ctx.now()`), nunca fijas: "evento que cierra inscripción mañana" sigue siéndolo cualquier día.
- Datos ficticios, nunca personales reales.
- Cada módulo que cierra añade sus escenarios y su run config. Catálogo abajo.

## Google simulado
- El lanzador local **siempre** usa el Google simulado, aunque haya `GOOGLE_CLIENT_ID`: confía en una clave generada al arrancar, no en Google. Probar el Google real exige el despliegue (o la imagen Docker) con los client IDs.
- idToken de prueba: `POST /api/v1/auth/dev/google-token` `{"subject":"google-solo","email":"google@example.test"}` → `{"idToken":"…"}`, válido 1 h. Se usa tal cual en `POST /api/v1/auth/google` o `POST /api/v1/me/identities/google`. Un `subject` nuevo = una persona de Google nueva.
- PowerShell: `irm -Method Post http://localhost:8080/api/v1/auth/dev/google-token -ContentType application/json -Body '{"subject":"s1","email":"a@example.test"}'`.
- Solo existe en el lanzador local (`server/src/test`); en producción ese endpoint no existe.

## Importación de alumnos local
- Sin `ANTHROPIC_API_KEY` el botón de importar no aparece. `--brackety.import.local-cli=true` lo activa con el `claude` y la sesión de quien desarrolla: **solo con listas ficticias** (las condiciones de la suscripción no cubren datos de terceros).
- Modelo: `--brackety.import.model=…` (por defecto `claude-sonnet-5-5`).

## Superadmin local
- Cloudflare Access simulado, como Google: la API local hace la comprobación real con una clave generada al arrancar y un filtro (`LocalAdminConfig`, solo en `server/src/test`) añade la cabecera que pondría Cloudflare si falta. La app admin funciona sin pasos extra.
- Superadmin: `superadmin@example.test` / `brackety-demo` en `POST /api/v1/admin/auth/login`.
- Probar la app admin: API con el escenario `superadmin` y `./run-app.ps1 -Target web -App admin`; entrar con el superadmin y ver Bloqueos y Organizadores.

## Reloj simulado
- Toda la lógica usa el `Clock` inyectado; prohibido `LocalDate.now()` sin reloj.
- `--brackety.clock.today=2027-03-10` desplaza el reloj a ese día (la hora sigue corriendo). Sirve para viajar en el tiempo con cualquier escenario.

## Cómo lanzar
| Dónde | Cómo |
|---|---|
| IntelliJ (servidor) | Run configs en `.run/`: `server · <escenario>`, `server · elegir escenario y fecha` (pregunta escenario y luego fecha `AAAA-MM-DD`; vacío = `empty` / hoy), `server · tests`. Requiere `server/pom.xml` cargado como proyecto Maven (módulo `brackety-server`) (*Maven home*: wrapper) |
| Android Studio (front) | Abrir `app/` (o `admin/`) como proyecto propio, nunca la raíz: el plugin Flutter necesita el `pubspec.yaml` en la raíz del proyecto. Plugin Flutter + SDK `C:\dev\flutter`. Run configs en `app/.run/` y `admin/.run/`: `app · <destino>`, `admin · <destino>` |
| Terminal | `./run-server.ps1 -Scenario <nombre> [-Today 2027-03-10]` · `-Scenario ?` lista los escenarios |
| Terminal | `./run-app.ps1 -Target web\|emulator\|device\|url [-Url https://…] [-App app\|admin]` |

## Front → backend
La URL de la API entra por `--dart-define-from-file=env/<destino>.json` (`API_BASE_URL`).
| Destino | URL | Notas |
|---|---|---|
| `web` | `http://localhost:8080` | app en puerto 5000, admin en 5001 |
| `emulator` | `http://10.0.2.2:8080` | 10.0.2.2 = el PC visto desde el emulador |
| `device` | `http://<IP LAN del PC>:8080` | el script detecta la IP; móvil en la misma wifi |
| `url` | la que se pase | Pi, túnel o cualquier servidor remoto |
- HTTP sin TLS a cualquier IP solo en builds debug (`android/app/src/debug/res/xml/network_security_config.xml`); en release, solo a `192.168.137.1` (pabellón, `servidor-local.md`).
- En Android Studio el dispositivo (Chrome, emulador, móvil) se elige en el desplegable de dispositivos; la run config fija el backend.
- `env/device.json` no se sube (lleva tu IP): lo crea `./run-app.ps1 -Target device`, o copia `env/device.example.json`.
- La pantalla **Conexión** de app y admin muestra la URL usada y la fecha del servidor: así se ve si el reloj simulado está activo.
- Gradle (Android) usa JDK 21 (`flutter config --jdk-dir`); el servidor, JDK 25.

## Navegador automatizado (Claude Code)
- Plugin `playwright` del proyecto (`.claude/settings.json`): Claude abre app (5000) y admin (5001), recorre flujos y hace capturas en 360×800, 800×1280 y 1440×900.
- Flutter web pinta en un canvas: en debug y con `APP_ENV=dev`, `enableSemanticsForAutomation()` (de `brackety_core`) activa el árbol de semántica para que Playwright encuentre botones y campos por su etiqueta. En release sigue apagado.
- Widgets sin texto visible (iconos): añadir `tooltip` o `Semantics(label:)` traducido; sirve también a lectores de pantalla.
- No sustituye a los widget tests ni a la prueba manual de Raul.

## Catálogo de escenarios
| Nombre | Contenido | Para probar |
|---|---|---|
| `empty` | BD vacía solo con migraciones | Primer arranque, registro desde cero |
| `accounts` | Una cuenta por perfil (`club@`, `entidad@`, `ayudante@`, `externo@`, `alumno@example.test`; organizadores sin fecha, con "Club Deportivo Ejemplo" `G12345674` y "Federación Ejemplo" `Q1234567D`; contraseña `brackety-demo`; sin verificar) y `bloqueada@example.test` bloqueada 15 min desde el arranque | Login, refresh, logout, bloqueo por intentos |
| `google` | `google@` solo Google (sub `google-solo`), `vinculada@` con contraseña `brackety-demo` y Google `vinculada.gmail@` (sub `google-vinculada`), `sustituible@` sin verificar (`@example.test`) | Login con Google, `REGISTRATION_REQUIRED`, sustitución de cuenta sin verificar, vincular y desvincular |
| `unverified` | Cuentas sin verificar (contraseña `brackety-demo`): `nueva@` recién creada, `recordatorio@` con 5 días y `purga@` con 7 (`@example.test`). La tarea diaria corre 1 min después de arrancar | Verificación pendiente, reenvío, recordatorio del día 5 y borrado del día 7 (enlaces en el log de la API) |
| `account-settings` | Cuentas verificadas (contraseña `brackety-demo`): `alumno.ayudante@` con Alumno y Ayudante, `borrada.dia1@` borrada ayer y `borrada.dia30@` borrada hace 30 días (`@example.test`). La purga diaria corre 1 min después de arrancar | Ajustes de cuenta (`/me`, perfiles, reauth, cambio de email, exportar), login de cuenta pendiente de borrado y restaurar, borrado definitivo |
| `superadmin` | Organizadores por validar (`club@`, `entidad@` en inglés) y uno validado (`club.validado@`); `bloqueada@` bloqueada por email y la IP `198.51.100.66` bloqueada, 15 min desde el arranque (`@example.test`, contraseña `brackety-demo`) | API de superadmin: login, bloqueos, validar organizadores (email en el log) |
| `yoseikan-f1` | Evento del prototipo hoy con 5 tapices, 9 categorías ficticias y 60 alumnos ficticios; cuentas `club1`, `ayudante1-2`, `arbitro1-5` (contraseña = usuario) | Prototipo Fase 1: configuración, inscripciones, grupos y marcador |
