---
name: new-module
description: Arrancar un módulo nuevo (rama, worktree, lectura mínima y plan de tareas). Usar al empezar cualquier módulo de docs/modulos/.
---
# Arrancar módulo `<modulo>`

1. Lee `docs/estado.md` y `docs/modulos/<modulo>.md` (y roles enlazados). Nada más.
2. Si el MD tiene dudas abiertas o secciones vacías, lista las dudas a Raul y para.
3. Divide el módulo en tareas pequeñas (backend, front, tests) y créalas en la lista de tareas. Cada tarea = una rama `feat/<modulo>-<tarea>`.
4. Crea el worktree de la primera tarea: `git worktree add ../brackety-wt/<rama> -b <rama> development`.
5. Implementa con el agente adecuado (`backend-dev`, `flutter-dev`).
6. Termina cada tarea con la skill `close-task`.
