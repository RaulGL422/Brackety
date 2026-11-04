# Módulo · marcador-tapiz

## Objetivo
Herramienta del ayudante en su ubicación: grupo, combates, marcador, tiempo y sanciones.

## Reglas
- El ayudante ve el **grupo actual** asignado a su tapiz (puede tener varios) y el listado de combates respetando los descansos del evento.
- Marcador según el reglamento de la modalidad/fase/categoría: botones de puntos válidos, límites automáticos (p. ej. 15 en tambo, 30 corta el combate en derribos), una técnica una vez (suelo).
- Cronómetro por modalidad (tambo 2:00, derribos 1:30; suelo pendiente) con pausa y reanudación.
- Amonestaciones y avisos, cambios de participante, observaciones por combate, firma del árbitro/mesa.
- **PDF del reglamento** accesible desde la pantalla de marcador.
- Foto del alumno visible solo con permiso de marcador, en su tapiz y evento.
- Un solo escritor por tapiz; traspaso explícito (`offline.md`).
- Deshacer última acción con registro de auditoría.
- Resultado del combate se confirma y bloquea; correcciones con permiso y rastro.

## Datos
`match`, `match_event` (puntos, avisos, tiempo), `match_note`, `scoreboard_session`.

## Pantallas
Selector de grupo/combate, marcador (botones grandes, una mano), cronómetro, resumen y firma.

## Offline
Funciona sin red con el grupo descargado; ver `offline.md`.

## Tests
Cada regla del reglamento (Yoseikan), límites, deshacer, un escritor por tapiz, descansos.

## Estado
Pendiente.
