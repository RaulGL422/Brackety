---
name: new-module
description: Arrancar un módulo nuevo (rama, worktree, lectura mínima y plan de tareas). Usar al empezar cualquier módulo de docs/modulos/.
---
# Arrancar módulo `<modulo>`

1. Lee `docs/estado.md` y `docs/modulos/<modulo>.md` (y roles enlazados). Nada más.
2. Si el MD tiene dudas abiertas o secciones vacías, lista las dudas a Raul y para.
3. Divide el módulo en tareas pequeñas (backend, front, tests) y créalas en la lista de tareas. Todas van en una sola rama `feat/<modulo>`, en commits pequeños.
4. Crea la rama y su worktree: `git worktree add ../brackety-wt/feat/<modulo> -b feat/<modulo> development`, y abre su PR a `development` como borrador (`gh pr create --draft`) para que el CI corra en cada push.
5. Implementa con el agente adecuado (`backend-dev`, `flutter-dev`).
6. Termina el módulo (o el bloque acordado con Raul) con la skill `close-task`.
