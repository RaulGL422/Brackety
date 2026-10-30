# Pendientes

## Entorno de desarrollo (Raul)
- [ ] Autorizar la depuración USB en el móvil conectado (aparece como "not authorized").
- [ ] Docker Desktop: solo hará falta para probar `deploy/` en Windows; tests y ejecución local no lo necesitan.

## Despliegue (infra-deploy)
- [ ] Variable de repositorio `API_BASE_URL` en GitHub (Settings → Variables) cuando haya dominio; sin ella fallan las imágenes web/admin al publicar.
- [ ] Paquetes GHCR: hacerlos públicos o `docker login ghcr.io` en la Pi con un token de solo lectura (decidir).
- [ ] Copia de los backups en la nube (doc 05): elegir proveedor barato; se añadiría con `rclone` al final de `backup.sh`.
- [ ] Generar la clave age de backups y guardar la privada fuera de la Pi (`09-despliegue.md`).
- [ ] Backup en Windows si llega a ser el servidor (hoy `backup.sh` es solo Linux).
- [ ] Cabecera Content-Security-Policy en nginx: probarla contra el despliegue real antes de activarla.

## Auth
- [ ] Google Cloud: crear OAuth client IDs (web + Android con SHA-1 de debug y release), ponerlos en `GOOGLE_CLIENT_ID` y probar el login real de Google en web y en Android (en local solo hay Google simulado).
- [ ] Resend: API key y remitente verificado en `rgal.dev` antes de `feat/auth-email` (en local los emails van al log).
- [ ] Cloudflare: regla de rate limiting sobre `/api/v1/auth/*` al desplegar.
- [ ] Producción: leer la IP real de `CF-Connecting-IP` y confiar solo en el túnel; comprobar en el despliegue real.
- [ ] Validar en servidor las versiones de términos y privacidad aceptadas (depende de `legal-paginas`).
- [ ] Emails de auth: pasar el envío directo (tras commit, sin reintentos) a la cola con reintentos del módulo `notificaciones`.
- [ ] Register/forgot: queda una pequeña diferencia de tiempo de BD según exista la cuenta (enumeración por temporización, medible con muchas muestras). Aceptado por ahora; si hiciera falta, mover esas escrituras al hilo asíncrono.
- [ ] Más adelante: 2FA (TOTP), lista de sesiones activas con "cerrar en todos", contraseñas contra filtraciones (HaveIBeenPwned).
- [ ] Una cuenta en borrado lógico bloquea registrarse con ese email (Google y contraseña) hasta el borrado definitivo a los 30 días. Decidir en `feat/auth-me` si se permite reactivarla.
- [ ] Login con Apple cuando haya cuenta Apple Developer o app iOS.

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

## Producto
- [ ] Grupo con sobrante: opciones (promedio por combate / puntos brutos / decidir caso a caso) y respuesta final del organizador; será opción del evento.
- [ ] Modelo exacto de equipos en torneos por equipos (plantilla, suplentes, entrenadores).
- [ ] Plantillas de deporte adicionales (judo, karate, taekwondo, fútbol…): investigar al llegar a `puntuacion`.
- [ ] Doble eliminación y repesca (judo, taekwondo, karate): investigar al llegar a `torneo`.
- [ ] Registro de tratamientos y plantilla de registro de brechas.

## Hecho
- 2026-10-30 · Sistema de diseño validado: paleta Eléctrico y Barlow.
- 2026-10-28 · Android cmdline-tools instaladas; `flutter doctor` sin errores para Android y web.
- 2026-10-28 · Graphify configurado a partir de ClipHive (`CLAUDE.md`, `.gitignore`).
