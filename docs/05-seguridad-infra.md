# 05 · Seguridad e infraestructura

## Variables de entorno
- Se suben a una web de gestión de secretos; en local, `.env` (ignorado por Git). Siempre `deploy/.env.example` actualizado, sin valores reales.
- Variables mínimas: `DB_URL, DB_USER, DB_PASSWORD, JWT_SECRET` (obligatoria, ≥32 bytes), `GOOGLE_CLIENT_ID` (client IDs de OAuth separados por comas, web y Android; vacía = login con Google responde 503), `APPLE_CLIENT_ID, RESEND_API_KEY` (vacía = emails solo al log), `EMAIL_FROM` (remitente; obligatoria con API key), `FCM_CREDENTIALS, SUPERADMIN_EMAIL, SUPERADMIN_PASSWORD_HASH` (vacías = login de superadmin 503), `CF_ACCESS_TEAM_DOMAIN, CF_ACCESS_AUD` (Cloudflare Access de admin; vacías = `/api/v1/admin/**` responde 503), `PRIVACY_CONTACT_EMAIL, PUBLIC_BASE_URL` (web pública, base de los enlaces de los emails; obligatoria con API key), `CORS_ALLOWED_ORIGINS` (patrones de origen separados por comas; vacío = sin CORS; sin comodines de host). `ANTHROPIC_API_KEY` (importación de alumnos con `claude -p`; clave de API, nunca el token de suscripción; vacía = sin botón de importar). Opcionales: `BRACKETY_IMPORT_MODEL` (modelo de la importación, `claude-sonnet-5-5` por defecto), `RATE_LIMIT_PER_MINUTE`, `RATE_LIMIT_AUTH_PER_MINUTE`, `RATE_LIMIT_REFRESH_PER_MINUTE`, `ACCESS_TTL` (vida del token de acceso, `15m` por defecto; `12h` en el portátil del pabellón).
- Solo de despliegue (`deploy/.env`): `CLOUDFLARE_TUNNEL_TOKEN`, `API_BASE_URL` (URL pública de la API que se graba en web al construir), `ADMIN_API_BASE_URL` (URL del host de admin que se graba en admin; vacía = `API_BASE_URL`), `IMAGE_TAG`, `DB_DATA` (volumen o ruta del SSD), `API_PORT`, `WEB_PORT`, `ADMIN_PORT`, `BACKUP_DIR`, `BACKUP_AGE_RECIPIENT` (clave pública age; la privada nunca en el servidor).
- Sin `PRIVACY_CONTACT_EMAIL` la API no permite publicar eventos ni pasar de fase.

## Superadmin
Un único usuario definido por entorno + Cloudflare Access (login con cuenta Cloudflare de Raul). Nunca expuesto sin Access: la API también verifica el JWT de Access en `/api/v1/admin/**` (`modulos/auth.md`). Registro de auditoría de cada acción (`admin_audit`).

## Red
Todo el tráfico entra por Cloudflare Tunnel. Sin puertos abiertos en el router. `db` y `api` sin puertos publicados al host salvo localhost en desarrollo. TLS lo gestiona Cloudflare.

## Aplicación
- JWT corto (15 min) + refresh rotatorio; revocación al cambiar contraseña o borrar cuenta.
- Límites de tasa en login, invitaciones y escritura de marcador.
- Contraseñas con Argon2/bcrypt. Login Google/Apple verificando tokens en servidor.
- CORS restringido a los dominios propios. Cabeceras de seguridad en nginx.
- Validación y autorización siempre en servidor.

## Backups y hardware (requisito de lanzamiento, no de desarrollo)
- Postgres sobre tarjeta SD se corrompe: usar SSD USB/NVMe antes de abrir al público.
- `pg_dump` diario cifrado (age/gpg) a disco externo + nube barata; retención 14 diarios + 8 semanales.
- Probar restauración antes del lanzamiento y cada trimestre.

## Despliegue
`deploy/deploy.sh` en la Pi: `docker compose pull && up -d`, comprobación de salud, rollback a la imagen anterior si falla. Perfil `windows` equivalente.

## Brechas
Procedimiento en `06-legal-rgpd.md` (aviso a la AEPD en 72 h).
