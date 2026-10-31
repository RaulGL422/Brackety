# 09 · Despliegue (Raspberry Pi y Windows)

Imágenes y compose: `modulos/infra-deploy.md`. Variables: `05-seguridad-infra.md`.

## Primer arranque en la Pi
1. **Sistema**: Raspberry Pi Imager → *Raspberry Pi OS Lite (64-bit)*. En la configuración avanzada: usuario, contraseña, wifi/ethernet y **SSH activado**.
2. **Actualizar**: `sudo apt update && sudo apt full-upgrade -y && sudo reboot`.
3. **SSD** (obligatorio antes de abrir al público; la SD se corrompe con Postgres):
   - `lsblk` para ver el disco; formatear una vez: `sudo mkfs.ext4 /dev/sda1`.
   - `sudo mkdir -p /mnt/ssd` y añadir a `/etc/fstab` por UUID (`sudo blkid`): `UUID=<uuid> /mnt/ssd ext4 defaults,noatime,nofail 0 2`.
   - `sudo mount -a` y `sudo mkdir -p /mnt/ssd/brackety/pgdata`.
4. **Docker** (script oficial): `curl -fsSL https://get.docker.com | sh` y `sudo usermod -aG docker $USER`; cerrar sesión y volver a entrar. Comprobar con `docker compose version`.
5. **Repo**: `git clone https://github.com/RaulGL422/Brackety.git ~/brackety`.
6. **Entorno**: `cd ~/brackety/deploy && cp .env.example .env && nano .env`.
   - Rellenar `DB_USER`, `DB_PASSWORD` (larga y aleatoria: `openssl rand -base64 32`), `CLOUDFLARE_TUNNEL_TOKEN`, `CORS_ALLOWED_ORIGINS`, `PRIVACY_CONTACT_EMAIL`…
   - `JWT_SECRET` obligatoria (≥32 bytes): `openssl rand -base64 48`. Sin ella la API no arranca y `deploy.sh` se niega a desplegar. Cambiarla cierra todas las sesiones.
   - Email: `RESEND_API_KEY` (Resend → API Keys), `EMAIL_FROM` (remitente de un dominio verificado en Resend, p. ej. `Brackety <no-reply@rgal.dev>`) y `PUBLIC_BASE_URL` (URL pública de la web, base de los enlaces). Sin API key los emails solo van al log de la API.
   - Google: `GOOGLE_CLIENT_ID` con los client IDs de OAuth (Google Cloud → APIs y servicios → Credenciales) de web y Android separados por comas. Vacía: el login con Google responde 503 y lo demás funciona.
   - Superadmin: `SUPERADMIN_EMAIL` y `SUPERADMIN_PASSWORD_HASH`. El hash, en tu PC: IntelliJ → run config `server · superadmin password hash`, escribe la contraseña (≥10) en la consola y copia la línea que imprime, **con comillas simples** (el hash lleva `$`). Cambiar la contraseña = nuevo hash y `./deploy.sh pi`. Si la contraseña se ha filtrado, rota también `JWT_SECRET`: el token de superadmin ya emitido sigue valiendo 1 h tras reiniciar (cambiarla cierra también todas las sesiones de usuario).
   - Cloudflare Access (tras el paso 8): `CF_ACCESS_TEAM_DOMAIN` = Zero Trust → Settings, *Team name and domain* (en paneles antiguos, Custom Pages) (`<equipo>.cloudflareaccess.com`); `CF_ACCESS_AUD` = Access → Applications → la de admin → *Overview*, *Application Audience (AUD) Tag*. Vacías: la API de superadmin responde 503.
   - `ADMIN_API_BASE_URL=https://admin.<dominio>`: la app admin llama a la API por su propio host (nginx reenvía `/api/` a la api), así pasa por Access. En CI, variable del repo `ADMIN_API_BASE_URL` (Settings → Variables); sin ella admin usa `API_BASE_URL` y el superadmin recibe 403.
   - `DB_DATA=/mnt/ssd/brackety/pgdata`.
   - `chmod 600 .env`: solo tu usuario puede leerlo.
