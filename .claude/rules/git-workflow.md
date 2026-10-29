# Reglas Git (detalle en docs/03-git-workflow.md)

- Ramas permanentes: `main` (producción) y `development`. Todo nace de `development`.
- Nombre de rama: `feat/<modulo>-<tarea>`, `fix/<modulo>-<tarea>`, `chore/<tarea>`, `docs/<tarea>`.
- Una rama = una tarea pequeña y terminable (idealmente < 1 día de trabajo).
- Worktrees para trabajo paralelo: `git worktree add ../brackety-wt/<rama> -b <rama> development`. Máximo 3 a la vez.
- Commits en inglés, estilo `tipo(modulo): resumen` (`feat(auth): add google login`). Commits pequeños.
- Antes de PR: `development` fusionado en la rama, tests locales verdes, `docs/estado.md` actualizado.
- PR hacia `development`, merge squash solo con CI verde. Raul revisa y aprueba; Claude no fusiona a `main`.
- `main` se actualiza desde `development` en releases etiquetadas (`vX.Y.Z`).
- Prohibido: `push --force` a ramas compartidas, commitear `.env`, claves o datos reales.
