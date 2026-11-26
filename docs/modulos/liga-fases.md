# Módulo · liga-fases

## Objetivo
Liga cuyo cada fase es un minievento (caso real: Liga Yoseikan, 4 fases).

## Reglas
- Cada fase tiene su inscripción (los participantes vuelven a inscribirse; el organizador puede importar los de la fase anterior).
- Cada fase tiene su modalidad, reglamento, ubicaciones, ayudantes y plantilla de puntuación.
- **Puntos de asistencia** por fase, configurables (Yoseikan: 10).
- Puntuación acumulada entre fases por categoría y global (`ranking.md`).
- **Agrupación manual por ayudantes**: la lista de inscritos se filtra por categoría y se ordena por estatura y luego peso (nulos al final). El ayudante crea grupos (en Yoseikan, de 4). Dentro del grupo, orden de combates con semilla aleatoria (ajustable a mano).
- Asignar grupo a tapiz; el ayudante del tapiz descarga el grupo y trabaja desde ahí (offline posible).
- Combate por 3.er puesto/desempate: aviso en la tabla (`liga.md`).
- Iniciar y finalizar fase solo con puerta legal activa.

## Datos
`phase` (modalidad, estado), `phase_registration`, `group`, `group_assignment`, `phase_points`.

## Pantallas
- Mis eventos (Raul, 2026-11-26): «En curso», «Próximos» y «Finalizados» según el estado de la fase (`phaseState` en `GET /api/v1/events`); cada liga una vez, en su fase de ahora. Fila de fases deslizable con la actual en el centro; cada fase abre la suya. El club abre o prepara la fase y ve la liga; ayudante o árbitro: con una tarea, su botón; con varias, «Entrar al evento»; sin tarea, «Por decidir». El tapiz se abre al empezar la fase. «Nuevo evento» solo para club o entidad.
- Pantalla de la liga (`/leagues/<fase>`): fases (fecha, modalidad, inscritos; cada una abre su panel), "Nueva fase" (nombre, fecha, modalidad, puntos de asistencia), clasificación acumulada por categoría con puntos por fase y medallas, CSV (web), y editar nombre y podios.
- Podios: el general con un toque ("1 oro · 1 plata · 1 bronce", "1·1·2" u "Otro" con contadores −/+); cada categoría "Como el general" o "Propio" con el mismo selector.
- Panel de una fase: la flecha vuelve a la liga; selector de fase arriba (si hay más de una).
- Inscripciones: "Inscribir de otras fases" (búsqueda, seleccionar todos, consentimiento de tutores si hay menores).
- Puntuaciones, Tapices, Inscripciones y Configuración siguen siendo de la fase abierta. En Configuración, los puntos por asistir de la fase (0-100; recalculan la clasificación de la liga).

## Tests
Reinscripción, agrupación por categoría/estatura/peso, acumulación entre fases, asistencia, semilla.

## Estado
Servidor hecho (2026-11-11, `feat/league-phases`): liga con fases (cada evento es una fase; la F1 pasa a fase 1), nueva fase copiando configuración, reinscripción por persona, clasificación de liga (asistencia y puntos por fase) y podios por categoría. Pantallas en pruebas (2026-11-12, `feat/league-phases-front`): mis eventos por liga, selector de fase, pestaña Liga y reinscripción (#81); puntos por asistir editables en Configuración; falta la prueba a mano.