7. **GHCR**: si los paquetes son privados, `docker login ghcr.io -u RaulGL422` con un token de solo lectura (`read:packages`).
8. **Túnel** (Cloudflare Zero Trust → Networks → Tunnels → *Create tunnel*, tipo Cloudflared):
   - Copiar el token a `CLOUDFLARE_TUNNEL_TOKEN`.
   - *Public hostnames*: `web` → `http://web:80`, `api` → `http://api:8080`, `admin` → `http://admin:80` (nombres de servicio del compose).
   - Access → Applications: proteger **solo** el hostname de `admin` (login con tu cuenta).
9. **Desplegar**: `./deploy.sh pi`. Termina con `Deploy OK` cuando api, web y admin están sanos.
10. **Comprobar**: `docker compose ps` (todo `healthy`) y abrir los tres hostnames desde fuera de casa.

Tras un reinicio todo vuelve solo: Docker arranca con el sistema y los servicios tienen `restart: unless-stopped`.

## Actualizar
- `cd ~/brackety && git pull && ./deploy/deploy.sh pi`.
- `git pull` trae los cambios de compose y scripts; las imágenes nuevas las descarga el script.
- Versión concreta: `IMAGE_TAG=1.2.0` en `.env`. `latest` = último `main`.

## Qué hace `deploy.sh` / `deploy.ps1`
1. Etiqueta como `rollback` las imágenes que están corriendo.
2. `docker compose pull` (si falla, no cambia nada).
3. `up -d --wait`: espera a los healthchecks (máx. 5 min).
4. Si fallan, vuelve a las imágenes `rollback` y termina con error.
- El rollback **no deshace migraciones** de base de datos: hacer backup antes de desplegar una versión con migraciones (tarea 6).
- `local` usa imágenes construidas en la máquina, sin pull ni túnel (`docker compose build && ./deploy.sh local`). Es lo que prueba el CI, rollback incluido.

## Backups
`deploy/backup.sh`: `pg_dump` cifrado con [age](https://github.com/FiloSottile/age), 14 diarios + 8 semanales (domingo).
1. **Clave** (en tu PC, una vez): `winget install FiloSottile.age` y `age-keygen -o brackety-backup.key`.
   - El archivo es la clave **privada**: guárdala en el gestor de contraseñas y en un USB. Nunca en la Pi ni en git.
   - La línea `# public key: age1…` va a `BACKUP_AGE_RECIPIENT` en `.env`.
2. **Disco de backups** distinto del SSD de la base de datos: montarlo como el SSD (fstab por UUID, `nofail`) en `/mnt/backup` y poner `BACKUP_DIR=/mnt/backup/brackety`.
3. **En la Pi**: `sudo apt install -y age` y probar a mano: `~/brackety/deploy/backup.sh`.
4. **Cron** (`crontab -e`): `30 3 * * * $HOME/brackety/deploy/backup.sh >> $HOME/brackety-backup.log 2>&1`.
- Antes de desplegar una versión con migraciones: lanzar `backup.sh` a mano.

## Restaurar (probar antes del lanzamiento y cada trimestre)
- **Prueba** (no toca producción): `./restore.sh /mnt/backup/brackety/daily/<archivo>.dump.age /media/usb/brackety-backup.key` restaura en la base `restore_check`. Revisar datos y borrarla con el comando que muestra el script.
- **Recuperación real**: añadir `brackety` como tercer argumento. Restaura primero en `brackety_restore`; solo si sale bien pide confirmación, para la api, cambia las bases y arranca la api. La anterior queda como `brackety_old_<fecha>`: borrarla cuando todo funcione.
- Tras usar la clave privada en la Pi, retirar el USB.

## Windows (servidor alternativo)
1. Docker Desktop con backend WSL 2, que arranque al iniciar sesión.
2. Clonar el repo, `deploy\.env` desde `.env.example` (en `DB_DATA` dejar `pgdata` o una ruta tipo `D:/brackety/pgdata`).
3. `.\deploy\deploy.ps1` (perfil `windows`, con túnel) o `-Mode local` para probar sin túnel.

## Problemas comunes
- `Deploy failed`: `docker compose logs api --tail 100`.
- `pull` denegado: falta `docker login ghcr.io` o el token caducó.
- El túnel no conecta: token mal copiado o hostnames apuntando a `localhost` en vez de al nombre del servicio.
