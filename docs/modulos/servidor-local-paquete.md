# servidor-local · paquete del evento y dispositivos

Parte de `servidor-local.md`, que sigue siendo el doc del módulo.

## Paquete del evento
- Desde 2026-11-11 el club exporta "Todo el evento (.zip)": CSV legibles en Excel (`;`, BOM, cabeceras en español, fechas dd/mm/aaaa, nombres en vez de ids), `evento.brackety` (esquema 2: liga, fase, organizaciones, ids de persona y resultados) y `LEEME.txt`. `-Package` acepta el `.zip` o el `.brackety`. Del `.zip` solo se carga `evento.brackety`: los CSV son para leer, editarlos no cambia lo que se carga. Para otros inscritos se cambian en la Pi (o con la importación de alumnos) y se exporta de nuevo (2026-11-13).
- Vuelta a la Pi: en el panel del club, "Importar resultados del pabellón" con el `.zip` del portátil. Primero cuenta (prueba en seco) y pide confirmación; luego trae grupos, equipos, combates y línea de tiempo. Idempotente (repetir no cambia nada); 409 si es de otro evento o si el de la Pi ya tiene grupos propios.
- Fichero `.brackety`, JSON UTF-8 con `schemaVersion: 3` (se leen del 1 al 3; la 3 quita el multigrupo, que en las anteriores se ignora), `exportedAt`, `event` (nombre, fecha, duración, límite de puntos, descanso entre combates, puntos por asistir), `owner` (usuario, organización y CIF), `staff` (usuario y rol, incluido el club), `categories` (nombre, edades, formato, tamaño de equipo), `mats` (número y usuario del árbitro o null), `staffNames` (opcional: usuario y nombre de la persona), `staffPermissions` (opcional: usuario y permisos elegidos en «Personal»; quien no está, los de su rol) y `participants` (nombre, apellidos, nacimiento, estatura, consentimiento del tutor, categoría elegida o null).
- Sin ids, grupos, equipos, combates, importaciones, contraseñas ni más datos de cuentas que los usuarios del staff.
- Lo exporta el club del evento en cualquier momento (también con grupos, que no viajan).
- `start-event.ps1 -Package f1.brackety` en una carpeta sin datos: lo copia a `brackety-data/` y la API lo carga al arrancar, antes de abrir el puerto, en una transacción (todo o nada).
- Rechazos (la API no arranca y el script muestra el motivo, con campo e índice de fila, sin datos personales): BD con algún evento, `schemaVersion` desconocida, JSON inválido, categoría inexistente o repetida, tapices que no van de 1 a N, árbitro sin permiso «Arbitrar su tapiz» (`OWN_MAT`, elegido o por su rol), del club o en dos tapices, permisos de alguien que no es ayudante ni árbitro o repetidos, dueño que no es CLUB del staff, menor sin consentimiento, CIF inválido, límites de campos.
- Cuentas del staff que falten: verificadas, `es`, contraseña aleatoria de 10 caracteres (minúsculas y dígitos sin `l`, `1`, `o`, `0`; `SecureRandom`); el dueño con perfil Club, organización y CIF del paquete; el resto Ayudante. Las existentes se reutilizan sin cambiar su contraseña.
- Las contraseñas nuevas van a `BRACKETY_PACKAGE_CREDENTIALS` (`brackety.package-credentials`, obligatoria con paquete), nunca al log: `usuario;rol;contraseña;tapices` (roles y tapices separados por comas). El script usa `brackety-data/credentials.txt` y lo muestra al acabar el primer arranque, con aviso de repartirlas a mano y borrarlo tras la fase. `-Demo` sigue con usuario = contraseña. Con `-UsernamePasswords` (`BRACKETY_PACKAGE_USERNAME_PASSWORDS`) las cuentas que crea el paquete también (riesgo aceptado por Raul para la F1, 2026-11-13).
- Reinicio (F1): el script pasa `BRACKETY_RESET_PACKAGE` (el paquete guardado en `brackety-data`). El superadmin, en Eventos, "Reiniciar el evento desde el paquete" (motivo + escribir REINICIAR): `truncate event, league cascade` y se vuelve a cargar, todo en una transacción. Cuentas, contraseñas y auditoría se quedan. Sin paquete no aparece el botón.
- Con paquete, `DemoSetup` no crea su evento (y nunca si ya hay alguno); el script apaga las cuentas demo.
- Tras arrancar, el evento está listo: el club ve sus inscritos y los ayudantes ya pueden crear grupos.
- El fichero lleva datos de menores: se guarda solo en el portátil del evento y se borra después (ver Legal).

## Dispositivos
- Árbitros y ayudantes usan la **web** del portátil (desde 2026-11-11 la web tiene la misma cola offline, ver `offline.md`). La APK queda como opción.
- La APK elige el servidor en el login: "Pabellón" (`http://192.168.137.1:8080`), "Internet" (`https://brackety-api.rgal.dev`) o "Otra URL" (http/https con host). Se recuerda en el dispositivo (almacén seguro, junto al refresh token).
- Por defecto, el `API_BASE_URL` del build. Solo en el login: cambiarlo cierra la sesión guardada (sus tokens son del otro servidor) y las peticiones siguientes van al nuevo sin reiniciar. La web no lo muestra.
- http sin cifrar solo hacia la IP del pabellón (`network_security_config.xml`); el resto, https. "Otra URL" con http a otra IP avisa de que no conectará. Los builds debug permiten http a cualquier IP (desarrollo local).
- El club puede usar el navegador del propio portátil (`http://localhost:8080`).

## APK (build e instalación)
- `cd app; flutter build apk --release --dart-define-from-file=env/apk-event.json` (servidor por defecto: el pabellón). Sale en `app/build/app/outputs/flutter-apk/app-release.apk` (unos 59 MB, las 3 ABIs); el script del paquete la copia como `brackety.apk`.
- Firma: aún con la clave debug (ver `pendientes.md`).
- Instalar: copiar el `.apk` al móvil y abrirlo (permitir "Instalar apps desconocidas" a la app que lo abre), o `adb install -r brackety.apk` con depuración USB.
