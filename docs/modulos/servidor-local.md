# Módulo · servidor-local (pabellón sin Internet)

Pedido por Raul el 2026-11-04 como medida de seguridad para la Fase 1: un portátil Windows hace de servidor y de punto de acceso; los móviles se conectan a él. Complementa a la Pi (`prototipo-f1.md`), no la sustituye.

## Objetivo
Llevar el evento ya preparado (configuración e inscripciones) y arrancarlo en cualquier portátil Windows con un solo comando, sin Internet, Docker ni instalaciones.

## Reglas
### Servidor portable
- Carpeta portable `dist/brackety-event/` (no se sube): `api/brackety.jar` (el jar de producción), `web/` (build web de `app/`), `jre/` (JDK 25 reducido con jlink), `pgsql/` (PostgreSQL 18 oficial de EnterpriseDB, solo `bin`, `lib`, `share` + runtime de Visual C++ del JDK), `start-event.ps1` y `LEEME.txt`. Unos 380 MB.
- PostgreSQL real (binarios portables), no el embebido de los tests: mismo jar que producción y `pg_dump` para las copias.
- `start-event.ps1` (PowerShell 7 o Windows PowerShell 5.1) arranca PostgreSQL solo en `127.0.0.1:15433` y la API en el puerto 8080 de todas las interfaces, con las variables de producción. La web sale de la propia API (mismo origen, sin CORS).
- Datos en `brackety-data/` junto al script: `pgdata/`, `secrets.env` (contraseña de la BD y `JWT_SECRET`, aleatorios en el primer arranque), `event.env` (titular y email de privacidad, editable), `pg.log`, `api.log`, `backups/`.
- Parar y volver a arrancar no pierde nada; solo se borra a mano.
- Al parar (Ctrl+C o si la API se cae): copia `pg_dump -Fc` en `brackety-data/backups/` (se guardan 20) y para PostgreSQL. `-Backup`: solo la copia, con el servidor en marcha o parado.
- Punto de acceso: si está apagado intenta encenderlo (necesita una conexión que compartir, p. ej. la wifi del iPhone); si falla, avisa y sigue. `-NoHotspot` lo salta.
- Firewall: si falta la regla de entrada para `jre\bin\java.exe` (TCP 8080, privada y pública), pregunta y la añade con permiso de administrador (UAC). `-NoFirewall` lo salta.
- Muestra al arrancar la URL de los móviles (`http://192.168.137.1:8080`, IP fija del punto de acceso de Windows) y la del portátil (`http://localhost:8080`).
- Cuentas demo del prototipo (`DEMO_ACCOUNTS_ENABLED=true`) con la fecha de `-EventDate` (por defecto hoy) hasta que llegue el paquete del evento (paso 2).
- La cookie de refresco es `Secure`: en http solo `localhost` mantiene la sesión web al recargar. Los móviles usarán la APK (paso 3).
- Sin Internet: sin emails, sin Google, sin importación con Claude (los alumnos se importan antes, en la Pi o en local).

### Generar y usar la carpeta
1. En el PC de desarrollo (Internet la primera vez; el zip de PostgreSQL queda en `dist/cache/`): `.\deploy\local\build-event-bundle.ps1`. Conserva `brackety-data/` si ya existe.
2. Copiar `dist/brackety-event/` al disco del portátil.
3. `powershell -ExecutionPolicy Bypass -File .\start-event.ps1 [-EventDate AAAA-MM-DD] [-LegalOwnerName …] [-PrivacyContactEmail …]`. Resto en `LEEME.txt` de la carpeta.

### Paquete del evento
- El club exporta desde cualquier servidor un fichero `.brackety` (JSON con versión de esquema): evento, categorías, tapices, staff (cuentas por nombre de usuario) e inscritos. Sin grupos, combates ni datos de cuentas.
- `start-event.ps1 -Package f1.brackety`: solo con la BD vacía lo carga y crea las cuentas demo del staff; con BD ya usada lo rechaza (no mezcla eventos).
- Tras arrancar, el evento está listo: el club ve sus inscritos y los ayudantes ya pueden crear grupos.
- El fichero lleva datos de menores: se guarda solo en el portátil del evento y se borra después (ver Legal).

### Dispositivos
- Árbitros y ayudantes usan la **APK Android** (el offline de la web exige https, ver `offline.md`).
- La APK elige el servidor en el login: "Pabellón" (`http://192.168.137.1:8080`), "Internet" (`https://brackety-api.rgal.dev`) o una URL a mano. Se recuerda en el dispositivo.
- http sin cifrar solo hacia la IP del pabellón (configuración de red de Android); el resto, https.
- El club puede usar el navegador del propio portátil (`http://localhost:8080`).

## Legal
- El portátil guarda datos de menores: disco cifrado (BitLocker) y cuenta de Windows con contraseña. Al acabar la fase, borrar `brackety-data/` y el `.brackety` (pendiente de confirmar por Raul).

## Datos
Sin tablas nuevas. Formato del paquete versionado (`schemaVersion`).

## API
- `WEB_DIR` (`brackety.web-dir`): carpeta con la build web que sirve la propia API, sin login; un GET sin fichero que no sea `/api/**` ni `/actuator/**` devuelve `index.html`. Todo con `no-cache`. Vacía (Docker y producción, donde la sirve nginx) = la API no sirve web.
- Web del paquete: `app/env/event-bundle.json` con `API_BASE_URL=same-origin` (la API es el origen de la página; solo web).
- `GET /api/v1/events/{id}/export/package` (club): descarga el paquete.
- Carga del paquete al arrancar (`--brackety.package=<ruta>`), no por API.

## Pantallas
- Club: botón "Exportar paquete del evento" junto a los CSV.
- Login (app): selector de servidor; la pantalla Conexión muestra el elegido.

## Offline
Ver `offline.md` (adelanto F1: marcador del árbitro).

## Tests
Web servida por la API (`WebAppConfigTest`, `WebAppDisabledTest`): fichero, `index.html` para rutas de la app, API sin cambios; apagada por defecto. `same-origin` en `api_config_test.dart`. Scripts: prueba a mano.
Paquete: exportar → cargar en BD vacía → mismo evento e inscritos; rechazo con BD usada y con versión desconocida. Arranque persistente: datos tras reiniciar. Selector de servidor: widget test en 3 tamaños.

## Plan (PRs en serie)
1. Servidor portable (`start-event.ps1`, BD persistente, web servida por la API, firewall, copia).
2. Paquete del evento (exportar y cargar al arrancar).
3. APK: selector de servidor, http solo al pabellón, build de release y cómo instalarla.
4. Ensayo: portátil como punto de acceso sin Internet, 3 móviles, un combate completo.

## Estado
En curso: paso 1 hecho (2026-11-04). Probado en el PC de desarrollo (arranque, web, login, datos tras reiniciar, copia al parar con Ctrl+C y con `-Backup`) sin punto de acceso ni UAC: falta probarlos en el portátil del evento.
