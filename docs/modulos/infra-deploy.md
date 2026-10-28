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
1. Repo + `.gitignore` + CI vacío que compila.
2. Esqueleto Spring Boot 4.1 (Java 25, Maven wrapper, Flyway, actuator, Testcontainers).
3. Esqueleto Flutter `app` y `admin` (i18n es/en, tema, router, Riverpod).
4. Dockerfiles y compose.
5. Scripts de despliegue y guía de primer arranque en la Pi.
6. Backup `pg_dump` cifrado (script + cron), prueba de restauración.

## Tests
CI verde; `docker compose up` local con healthchecks OK; restauración de backup probada.

## Estado
Pendiente. Requiere configurar Graphify (`pendientes.md`).
