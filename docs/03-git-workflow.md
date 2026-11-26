# 03 · Flujo Git

## Ramas
- `main`: producción, solo releases etiquetadas (`vX.Y.Z`).
- Release: rama `release/vX.Y.Z` desde `development` (en `CHANGELOG.md`, «Sin publicar» pasa a «X.Y.Z»), PR a `main` con merge commit y tag en ese merge. Nunca la PR directa desde `development`: el repo borra la rama de origen al fusionar.
- Tras la etiqueta: PR `chore/sync-main` que fusiona `main` en `development` (merge commit), para que la versión y los arreglos de la release lleguen a las imágenes `dev` de debug.
- `development`: integración. Siempre compila y pasa tests.
- Trabajo: una rama por módulo, `feat/<modulo>`, con todos sus pasos; `fix/…`, `chore/…`, `docs/…` para lo suelto. Todas desde `development`.

## Ciclo de una tarea
1. Elegir tarea pequeña de `docs/estado.md` y su MD de módulo.
2. Si la rama del módulo no existe, crearla (y worktree si hay trabajo en paralelo): `git worktree add ../brackety-wt/<rama> -b <rama> development`, y abrir su PR a `development` como borrador.
3. Implementar + tests (agentes `backend-dev` / `flutter-dev`).
4. Skill `close-task`: merge de `development`, tests, revisión, estado.
5. Siguiente tarea del módulo: en la misma rama. Si `development` avanza, fusionarlo en ella.
6. Módulo (o bloque acordado) terminado: PR lista para revisar; CI verde; Raul aprueba; merge squash. Borrar rama y worktree.

## Worktrees
Máximo 3 simultáneos, uno por tarea independiente (p. ej. backend y front del mismo módulo en paralelo solo si el contrato API está fijado). Nunca dos ramas tocando los mismos archivos.

## Commits
`tipo(modulo): resumen` en inglés; tipos: feat, fix, refactor, perf, test, docs, build, ci, chore. Cuerpo solo si explica un porqué.

## CI (GitHub Actions)
- En cada PR: build + tests backend (Maven), análisis y tests Flutter y tamaño de los MDs de `docs/`. Sin imágenes Docker.
- Imágenes solo en push a `development` (tag `dev`), `main` (`latest`) y tags `vX.Y.Z` (su versión): antes de publicar, compose completo (despliegue, backup/restauración, rollback) y debug; si falla, no se publica.
- Dependabot abre PRs semanales a `development` con actualizaciones (Maven, pub, Docker, Actions).
- Secretos de CI en GitHub Secrets; nunca en el repo.

## Hooks locales
`git config core.hooksPath .githooks` una vez por clon: `post-commit` actualiza Graphify en segundo plano.

## Repo
Un solo repositorio GitHub (nombre previsto `brackety`, a confirmar). `.gitignore` excluye `.env`, builds, `graphify-out` si procede, IDEs.
