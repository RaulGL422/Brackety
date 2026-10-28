# 03 · Flujo Git

## Ramas
- `main`: producción, solo releases etiquetadas (`vX.Y.Z`).
- `development`: integración. Siempre compila y pasa tests.
- Trabajo: `feat/<modulo>-<tarea>`, `fix/…`, `chore/…`, `docs/…`, creadas desde `development`.

## Ciclo de una tarea
1. Elegir tarea pequeña de `docs/estado.md` y su MD de módulo.
2. Crear rama (y worktree si hay trabajo en paralelo): `git worktree add ../brackety-wt/<rama> -b <rama> development`.
3. Implementar + tests (agentes `backend-dev` / `flutter-dev`).
4. Skill `close-task`: merge de `development`, tests, revisión, estado.
5. PR a `development`; CI verde; Raul aprueba; merge squash.
6. Borrar rama y worktree.

## Worktrees
Máximo 3 simultáneos, uno por tarea independiente (p. ej. backend y front del mismo módulo en paralelo solo si el contrato API está fijado). Nunca dos ramas tocando los mismos archivos.

## Commits
`tipo(modulo): resumen` en inglés; tipos: feat, fix, refactor, test, docs, chore. Cuerpo solo si explica un porqué.

## CI (GitHub Actions)
- En cada PR: build + tests backend (Maven), análisis y tests Flutter.
- En `development`: construir imágenes y subirlas a GHCR con tag `dev`.
- En tags de `main`: imágenes con tag de versión.
- Secretos de CI en GitHub Secrets; nunca en el repo.

## Repo
Un solo repositorio GitHub (nombre previsto `brackety`, a confirmar). `.gitignore` excluye `.env`, builds, `graphify-out` si procede, IDEs.
