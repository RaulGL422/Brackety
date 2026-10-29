# 05 · Seguridad e infraestructura

## Variables de entorno
- Se suben a una web de gestión de secretos; en local, `.env` (ignorado por Git). Siempre `deploy/.env.example` actualizado, sin valores reales.
- Variables mínimas: `DB_URL, DB_USER, DB_PASSWORD, JWT_SECRET, GOOGLE_CLIENT_ID, APPLE_CLIENT_ID, RESEND_API_KEY, FCM_CREDENTIALS, SUPERADMIN_EMAIL, SUPERADMIN_PASSWORD_HASH, PRIVACY_CONTACT_EMAIL, PUBLIC_BASE_URL, CORS_ALLOWED_ORIGINS` (patrones de origen separados por comas; vacío = sin CORS).
- Solo de despliegue (`deploy/.env`): `CLOUDFLARE_TUNNEL_TOKEN`, `API_BASE_URL` (URL pública de la API que se graba en web y admin al construir), `IMAGE_TAG`, `DB_DATA` (volumen o ruta del SSD), `API_PORT`, `WEB_PORT`, `ADMIN_PORT`, `BACKUP_DIR`, `BACKUP_AGE_RECIPIENT` (clave pública age; la privada nunca en el servidor).
- Sin `PRIVACY_CONTACT_EMAIL` la API no permite publicar eventos ni pasar de fase.

## Superadmin
Un único usuario definido por entorno + Cloudflare Access (login con cuenta Cloudflare de Raul). Nunca expuesto sin Access. Registro de auditoría de cada acción destructiva.

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
