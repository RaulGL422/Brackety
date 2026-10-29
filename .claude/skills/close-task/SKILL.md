---
name: close-task
description: Cerrar una tarea o módulo: tests, revisión, estado y PR. Usar siempre al terminar una tarea.
---
# Cerrar tarea

1. Fusiona `development` en la rama y resuelve conflictos.
2. Ejecuta los tests afectados; si es el último de un módulo, la suite completa y la checklist de `docs/04-testing.md`.
3. Lanza el agente `reviewer` (indícale la base si no es `development`). Corrige los bloqueantes.
4. Actualiza `docs/estado.md` (módulo, tarea, fecha), `docs/decisiones.md` y `docs/pendientes.md` si procede.
5. Abre PR hacia `development` con: qué hace, cómo probarlo, tests ejecutados. No fusiones: decide Raul.
6. Retira el worktree cuando se fusione: `git worktree remove ../brackety-wt/<rama>`. No empieces la siguiente tarea de la misma línea hasta que esta PR esté fusionada.
