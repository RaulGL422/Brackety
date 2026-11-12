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

### Paquete del evento
- Desde 2026-11-11 el club exporta "Todo el evento (.zip)": CSV legibles en Excel (`;`, BOM, cabeceras en español, fechas dd/mm/aaaa, nombres en vez de ids), `evento.brackety` (esquema 2: liga, fase, organizaciones, ids de persona y resultados) y `LEEME.txt`. `-Package` acepta el `.zip` o el `.brackety`.
- Vuelta a la Pi: en el panel del club, "Importar resultados del pabellón" con el `.zip` del portátil. Primero cuenta (prueba en seco) y pide confirmación; luego trae grupos, equipos, combates y línea de tiempo. Idempotente (repetir no cambia nada); 409 si es de otro evento o si el de la Pi ya tiene grupos propios.
- Fichero `.brackety`, JSON UTF-8 con `schemaVersion: 1`, `exportedAt`, `event` (nombre, fecha, multigrupo, duración, límite de puntos, descanso entre combates, puntos por asistir), `owner` (usuario, organización y CIF), `staff` (usuario y rol, incluido el club), `categories` (nombre, edades, formato, tamaño de equipo), `mats` (número y usuario del árbitro o null) y `participants` (nombre, apellidos, nacimiento, estatura, consentimiento del tutor, categoría elegida o null).
- Sin ids, grupos, equipos, combates, importaciones, contraseñas ni más datos de cuentas que los usuarios del staff.
- Lo exporta el club del evento en cualquier momento (también con grupos, que no viajan).
- `start-event.ps1 -Package f1.brackety` en una carpeta sin datos: lo copia a `brackety-data/` y la API lo carga al arrancar, antes de abrir el puerto, en una transacción (todo o nada).
- Rechazos (la API no arranca y el script muestra el motivo, con campo e índice de fila, sin datos personales): BD con algún evento, `schemaVersion` desconocida, JSON inválido, categoría inexistente o repetida, tapices que no van de 1 a N, árbitro que no es REFEREE del staff o en dos tapices, dueño que no es CLUB del staff, menor sin consentimiento, CIF inválido, límites de campos.
- Cuentas del staff que falten: verificadas, `es`, contraseña aleatoria de 10 caracteres (minúsculas y dígitos sin `l`, `1`, `o`, `0`; `SecureRandom`); el dueño con perfil Club, organización y CIF del paquete; el resto Ayudante. Las existentes se reutilizan sin cambiar su contraseña.
- Las contraseñas nuevas van a `BRACKETY_PACKAGE_CREDENTIALS` (`brackety.package-credentials`, obligatoria con paquete), nunca al log: `usuario;rol;contraseña;tapices` (roles y tapices separados por comas). El script usa `brackety-data/credentials.txt` y lo muestra al acabar el primer arranque, con aviso de repartirlas a mano y borrarlo tras la fase. `-Demo` sigue con usuario = contraseña.
- Con paquete, `DemoSetup` no crea su evento (y nunca si ya hay alguno); el script apaga las cuentas demo.
- Tras arrancar, el evento está listo: el club ve sus inscritos y los ayudantes ya pueden crear grupos.
- El fichero lleva datos de menores: se guarda solo en el portátil del evento y se borra después (ver Legal).

### Dispositivos
- Árbitros y ayudantes usan la **web** del portátil (desde 2026-11-11 la web tiene la misma cola offline, ver `offline.md`). La APK queda como opción.
- La APK elige el servidor en el login: "Pabellón" (`http://192.168.137.1:8080`), "Internet" (`https://brackety-api.rgal.dev`) o "Otra URL" (http/https con host). Se recuerda en el dispositivo (almacén seguro, junto al refresh token).
- Por defecto, el `API_BASE_URL` del build. Solo en el login: cambiarlo cierra la sesión guardada (sus tokens son del otro servidor) y las peticiones siguientes van al nuevo sin reiniciar. La web no lo muestra.
- http sin cifrar solo hacia la IP del pabellón (`network_security_config.xml`); el resto, https. "Otra URL" con http a otra IP avisa de que no conectará. Los builds debug permiten http a cualquier IP (desarrollo local).
- El club puede usar el navegador del propio portátil (`http://localhost:8080`).

