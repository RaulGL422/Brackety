# Módulo · infra-deploy

## Objetivo
Repo, CI, esqueletos de `server/`, `app/`, `admin/` y despliegue reproducible en Pi y Windows.

## Reglas
- Un repo; estructura de `CLAUDE.md`. Ramas según `03-git-workflow.md`.
- Imágenes multi-arquitectura (arm64 + amd64) publicadas en GHCR por GitHub Actions.
- `deploy/docker-compose.yml` con servicios `api, web, admin, db, tunnel`; perfiles `pi` y `windows`.
- `deploy/.env.example` con todas las variables de `05-seguridad-infra.md`.
- `deploy/deploy.sh` (Linux) y `deploy.ps1` (Windows): pull, up, healthcheck, rollback.
- Healthchecks: `/actuator/health` en api; nginx 200 en web y admin.
- Cloudflare Tunnel: rutas `web`, `api`, `admin`; Access solo en `admin`.

## Tareas
1. Repo, `.gitignore`, Graphify y reglas (`chore/infra-repo-setup`).
2. Esqueleto Spring Boot 4.1 (Java 25, Maven wrapper, Flyway, actuator, Postgres embebido, Spotless), ejecutadores por escenario, reloj inyectable y CI backend (`feat/infra-server-skeleton`).
3. Esqueleto Flutter `app` y `admin` (i18n es/en, tema, router, Riverpod, layout responsive), destinos web/emulador/móvil/URL y CI Flutter (`feat/infra-flutter-skeleton`).
4. Dockerfiles, compose y publicación de imágenes en GHCR (`feat/infra-docker`).
5. Scripts de despliegue y guía de primer arranque en la Pi.
6. Backup `pg_dump` cifrado (script + cron), prueba de restauración.

## Docker
- `server/Dockerfile` (api) y `deploy/web.Dockerfile` (web y admin con `APP=app|admin`; Flutter clonado en la versión del proyecto). Las etapas de build corren en la plataforma del runner; solo la imagen final es arm64/amd64.
- `deploy/docker-compose.yml`: sin perfil arranca todo menos `tunnel` (prueba local y CI); `--profile pi` o `--profile windows` añade el túnel en un host público.
- Puertos solo en `127.0.0.1` (8080 api, 8081 web, 8082 admin); la entrada pública es siempre el túnel.
- Workflow `images.yml`: en cada PR construye y levanta el compose y comprueba los healthchecks; en `main` y tags `v*` publica `ghcr.io/raulgl422/brackety-{api,web,admin}` multi-arch (`latest`, versión, sha).

## Tests
CI verde; ejecutadores locales arrancan (`08-ejecucion-local.md`); `docker compose up` con healthchecks OK; restauración de backup probada.

## Estado
En curso: tareas 1 a 4 hechas. Siguen scripts de despliegue y guía de la Pi.
