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
- Si la API se cae sola: copia y la vuelve a arrancar (hasta 3 veces en 10 min; sin recargar el paquete). Puertos solo en el script (`SERVER_PORT`).
- Al parar (Ctrl+C o tras la 4.ª caída): copia `pg_dump -Fc` en `brackety-data/backups/` (se guardan 20) y para PostgreSQL. `-Backup`: solo la copia, con el servidor en marcha o parado.
- Punto de acceso: si está apagado intenta encenderlo (necesita una conexión que compartir, p. ej. la wifi del iPhone); si falla, avisa y sigue. `-NoHotspot` lo salta.
- Firewall: regla de entrada para `jre\bin\java.exe` (TCP 8080, privada y pública) solo desde `192.168.137.0/24` (el punto de acceso; otra wifi a la que se una el portátil no llega). Si falta, o hay una regla de entrada de ese `java.exe` abierta a cualquier red (p. ej. el aviso de Windows aceptado) o de bloqueo, pregunta y con un solo UAC borra las de ese programa y crea la buena. `localhost` no pasa por el firewall. `-NoFirewall` lo salta.
- Muestra al arrancar la URL de los móviles (`http://192.168.137.1:8080`, IP fija del punto de acceso de Windows) y la del portátil (`http://localhost:8080`).
- El primer arranque de una carpeta sin datos exige `-Package <fichero>` o `-Demo` (cuentas y evento demo del prototipo con la fecha de `-EventDate`, por defecto hoy). Sin ninguno no arranca: el evento de prueba nunca se mezcla con el real.
- `brackety-data/package-loaded.txt` o `demo-loaded.txt` (nombre y hora) marcan qué cargó el primer arranque; solo se escriben si la API arrancó bien. Con datos y sin marca (primer arranque fallido) se niega y sugiere `-Reset`.
- `-Reset` (servidor parado, confirma s/N): renombra `brackety-data` a `brackety-data.old-AAAAMMDD-HHmmss`, nunca borra. Con `-Package` o `-Demo` sigue con un primer arranque.
- `ACCESS_TTL=12h`: un móvil sin red un rato no pierde la sesión (el refresh sigue rotando).
- `SERVER_FORWARD_HEADERS_STRATEGY=none`: sin proxy delante, Tomcat no hace caso de `X-Forwarded-For` (con `native` confía en cualquier IP privada, también en los móviles del punto de acceso, que se saltarían el bloqueo por IP y el limitador). En la Pi se queda `native`: la API solo es accesible desde el propio host (`127.0.0.1`) y la red de Docker.
- `REFRESH_COOKIE_SECURE=false` (solo aquí): en http una cookie `Secure` no vuelve y la web perdería la sesión al recargar. En la Pi y Docker sigue `true`.
- Sin Internet: sin emails, sin Google, sin importación con Claude (los alumnos se importan antes, en la Pi o en local).

### Generar y usar la carpeta
1. En el PC de desarrollo (Internet la primera vez; el zip de PostgreSQL queda en `dist/cache/`): `.\deploy\local\build-event-bundle.ps1 [-Apk]`. Conserva `brackety-data/` si ya existe. Sin APK por defecto (en el pabellón se usa la web); `-Apk` la añade (el build tarda minutos).
2. Copiar `dist/brackety-event/` al disco del portátil.
3. `powershell -ExecutionPolicy Bypass -File .\start-event.ps1 -Package f1.zip | -Demo [-EventDate AAAA-MM-DD]` la primera vez; después sin ellos. Además `[-LegalOwnerName …] [-PrivacyContactEmail …] [-Backup] [-Reset]`. Resto en `LEEME.txt` de la carpeta.

### Superadmin en el portátil (2026-11-11)
- Sin Cloudflare Access en el pabellón: `start-event.ps1` pone `ADMIN_LOCAL_ONLY=true` y la API de superadmin solo responde al propio portátil (`127.0.0.1`/`::1`); a los móviles, 403.
- Web del superadmin en `http://localhost:8080/admin/` (`ADMIN_WEB_DIR`, build con `--base-href /admin/` en el paquete).
- Primer arranque: contraseña aleatoria; el hash lo hace el propio jar (`java -jar brackety.jar --superadmin-hash`, mismo Argon2) y va a `secrets.env`; email y contraseña en `brackety-data/superadmin.txt`.
- Sirve para reiniciar un combate o deshacer un grupo con puntos (como en la Pi).

### Paquete del evento, dispositivos y APK
En `servidor-local-paquete.md`.

