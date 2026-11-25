# Reglas Git (detalle en docs/03-git-workflow.md)

- Ramas permanentes: `main` (producción) y `development`. Todo nace de `development`.
- **Una rama por módulo** (Raul, 2026-11-24): `feat/<modulo>`. Todos los pasos del módulo van en ella, en commits pequeños; no una rama ni una PR por paso. Lo suelto: `fix/<tarea>`, `chore/<tarea>`, `docs/<tarea>`.
- Al crear la rama del módulo se abre su PR a `development` como borrador: el CI corre en cada push. Al terminar el módulo (o el bloque acordado con Raul) pasa a lista para revisar y se fusiona una vez.
- Nada de PRs encadenadas ni varias PRs del mismo módulo a la vez (con squash obligan a rehacer cada una).
- Worktrees solo para tareas independientes en paralelo: `git worktree add ../brackety-wt/<rama> -b <rama> development`. Máximo 3 a la vez.
- Commits en inglés, `tipo(modulo): resumen`. Tipos: feat, fix, refactor, perf, test, docs, build, ci, chore. Commits pequeños.
- `git add` con rutas concretas, nunca `-A` a ciegas: revisar `git status` antes (en una rama pueden quedar archivos generados sin seguimiento).
- Antes de PR: `development` fusionado en la rama, tests locales verdes, `docs/estado.md` actualizado y una línea en «Sin publicar» de `CHANGELOG.md` si Raul lo notará al probar.
- PR hacia `development`, merge squash solo con CI verde. Raul revisa y aprueba; Claude no fusiona a `main`.
- `main` se actualiza desde `development` en releases etiquetadas (`vX.Y.Z`), siempre a través de una rama `release/vX.Y.Z` (el repo borra la rama de origen al fusionar).
- Prohibido: `push --force` (también en ramas propias: se corrige con commits nuevos), commitear `.env`, claves o datos reales.
