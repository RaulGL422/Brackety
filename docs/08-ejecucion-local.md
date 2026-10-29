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

## Reloj simulado
- Toda la lógica usa el `Clock` inyectado; prohibido `LocalDate.now()` sin reloj.
- `--brackety.clock.today=2027-03-10` desplaza el reloj a ese día (la hora sigue corriendo). Sirve para viajar en el tiempo con cualquier escenario.

## Cómo lanzar
| Dónde | Cómo |
|---|---|
| IntelliJ (servidor) | Run configs en `.run/`: `server · <escenario>`, `server · elegir escenario y fecha` (pregunta ambos; fecha vacía = hoy), `server · tests`. Requiere `server/pom.xml` cargado como proyecto Maven (módulo `brackety-server`) |
| Android Studio (front) | Abrir la raíz del repo con el plugin Flutter y SDK `C:\dev\flutter`: `app · <destino>`, `admin · <destino>` |
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
- HTTP sin TLS solo en builds debug (`android/app/src/debug/AndroidManifest.xml`).
- En Android Studio el dispositivo (Chrome, emulador, móvil) se elige en el desplegable de dispositivos; la run config fija el backend.
- `env/device.json` no se sube (lleva tu IP): lo crea `./run-app.ps1 -Target device`, o copia `env/device.example.json`.
- La pantalla **Conexión** de app y admin muestra la URL usada y la fecha del servidor: así se ve si el reloj simulado está activo.
- Gradle (Android) usa JDK 21 (`flutter config --jdk-dir`); el servidor, JDK 25.

## Catálogo de escenarios
| Nombre | Contenido | Para probar |
|---|---|---|
| `empty` | BD vacía solo con migraciones | Primer arranque, registro desde cero |