### APK (build e instalación)
- `cd app; flutter build apk --release --dart-define-from-file=env/apk-event.json` (servidor por defecto: el pabellón). Sale en `app/build/app/outputs/flutter-apk/app-release.apk` (unos 59 MB, las 3 ABIs); el script del paquete la copia como `brackety.apk`.
- Firma: aún con la clave debug (ver `pendientes.md`).
- Instalar: copiar el `.apk` al móvil y abrirlo (permitir "Instalar apps desconocidas" a la app que lo abre), o `adb install -r brackety.apk` con depuración USB.

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

## Pantallas
- Club: menú Exportar (icono de descarga, solo web como los CSV) con los 3 CSV y "Exportar paquete del evento"; el fichero se llama como dice el servidor.
- Login (app, solo Android): línea "Servidor: <nombre>" con la URL y "Cambiar" (diálogo con las 3 opciones y el campo de URL). La pantalla Conexión muestra el elegido.

## Offline
Ver `offline.md` (adelanto F1: marcador del árbitro).

## Tests
Web servida por la API (`WebAppConfigTest`, `WebAppDisabledTest`): fichero, `index.html` para rutas de la app, API sin cambios; apagada por defecto. `X-Forwarded-For` por Tomcat real (`ForwardedForIgnoredTest`, `ForwardedForBehindProxyTest`): con `none` no cambia la IP del limitador ni del bloqueo; con `native` sí. `same-origin` en `api_config_test.dart`. Scripts: prueba a mano.
Paquete (`EventPackageServiceTest`, `EventPackageControllerTest`): ida y vuelta a BD vacía (ajustes, categorías por equipos, tapices con y sin árbitro, staff, inscritos con categoría elegida); rechazo con BD usada, versión desconocida y contenido inválido sin escribir nada; cuentas creadas con contraseña aleatoria (alfabeto y longitud) que entran con ella y no con el usuario, cuenta existente reutilizada sin listarla; cargador de arranque con el fichero de contraseñas y sin él; permisos (club 200, ayudante y árbitro 403, ajeno 404, sin token 401) y cabeceras. App: menú con el paquete en 3 tamaños (endpoint y nombre). Scripts: prueba a mano. Selector de servidor (`test/features/server/`): diálogo en 3 tamaños (URL inválida, aviso de http, guardar), opción conocida y cancelar, Conexión con el elegido, web sin selector; unit de validación de URL, elección por defecto (build, guardado, web) y descarte de tokens al cambiar. Red de Android y APK: prueba a mano.

## Plan (PRs en serie)
1. Servidor portable (`start-event.ps1`, BD persistente, web servida por la API, firewall, copia).
2. Paquete del evento (exportar y cargar al arrancar).
3. APK: selector de servidor, http solo al pabellón, build de release y cómo instalarla.
4. Ensayo: portátil como punto de acceso sin Internet, 3 móviles, un combate completo.

## Estado
En curso: pasos 1-3 hechos (2026-11-05). Paso 3: APK release generada; falta probarla en móviles reales con el punto de acceso (paso 4).
Pasos 1-2 (2026-11-04). Probado en el PC de desarrollo (arranque, web, login, datos tras reiniciar, copia al parar con Ctrl+C y con `-Backup`) sin punto de acceso ni UAC: falta probarlos en el portátil del evento.
Paso 2 probado a mano con la carpeta generada: paquete exportado de `yoseikan-f1` (75 inscritos, 5 tapices) → `-Package` en carpeta vacía (evento, inscritos, tapices con árbitro, `arbitro1` entra), reinicio sin recarga, `-Package` y `-Reset` rechazados con datos o en marcha, paquete inválido rechazado con su motivo, `-Demo`, `-Reset` archiva.
