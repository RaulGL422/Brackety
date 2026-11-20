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
   - Importación de alumnos (`modulos/importacion-alumnos.md`): `ANTHROPIC_API_KEY` = console.anthropic.com → API Keys (clave de API con las condiciones comerciales, **nunca** el token de `claude setup-token`). Antes, aceptar el DPA de Anthropic (`pendientes.md`). Vacía: no aparece "Importar alumnos" y lo demás funciona. La imagen de la api ya trae `claude`.
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
- Qué corre: `docker compose logs api | grep -A10 "is ready"` muestra la versión (la de `app/pubspec.yaml`, con `-dev` en debug), el commit, la BD con su esquema y qué está activo o falta (email, Google, superadmin, contacto de privacidad, importación, cuentas demo). Sin secretos ni emails. `GET /api/v1/info` también da la versión. El portátil del pabellón la lee de `api/version.txt`.

## Qué hace `deploy.sh` / `deploy.ps1`
1. Etiqueta como `rollback` las imágenes que están corriendo.
2. `docker compose pull` (si falla, no cambia nada).
3. `up -d --wait`: espera a los healthchecks (máx. 5 min).
4. Si fallan, vuelve a las imágenes `rollback` y termina con error.
- El rollback **no deshace migraciones** de base de datos: hacer backup antes de desplegar una versión con migraciones (tarea 6).
- `local` usa imágenes construidas en la máquina, sin pull ni túnel (`docker compose build && ./deploy.sh local`). Es lo que prueba el CI, rollback incluido.

## Debug en la misma Pi (`modulos/entornos.md`)
Otro proyecto de compose (`brackety-debug`) con su BD, sus puertos (8090-8092), su túnel y límites de CPU y memoria.
1. **Cloudflare**: un **segundo túnel** con `brackety-debug` → `http://web:80`, `brackety-debug-api` → `http://api:8080`, `brackety-debug-admin` → `http://admin:80`. Una aplicación de Access que cubra **los tres** hostnames.
2. **GitHub** (Settings → Variables): `DEBUG_API_BASE_URL=https://brackety-debug-api.rgal.dev` y `DEBUG_ADMIN_API_BASE_URL=https://brackety-debug-admin.rgal.dev`. Cada push a `development` publica las imágenes `dev` (api con escenarios, admin con la pestaña Escenarios).
3. **Pi**: `sudo mkdir -p /mnt/ssd/brackety-debug/pgdata`, `cp .env.debug.example .env.debug`, rellenarlo (BD, `JWT_SECRET` y superadmin **propios**, token del segundo túnel, Access) y `chmod 600 .env.debug`.
4. `./deploy.sh debug` (mismo pull, espera y rollback que producción; se niega si comparte `JWT_SECRET`).
- **Días de evento**: `./deploy.sh debug-stop` la víspera; `./deploy.sh debug` al acabar. Parado no arranca solo tras reiniciar.
- Actualizar: `./deploy.sh debug` tras cada fusión en `development`.
- Comandos sueltos: `docker compose --env-file .env.debug -f docker-compose.yml -f docker-compose.debug.yml logs api`.
- Sin backups: lo que importe, en una copia con nombre de la pestaña Escenarios.

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

## Datos de la F1 a producción (`modulos/entornos.md`)
Los datos se quedan en la BD de la Pi: la cuenta `club1` pasa a ser la de la entidad (la lleva Raul) y las genéricas se retiran.
1. **Resultados del pabellón**: si no se importaron, en el panel del club, "Importar resultados del pabellón" con el `.zip` del portátil.
2. **Antes de actualizar**, con la versión vieja: exportar "Todo el evento (.zip)" de cada fase y la clasificación de la liga. Son la referencia y llevan datos de menores: guardarlos cifrados y borrarlos tras la comprobación.
3. `./backup.sh` y, en `psql`, `select person_id from participant group by person_id having count(distinct birth_date) > 1;` debe salir vacío (si no, corregir esos nacimientos antes: la migración de personas toma el último).
4. SSD (paso 3 del primer arranque) si aún no está, `DEMO_ACCOUNTS_ENABLED=false` en `.env` y `./deploy.sh pi` con la versión nueva.
5. **Comprobar**: la clasificación de la liga y los resultados por categoría salen con los mismos puestos y puntos que en el paso 2.
6. `./backup.sh` y `./f1-handover.sh <email de la entidad>`: pide la contraseña nueva (≥10), enseña en seco cómo queda y aplica solo si se escribe `HANDOVER`.
   - `club1` pasa a ese email y contraseña (mismo id: eventos, ligas, clubes y alumnos siguen siendo suyos). Se cierran sus sesiones.
   - Cuentas sin `@` (`ayudante*`, `arbitro*`, staff del paquete): suspendidas y sin contraseña. Siguen en el historial (quién arbitró qué). Queda en la auditoría del superadmin.
7. Entrar con el email nuevo y revisar la liga, el PDF de la clasificación y los CSV.
- **Ceder al club** (cuando la app esté estable): desde la cuenta, Ajustes → cambiar email al del club (necesita Resend). El club pone su contraseña con "¿Olvidaste tu contraseña?".

## Portátil del pabellón (sin Internet ni Docker)
Carpeta portable con PostgreSQL, Java, API y web: cómo generarla y usarla en `modulos/servidor-local.md`.

## Windows (servidor alternativo)
1. Docker Desktop con backend WSL 2, que arranque al iniciar sesión.
2. Clonar el repo, `deploy\.env` desde `.env.example` (en `DB_DATA` dejar `pgdata` o una ruta tipo `D:/brackety/pgdata`).
3. `.\deploy\deploy.ps1` (perfil `windows`, con túnel) o `-Mode local` para probar sin túnel.

## Problemas comunes
- `Deploy failed`: `docker compose logs api --tail 100`.
- `pull` denegado: falta `docker login ghcr.io` o el token caducó.
- Túnel `Inactive` y `tunnel` en `Restarting` con "Provided Tunnel token is not valid": copiar solo lo que va tras `--token` (empieza por `eyJ`), sin espacios ni comillas.
- Error 1033 en el navegador: el nombre apunta a un túnel no conectado (ver el anterior) o el CNAME es de otro túnel.
- "no such host" en `logs tunnel`: la URL de la ruta debe ser el **servicio** del compose (`http://web:80`, `http://api:8080`), no el contenedor (`brackety-web`) ni `localhost`.
- Importar responde "No se ha podido leer la lista": `docker compose logs api --tail 50 | grep -i "claude"`. Clave mal copiada o sin saldo en Anthropic; `docker compose exec api claude --version` comprueba que el CLI está.
