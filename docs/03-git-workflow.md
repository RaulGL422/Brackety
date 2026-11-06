# 03 · Flujo Git

## Ramas
- `main`: producción, solo releases etiquetadas (`vX.Y.Z`).
- Release: rama `release/vX.Y.Z` desde `development`, PR a `main` con merge commit y tag en ese merge. Nunca la PR directa desde `development`: el repo borra la rama de origen al fusionar.
- `development`: integración. Siempre compila y pasa tests.
- Trabajo: `feat/<modulo>-<tarea>`, `fix/…`, `chore/…`, `docs/…`, creadas desde `development`.

## Ciclo de una tarea
1. Elegir tarea pequeña de `docs/estado.md` y su MD de módulo.
2. Crear rama (y worktree si hay trabajo en paralelo): `git worktree add ../brackety-wt/<rama> -b <rama> development`.
3. Implementar + tests (agentes `backend-dev` / `flutter-dev`).
4. Skill `close-task`: merge de `development`, tests, revisión, estado.
5. PR a `development`; CI verde; Raul aprueba; merge squash.
6. Borrar rama y worktree. La siguiente tarea de esa línea empieza aquí, desde `development` ya actualizado: una sola PR abierta por línea de trabajo.

## Worktrees
Máximo 3 simultáneos, uno por tarea independiente (p. ej. backend y front del mismo módulo en paralelo solo si el contrato API está fijado). Nunca dos ramas tocando los mismos archivos.

## Commits
`tipo(modulo): resumen` en inglés; tipos: feat, fix, refactor, perf, test, docs, build, ci, chore. Cuerpo solo si explica un porqué.

## CI (GitHub Actions)
- En cada PR: build + tests backend (Maven), análisis y tests Flutter, tamaño de los MDs de `docs/`, y compose completo (despliegue, backup/restauración, rollback).
- En `main`: imágenes multi-arch a GHCR con tag `latest`; en tags `vX.Y.Z`, con su versión.
- Dependabot abre PRs semanales a `development` con actualizaciones (Maven, pub, Docker, Actions).
- Secretos de CI en GitHub Secrets; nunca en el repo.

## Hooks locales
`git config core.hooksPath .githooks` una vez por clon: `post-commit` actualiza Graphify en segundo plano.

## Repo
Un solo repositorio GitHub (nombre previsto `brackety`, a confirmar). `.gitignore` excluye `.env`, builds, `graphify-out` si procede, IDEs.
