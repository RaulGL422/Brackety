# Pendientes

## Entorno de desarrollo (Raul)
- [ ] Autorizar la depuración USB en el móvil conectado (aparece como "not authorized").
- [ ] Docker Desktop: solo hará falta para probar `deploy/` en Windows; tests y ejecución local no lo necesitan.

## Por probar a mano (Raul, PR fusionadas del 2026-11-16/17)
- [ ] #104 comodín: elegir primero un comodín y luego uno normal en un grupo de equipos; cada uno queda con su papel.
- [ ] #105 inhabilitar tapiz: inhabilitar y habilitar desde Tapices (club) y desde el admin; el tapiz no recibe grupos mientras está inhabilitado.
- [ ] #107 M1 reglas en la modalidad: en Ajustes cambiar duración, límite y descanso; el marcador y la previsión los usan.
- [ ] #108 CSV por categoría: pestaña de liga, «Un CSV por categoría (.zip)», abrir uno con Excel.
- [ ] #109 M2a alumno único: corregir un apellido en una fase y verlo en la otra; cambiar el nacimiento de alguien ya agrupado da error.
- [ ] #109 antes de desplegar en la Pi: `select person_id from participant group by person_id having count(distinct birth_date) > 1;` debe salir vacío.
- [ ] Datos de la F1 a producción: seguir `09-despliegue.md` («Datos de la F1 a producción») cuando estén SSD, backups y Cloudflare; elegir el email de la cuenta de la entidad.
- [ ] #110 PDF: «Clasificación en PDF» en la pestaña de liga, imprimir una hoja.
- [ ] #111 M2b club único: renombrar un club en la F2 y verlo en la F1.
- [ ] #112 M2c sexo y peso: editar a alguien de la F1 (pide el sexo); importar una lista con y sin columna de sexo; peso con coma.
- [ ] #113 F2-1: peso obligatorio en Ajustes de una fase, intentar agrupar a alguien sin peso y apuntarlo desde crear grupos.
- [ ] #114 F2-2: categoría con varias edades; crear grupos las separa y el panel muestra la edad.
- [ ] #115/#117 debug: con el debug desplegado, cargar `yoseikan-f1` en una fecha simulada, ver la franja en app y admin, guardar una copia, cambiar algo, restaurarla y volver a hoy.
- [ ] Despliegue de debug: `./deploy.sh debug`, abrir los tres hostnames (piden Access), `./deploy.sh debug-stop` y comprobar que producción sigue.

## Despliegue (infra-deploy)
- [ ] Copia de los backups en la nube (doc 05): elegir proveedor barato; se añadiría con `rclone` al final de `backup.sh`.
- [ ] Generar la clave age de backups y guardar la privada fuera de la Pi (`09-despliegue.md`).
- [ ] Backup en Windows si llega a ser el servidor (hoy `backup.sh` es solo Linux).
- [ ] Cabecera Content-Security-Policy en nginx: probarla contra el despliegue real antes de activarla.

## Auth
- [ ] Organizadores creados antes del registro con CIF (p. ej. `club1` demo de un despliegue anterior) quedan sin nombre ni CIF: el superadmin los ve vacíos. Pedírselos a mano o completar desde ajustes cuando exista.
- [ ] Organizadores sin CIF español (entidades extranjeras, autónomos con NIF): hoy no pueden registrarse como organizador. Decidir si se admite NIF/NIE o un identificador extranjero.
- [ ] Google Cloud: crear OAuth client IDs (web + Android con SHA-1 de debug y release), ponerlos en `GOOGLE_CLIENT_ID` y probar el login real de Google en web y en Android (en local solo hay Google simulado).
- [ ] Resend: API key y remitente verificado en `rgal.dev` antes de `feat/auth-email` (en local los emails van al log).
- [ ] Cloudflare: regla de rate limiting sobre `/api/v1/auth/*` al desplegar.
- [ ] Debug en la Pi (`09-despliegue.md`, «Debug en la misma Pi»): segundo túnel con los hostnames de debug, Access para los tres, variables `DEBUG_API_BASE_URL` y `DEBUG_ADMIN_API_BASE_URL` en GitHub (sin ellas falla la publicación de `development`) y `.env.debug`.
- [ ] Producción: leer la IP real de `CF-Connecting-IP` y confiar solo en el túnel; comprobar en el despliegue real.
- [ ] Emails de auth: pasar el envío directo (tras commit, sin reintentos) a la cola con reintentos del módulo `notificaciones`.
- [ ] Register/forgot: queda una pequeña diferencia de tiempo de BD según exista la cuenta (enumeración por temporización, medible con muchas muestras). Aceptado por ahora; si hiciera falta, mover esas escrituras al hilo asíncrono.
- [ ] Más adelante: 2FA (TOTP), lista de sesiones activas con "cerrar en todos", contraseñas contra filtraciones (HaveIBeenPwned).
- [ ] Aviso "tu email ha cambiado" al email antiguo: sin canal de soporte no hay forma de recuperar la cuenta si el cambio lo hizo un atacante (salvo Google vinculado). Definir con `PRIVACY_CONTACT_EMAIL`/soporte.
- [ ] Exportación sin el `sub` de Google (es dato personal, pero es un identificador interno de Google): confirmarlo en la revisión legal.
- [ ] Quitar un perfil lo borra (no `deleted_at`): revisar cuando eventos o inscripciones referencien perfiles.
- [ ] Dueño de eventos: `DELETE /me` da 409 `OWNS_EVENTS`, pero aún no hay forma de ceder ni borrar un evento (módulo `eventos`). Hasta entonces ese organizador no puede borrar su cuenta.
- [ ] Registro con el email de una cuenta borrada hace más de 30 días y aún sin purgar (hasta 1 día): el aviso dice que puede cancelar el borrado, ya no es cierto. ¿Callar o mensaje distinto?
- [ ] Errores de la API sin texto en `i18n/messages*.properties` (la app traduce por `code`); `OWNS_EVENTS` sigue ese patrón. Confirmar si se quieren textos en servidor.
- [ ] Login con Apple cuando haya cuenta Apple Developer o app iOS.
- [ ] Login con Google en la app (botón + `REGISTRATION_REQUIRED`) cuando existan los client IDs.

