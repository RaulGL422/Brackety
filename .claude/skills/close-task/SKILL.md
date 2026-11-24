---
name: close-task
description: Cerrar una tarea o módulo: tests, revisión, estado y PR. Usar siempre al terminar una tarea.
---
# Cerrar tarea

1. Fusiona `development` en la rama y resuelve conflictos.
2. Ejecuta los tests afectados; si es el último de un módulo, la suite completa y la checklist de `docs/04-testing.md`.
3. Lanza el agente `reviewer` (indícale la base si no es `development`). Corrige los bloqueantes.
4. Actualiza `docs/estado.md` (una línea: estado, doc y nº de PR, sin descripción), `docs/decisiones.md` y `docs/pendientes.md` si procede (lo que Raul debe probar a mano, en su sección 2).
5. Al acabar una tarea del módulo: commit y push a su rama (`feat/<modulo>`), sin PR nueva. Al acabar el módulo o el bloque acordado: la PR borrador del módulo pasa a lista (`gh pr ready`) con qué hace, cómo probarlo y tests ejecutados. No fusiones: decide Raul.
6. Retira el worktree cuando se fusione: `git worktree remove ../brackety-wt/<rama>`. La siguiente tarea del módulo sigue en la misma rama.
