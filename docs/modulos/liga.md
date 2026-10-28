# Módulo · liga

## Objetivo
Liga con participantes fijos: todos contra todos, jornada a jornada.

## Reglas
- Mismos participantes durante todo el evento. Ida y vuelta configurable.
- Calendario y orden de fases aleatorios con **semilla guardada**; garantiza que todos se enfrenten (algoritmo de rotación por jornadas).
- Número impar: descanso (bye) rotatorio.
- Grupos de X personas o parejas; sistema nórdico (todos contra todos en el grupo).
- Grupos incompletos o con sobrante: ver `puntuacion.md`.
- Roles de ayudante guardados en todo el evento; ubicaciones y ayudantes pueden cambiar por fase.
- Descansos mínimos entre combates configurables.
- Tabla de clasificación con aviso de empate en el podio: se propone combate o mini torneo **dentro del mismo evento** (se probará y ajustará).
- Combate por 3.er puesto configurable en el evento.

## Datos
`phase`, `group`, `group_member`, `match`, `standing`.

## Pantallas
Calendario/jornadas, tabla de clasificación, vista del participante.

## Tests
Calendario completo sin repetidos con 3, 4, 5, 6 y 7 participantes; semilla reproducible; ida y vuelta; bye; empates.

## Estado
Pendiente.