## Tras la Fase 1 (2026-11-16; plan en `producto/roadmap.md`)
- [ ] Competición del 2026-12-20: modalidades y su puntuación, categorías, tapices y servidor; la clasificación ya está (`producto/competicion-2026-12-20.md`).
- [ ] F1-2 comodín: arreglado en la app (2026-11-16); falta revisar en la Pi qué se apañó a mano y que la clasificación sea correcta.
- [ ] F2-3 CSV de resultados: la entidad de la liga ve confusos los puestos (1.º, 2.º, 3.º) al abrirlos en Excel. Hecho: CSV por categoría (#108) y PDF (#110). Falta rehacer el resto de CSV (Raul aún no lo ha revisado).
- [ ] F2-4: global opcional hecha (`modulos/ranking.md`). Dividir una categoría por sexo o tramos de peso: cuando una modalidad lo necesite (en la F2 la categoría es solo por edad; Raul, 2026-11-17).
- [ ] F1-4 advertencias: revisar la lista de tambo propuesta (prohibiciones del reglamento, cap. 3.1: proyección o golpeo, tirarse rodando, ataque de pique, exceso de potencia, conducta antideportiva). Se cambia en `Discipline` o por evento en Configuración.
- [ ] F1-5 cuentas propias: hecho en `feat/f1-5-staff-invites`. Con Resend en producción, probar a mano: invitar a un email real, registrarse con él, aceptar y arbitrar un tapiz. Retirar `staffNames` cuando las cuentas tengan nombre.
- [ ] F1-7: probar a mano en debug la PR B (fusionada, #129): comenzar, crear grupos, finalizar con pendientes, reabrir con motivo y el correo del día siguiente. PR C (permisos, rama `feat/event-staff-permissions`): dar y quitar permisos en «Personal» y comprobar que el ayudante ve o pierde sus botones.
- [ ] F1-7 C2 (rama `feat/staff-panel-access`): probar a mano en debug un ayudante solo de mirar, otro solo de alumnos y un árbitro que además hace grupos.
- [ ] F1-7 C permisos en el portátil (rama `feat/package-staff-permissions`): probar a mano exportar con un ayudante en un tapiz, cargarlo en el portátil y entrar con él.
- [ ] Correo como herramienta (Raul, 2026-11-18): Raul elige de la lista propuesta en `modulos/notificaciones.md` (sección «Propuesta a Raul»), y si vale la propuesta para enviar resultados.
- [ ] Nombres descriptivos en las descargas (rama `feat/descriptive-download-names`): probar a mano que cada descarga del panel lleva liga, fase y qué es (`modulos/ranking.md`).
- [ ] Compartir resultados por correo (Raul, 2026-11-18): enviar la clasificación o los resultados (PDF/CSV) a una o varias direcciones que escribe el club, desde el panel. Ojo: llevan datos de menores (`06-legal-rgpd.md`); decidir qué se puede enviar y a quién.
- [ ] Gestión del club (`producto/gestion-club.md`): ¿se amplía el alcance? Cambia `00-vision.md` (hoy cobros fuera de alcance).
- [ ] Si se cobra o se factura: forma jurídica, asesor fiscal y contratos con los clubes.

## Prototipo Fase 1 (bloquean el uso real)
- [ ] Raul · Cloudflare para dejarlo todo listo (sin configurar el 2026-11-05). Pasos en `09-despliegue.md` (paso 8); `.env` de la Pi en `prototipo-f1.md` (Despliegue):
  - Un túnel en la Pi (Zero Trust → Networks → Tunnels, tipo Cloudflared); su token en `CLOUDFLARE_TUNNEL_TOKEN`.
  - Hostname `brackety.rgal.dev` → `http://web:80` (web pública).
  - Hostname `brackety-api.rgal.dev` → `http://api:8080` (API; la opción "Internet" de la APK apunta aquí y no funciona hasta entonces).
  - Hostname `brackety-admin.rgal.dev` → `http://admin:80`, solo junto con su aplicación de Access (`CF_ACCESS_TEAM_DOMAIN`, `CF_ACCESS_AUD`). No hace falta para la F1.
  - Relacionado: rate limiting de `/api/v1/auth/*` (Auth) y Email Routing de `privacidad@rgal.dev` (abajo).
  - Comprobar desde datos móviles la web y `https://brackety-api.rgal.dev/actuator/health`.
  - El pabellón no depende del túnel: va con el portátil (`modulos/servidor-local.md`).
- [ ] Categorías reales de la Fase 1 (ahora ficticias: tramos del ranking, mixtas).
- [ ] Tras la fase: desactivar `DEMO_ACCOUNTS_ENABLED` y borrar las cuentas demo.
- [ ] Wifi del pabellón: el punto de acceso de Windows no se activa sin Internet (probado por Raul el 2026-11-04) y la tarjeta AX200 no admite red hospedada. El bucle invertido no se deja elegir y el iPhone por USB no lo reconoce Windows (fallo de cable). Decidido por Raul: el portátil se conecta por wifi al punto de acceso del iPhone (cargando por cable) y lo comparte con el suyo (`192.168.137.1`). Probado el 2026-11-04: un móvil en el punto de acceso llega a la API en `192.168.137.1:8080` y sigue llegando con el iPhone sin datos. Quedan: el ahorro de energía del punto de acceso (lo apaga sin clientes) y el límite de 8 dispositivos.
- [ ] Carpeta del pabellón (`servidor-local.md`), sin probar aún: encender el punto de acceso desde `start-event.ps1`, el aviso de UAC del firewall y arrancar en un portátil limpio (sin Java ni Visual C++ instalados).
- [ ] Reglas "java" del firewall creadas al probar la carpeta en el portátil de Raul (aviso de Windows): mantener o borrar.
- [ ] Raul: crear `privacidad@rgal.dev` (p. ej. reenvío de Cloudflare Email Routing a su Gmail).
- [ ] Portátil del pabellón: ¿BitLocker activo? Confirmar el borrado de `brackety-data/` y del paquete tras la fase (`servidor-local.md`).
- [ ] Móviles de árbitros y ayudantes: ¿todos Android y con permiso para instalar la APK? Si hay iPhone, ese usa la web (sin offline).

- [ ] Revisión del 2026-11-06 (`revision-f1.md`): lo que quede abierto tras la fase pasa aquí.
- [ ] Refresh idempotente (`SessionService`): la caché vive en memoria y supone una sola instancia de la API (vale para el portátil y la Pi).
- [ ] `docs/decisiones.md` está en 150 líneas: dividirlo antes de añadir más.

- [ ] Pruebas F1 del 2026-11-12: decisiones abiertas en `pruebas-f1.md` (sección Abierto), sobre todo categorías con 3 inscritos.
- [ ] Importación de alumnos: aceptar el DPA de Anthropic en su consola y confirmar el plazo de conservación de datos de la API (`modulos/importacion-alumnos.md`).

## Repositorio público
- [ ] `docs/` es planificación temporal y se eliminará en el futuro. Antes de hacerlo: pasar a `CLAUDE.md` (o un README) lo imprescindible que hoy solo vive en `docs/` y quitar sus enlaces.

## Bloquean el lanzamiento público
- [ ] Firma release de Android (keystore propio en secretos de CI); ahora `app/android/app/build.gradle.kts` firma release con la clave debug de la plantilla.
- [ ] Email de privacidad (`PRIVACY_CONTACT_EMAIL`, p. ej. `privacidad@rgal.dev`). Sin él, la API no deja publicar ni pasar de fase.
- [ ] SSD USB/NVMe para la base de datos (la SD no es fiable). La F1 va en la SD (Raul, 2026-11-10): después, copia, `DB_DATA` al SSD y restaurar.
- [ ] Backups cifrados + prueba de restauración.
- [ ] Revisión legal profesional de privacidad, términos y cookies.
- [ ] Google Play: 12 testers × 14 días en pruebas cerradas (Raul tiene las personas).
- [ ] Marca: comprobar "Brackety" en OEPM y dominio `brackety.rgal.dev` (existe una app llamada Brackify, parecida).

## Reglamento Yoseikan (ver `reglamentos/yoseikan-2027.md`)
- [ ] Tiempo de ronda de lucha en suelo (Raul consultando).
- [ ] Escala de puntuación de cada prueba de Expresión Técnica (kata, derribos al muñeco, saco, arco).
- [ ] Puntos de asistencia por fase: 10 por ahora, candidato a cambio.
- [ ] Reglas de amonestación del tambo por categoría: fijarlas por modalidad/fase/categoría.
- [ ] Recopilar el reglamento completo en PDF para consulta cerca del marcador.
- [ ] Confirmar orden de fases: deducido del Registro general (F1 suelo, F2 armas, F3 expresión técnica, F4 derribos).

## Diseño tras la Fase 1 (revisión con Playwright, 2026-11-07)
- [ ] Escritorio: Configuración, Puntuaciones y Tapices ocupan todo el ancho; aplicar anchos de formulario (480) y lectura (720) de `07-diseno.md` (el tablero del árbitro ya lo hace).
- [ ] Escritorio con más información por pantalla (maquetas del canvas, 2026-11-09; después de la F1): mesa del club con pestañas arriba y totales, tabla de tapices (combate en curso con marcador, siguiente, grupo con avance, árbitro, hora de fin), "Pendiente de ti", avance por categoría y últimos resultados; crear grupo con tabla de alumnos y huecos con edad y estatura. Raul quiere la **previsión del día** por tapiz (jugado, en curso, por jugar): necesita en el servidor la duración media de los combates por categoría y la hora estimada de fin de cada grupo.
- [ ] Sistema neutro en el resto de pantallas: maquetas antes de programar (inicio, login, mesa del club como planta de tapices, inscripciones, ajustes, admin). Quitar los textos con punto medio ("6 años · 132 cm") en favor de columnas con etiqueta.
- [ ] Web sin conexión (offline), después de la F1, en dos pasos. 1) Con la pestaña abierta: cola del marcador guardada en el navegador y enviada al volver la red (vale en http y https). 2) Completa por https (`brackety.rgal.dev`): la app se guarda en el navegador y abre sin red. En http (pabellón) el navegador no permite el paso 2. Útil sobre todo para iPhone. Aprobado por Raul el 2026-11-08.
- [ ] "Tapiz" fijo en los textos: en otros deportes será Pista, Campo… Debe salir del nombre de la ubicación del evento (módulo `eventos`).
- [ ] Lector de pantalla: la lista de Puntuaciones se lee como un único bloque; una fila por alumno.

