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
Panel de fase, creación de grupos, asignación a tapiz, tabla por categoría, registro general acumulado.

## Tests
Reinscripción, agrupación por categoría/estatura/peso, acumulación entre fases, asistencia, semilla.

## Estado
Pendiente. Detalle fino cuando se construya el módulo.
