# Pendientes

## Entorno de desarrollo (Raul)
- [ ] Autorizar la depuración USB en el móvil conectado (aparece como "not authorized").
- [ ] Docker Desktop: solo hará falta para probar `deploy/` en Windows; tests y ejecución local no lo necesitan.

## Despliegue (infra-deploy)
- [ ] Paquetes GHCR: hacerlos públicos o `docker login ghcr.io` en la Pi con un token de solo lectura (decidir).
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
- [ ] Base de datos de la fase en la SD (sin SSD) con copia diaria: ¿se acepta el riesgo o se compra antes el SSD?
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

- [ ] Importación de alumnos: aceptar el DPA de Anthropic en su consola y confirmar el plazo de conservación de datos de la API (`modulos/importacion-alumnos.md`).

## Repositorio público
- [ ] `docs/` es planificación temporal y se eliminará en el futuro. Antes de hacerlo: pasar a `CLAUDE.md` (o un README) lo imprescindible que hoy solo vive en `docs/` y quitar sus enlaces.

## Bloquean el lanzamiento público
- [ ] Firma release de Android (keystore propio en secretos de CI); ahora `app/android/app/build.gradle.kts` firma release con la clave debug de la plantilla.
- [ ] Email de privacidad (`PRIVACY_CONTACT_EMAIL`, p. ej. `privacidad@rgal.dev`). Sin él, la API no deja publicar ni pasar de fase.
- [ ] SSD USB/NVMe para la base de datos (la SD no es fiable).
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
- [ ] Escritorio: Configuración, Puntuaciones y Tapices ocupan todo el ancho; aplicar anchos de formulario (480) y lectura (720) de `07-diseno.md`.
- [ ] Tarjeta "Siguiente recomendado": naranja lleno + círculo de grupo + punto rojo chocan; probar `tertiaryContainer` con borde de acento.
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
- 2026-10-30 · Sistema de diseño validado: paleta Eléctrico y Barlow.
- 2026-10-28 · Android cmdline-tools instaladas; `flutter doctor` sin errores para Android y web.
- 2026-10-28 · Graphify configurado a partir de ClipHive (`CLAUDE.md`, `.gitignore`).