## Producto
- [ ] Grupo con sobrante: opciones (promedio por combate / puntos brutos / decidir caso a caso) y respuesta final del organizador; será opción del evento.
- [ ] Modelo exacto de equipos en torneos por equipos (plantilla, suplentes, entrenadores).
- [ ] Prototipo por equipos: categorías reales (cuáles van por equipos y edades), tamaños reales de equipo/grupo y si hay ranking de equipos además del de alumnos (`prototipo-f1-equipos.md`).
- [ ] Plantillas de deporte adicionales (judo, karate, taekwondo, fútbol…): investigar al llegar a `puntuacion`.
- [ ] Doble eliminación y repesca (judo, taekwondo, karate): investigar al llegar a `torneo`.
- [ ] Registro de tratamientos y plantilla de registro de brechas.

## Hecho
- 2026-10-30 · Tokens de acceso y reauth emitidos antes de un cambio de credenciales o borrado se rechazan (`sessions_revoked_at`).
- 2026-10-30 · Cuenta en borrado lógico: durante 30 días el dueño la reactiva al iniciar sesión (`ACCOUNT_PENDING_DELETION` + restaurar); registrarse con ese email avisa al dueño y no crea otra.
- 2026-11-08 · Dirección de diseño Tatami (claro y oscuro) aceptada por Raul; sustituye a Eléctrico y Barlow.
- 2026-11-08 · Tatami sustituido por el sistema neutro multideporte con Atkinson Hyperlegible Next (Raul).
- 2026-11-08 · Modo claro u oscuro fijable en Ajustes (Automático, Claro, Oscuro), guardado en el dispositivo.
- 2026-10-30 · Sistema de diseño validado: paleta Eléctrico y Barlow.
- 2026-10-28 · Android cmdline-tools instaladas; `flutter doctor` sin errores para Android y web.
- 2026-10-28 · Graphify configurado a partir de ClipHive (`CLAUDE.md`, `.gitignore`).
- 2026-11-09 · Marcador web: `knownEvents` obligatorio; dos pestañas a la vez ya no suman dos (409 `MATCH_STALE`).
- 2026-11-10 · Pi desplegada con la v0.3.0 (`brackety.rgal.dev`); GHCR privado con token `read:packages` y clave de despliegue.
