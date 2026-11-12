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
- Mis eventos: una tarjeta por liga con sus fases en orden; cada fase con sus botones (panel del club, grupos, mi tapiz).
- Panel del club: selector de fase arriba (si hay más de una) y pestaña **Liga**: fases (fecha, modalidad, inscritos), "Nueva fase" (nombre, fecha, modalidad, puntos de asistencia), clasificación acumulada por categoría con puntos por fase y medallas, CSV (web), y editar nombre y podios (general y por categoría).
- Inscripciones: "Inscribir de otras fases" (búsqueda, seleccionar todos, consentimiento de tutores si hay menores).
- Puntuaciones, Tapices, Inscripciones y Configuración siguen siendo de la fase abierta.

## Tests
Reinscripción, agrupación por categoría/estatura/peso, acumulación entre fases, asistencia, semilla.

## Estado
Servidor hecho (2026-11-11, `feat/league-phases`): liga con fases (cada evento es una fase; la F1 pasa a fase 1), nueva fase copiando configuración, reinscripción por persona, clasificación de liga (asistencia y puntos por fase) y podios por categoría. Pantallas en pruebas (2026-11-12, `feat/league-phases-front`): mis eventos por liga, selector de fase, pestaña Liga y reinscripción; falta la prueba a mano.
