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
4. Dockerfiles y compose.
5. Scripts de despliegue y guía de primer arranque en la Pi.
6. Backup `pg_dump` cifrado (script + cron), prueba de restauración.

## Tests
CI verde; ejecutadores locales arrancan (`08-ejecucion-local.md`); `docker compose up` con healthchecks OK; restauración de backup probada.

## Estado
En curso: tareas 1 y 2 hechas.
