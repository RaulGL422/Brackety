---
paths: ["deploy/**", ".github/**", "**/Dockerfile", "**/*.Dockerfile", "**/*.sh", "**/*.ps1", ".githooks/**"]
---
# Reglas de infraestructura (Docker, CI, scripts)

## Imágenes y CI
- Imágenes base con versión exacta (`postgres:18.6-alpine`, nunca `latest` ni solo mayor). Las actualiza Dependabot.
- Acciones de GitHub de terceros fijadas por SHA con la versión en comentario (`uses: x/y@<sha> # v1.2.3`); las de `actions/*` también en jobs con permisos de escritura.
- `permissions` mínimos por workflow y por job. Secretos solo en GitHub Secrets / Variables.
- Etapas de build con `--platform=$BUILDPLATFORM` cuando el resultado no depende de la arquitectura.
- Nada de secretos en `ARG`/`ENV` de imágenes ni en logs. `.dockerignore` excluye `.env`, claves y builds locales.
- Servicios sin root cuando la imagen lo permita; puertos solo en `127.0.0.1`; la entrada pública es el túnel.

## Scripts
- Bash: `#!/usr/bin/env bash` + `set -euo pipefail`; comillas en todas las variables; `cd "$(dirname "$0")"`.
- `deploy.sh` y `deploy.ps1` hacen los mismos pasos: un cambio en uno se replica en el otro.
- PowerShell 5.1: comprobar `$LASTEXITCODE` tras cada comando nativo que importe; no usar `$ErrorActionPreference='Stop'` con redirecciones de nativos.
- `docker compose exec -T` lee el stdin del script: añadir `< /dev/null` si no se le pasa entrada a propósito.
- Todo fallo imprime qué ha pasado y qué queda (p. ej. "Rollback failed: the service is down").
- Operaciones destructivas: primero se prueban en una copia (base temporal, imagen `rollback`) y solo después se tocan los datos reales, con confirmación explícita. Lo anterior se renombra, no se borra.

## Pruebas
- Todo script de `deploy/` se prueba en el job `compose-smoke`, incluido su camino de error (versión rota, rollback, restauración).
- Lo que no puede ejecutarse en CI (p. ej. `deploy.ps1`) al menos se valida con su parser y se dice en la PR.