## Legal
- El portátil guarda datos de menores: disco cifrado (BitLocker) y cuenta de Windows con contraseña. `start-event.ps1` avisa en amarillo, sin parar, si el disco de la carpeta no tiene BitLocker activo (`Get-BitLockerVolume`; sin administrador, la propiedad de Explorer `System.Volume.BitLockerProtection`) o si no se pudo comprobar.
- En el primer arranque, `icacls` deja `brackety-data/` solo para el usuario de Windows actual, SYSTEM y Administradores (sin herencia; lo de dentro la hereda). Al acabar la fase, borrar `brackety-data/` y el `.brackety` (pendiente de confirmar por Raul).

## Datos
Sin tablas nuevas. Formato del paquete versionado (`schemaVersion`).

## API
- `WEB_DIR` (`brackety.web-dir`): carpeta con la build web que sirve la propia API, sin login; un GET sin fichero que no sea `/api/**` ni `/actuator/**` devuelve `index.html`. Todo con `no-cache`. Vacía (Docker y producción, donde la sirve nginx) = la API no sirve web.
- Web del paquete: `app/env/event-bundle.json` con `API_BASE_URL=same-origin` (la API es el origen de la página; solo web).
- `GET /events/{id}/export/full` (.zip) y `POST /events/{id}/import/results?dryRun=` (cuerpo: el fichero), solo CLUB.
- `GET /api/v1/events/{id}/export/package` (solo CLUB del evento, como los CSV): `application/json`, `Content-Disposition: attachment; filename="<nombre-en-slug>-<fecha>.brackety"`. El log solo lleva recuentos. CORS expone `Content-Disposition` para que la web use ese nombre.
- Carga al arrancar con `BRACKETY_PACKAGE` (`brackety.package`, ruta del fichero), no por API.
- Superadmin: `GET /api/v1/admin/event-reset` (`packageName` o null) · `POST /api/v1/admin/event-reset` (`reason`; 404 sin paquete).

## Pantallas
- Club: menú Exportar (icono de descarga, solo web como los CSV) con los 3 CSV y "Exportar paquete del evento"; el fichero se llama como dice el servidor.
- Login (app, solo Android): línea "Servidor: <nombre>" con la URL y "Cambiar" (diálogo con las 3 opciones y el campo de URL). La pantalla Conexión muestra el elegido.

## Offline
Ver `offline.md` (adelanto F1: marcador del árbitro).

## Tests
Web servida por la API (`WebAppConfigTest`, `WebAppDisabledTest`): fichero, `index.html` para rutas de la app, API sin cambios; apagada por defecto. `X-Forwarded-For` por Tomcat real (`ForwardedForIgnoredTest`, `ForwardedForBehindProxyTest`): con `none` no cambia la IP del limitador ni del bloqueo; con `native` sí. `same-origin` en `api_config_test.dart`. Scripts: prueba a mano.
Paquete (`EventPackageServiceTest`, `EventPackageControllerTest`): ida y vuelta a BD vacía (ajustes, categorías por equipos, tapices con y sin árbitro, staff, inscritos con categoría elegida); rechazo con BD usada, versión desconocida y contenido inválido sin escribir nada; cuentas creadas con contraseña aleatoria (alfabeto y longitud) que entran con ella y no con el usuario, cuenta existente reutilizada sin listarla; cargador de arranque con el fichero de contraseñas y sin él; permisos (club 200, ayudante y árbitro 403, ajeno 404, sin token 401) y cabeceras. App: menú con el paquete en 3 tamaños (endpoint y nombre). Scripts: prueba a mano. Selector de servidor (`test/features/auth/server_*`): diálogo en 3 tamaños (URL inválida, aviso de http, guardar), opción conocida y cancelar, Conexión con el elegido, web sin selector; unit de validación de URL, elección por defecto (build, guardado, web) y descarte de tokens al cambiar. Red de Android y APK: prueba a mano.

## Plan (PRs en serie)
1. Servidor portable (`start-event.ps1`, BD persistente, web servida por la API, firewall, copia).
2. Paquete del evento (exportar y cargar al arrancar).
3. APK: selector de servidor, http solo al pabellón, build de release y cómo instalarla.
4. Ensayo: portátil como punto de acceso sin Internet, 3 móviles, un combate completo.

## Estado
En curso: pasos 1-3 hechos (2026-11-05). Paso 3: APK release generada; falta probarla en móviles reales con el punto de acceso (paso 4).
Pasos 1-2 (2026-11-04). Probado en el PC de desarrollo (arranque, web, login, datos tras reiniciar, copia al parar con Ctrl+C y con `-Backup`) sin punto de acceso ni UAC: falta probarlos en el portátil del evento.
Paso 2 probado a mano con la carpeta generada: paquete exportado de `yoseikan-f1` (75 inscritos, 5 tapices) → `-Package` en carpeta vacía (evento, inscritos, tapices con árbitro, `arbitro1` entra), reinicio sin recarga, `-Package` y `-Reset` rechazados con datos o en marcha, paquete inválido rechazado con su motivo, `-Demo`, `-Reset` archiva.
