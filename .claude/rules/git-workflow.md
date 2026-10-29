# Reglas Git (detalle en docs/03-git-workflow.md)

- Ramas permanentes: `main` (producción) y `development`. Todo nace de `development`.
- Nombre de rama: `feat/<modulo>-<tarea>`, `fix/<modulo>-<tarea>`, `chore/<tarea>`, `docs/<tarea>`.
- Una rama = una tarea pequeña y terminable (idealmente < 1 día de trabajo).
- **Una PR abierta por línea de trabajo**: la siguiente tarea empieza desde `development` después de fusionar la anterior. Nada de PRs encadenadas (con squash obligan a rehacer cada una).
- Worktrees solo para tareas independientes en paralelo: `git worktree add ../brackety-wt/<rama> -b <rama> development`. Máximo 3 a la vez.
- Commits en inglés, `tipo(modulo): resumen`. Tipos: feat, fix, refactor, perf, test, docs, build, ci, chore. Commits pequeños.
- `git add` con rutas concretas, nunca `-A` a ciegas: revisar `git status` antes (en una rama pueden quedar archivos generados sin seguimiento).
- Antes de PR: `development` fusionado en la rama, tests locales verdes, `docs/estado.md` actualizado.
- PR hacia `development`, merge squash solo con CI verde. Raul revisa y aprueba; Claude no fusiona a `main`.
- `main` se actualiza desde `development` en releases etiquetadas (`vX.Y.Z`).
- Prohibido: `push --force` (también en ramas propias: se corrige con commits nuevos), commitear `.env`, claves o datos reales.
