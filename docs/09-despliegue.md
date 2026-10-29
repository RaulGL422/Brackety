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

## Windows (servidor alternativo)
1. Docker Desktop con backend WSL 2, que arranque al iniciar sesión.
2. Clonar el repo, `deploy\.env` desde `.env.example` (en `DB_DATA` dejar `pgdata` o una ruta tipo `D:/brackety/pgdata`).
3. `.\deploy\deploy.ps1` (perfil `windows`, con túnel) o `-Mode local` para probar sin túnel.

## Problemas comunes
- `Deploy failed`: `docker compose logs api --tail 100`.
- `pull` denegado: falta `docker login ghcr.io` o el token caducó.
- El túnel no conecta: token mal copiado o hostnames apuntando a `localhost` en vez de al nombre del servicio.
