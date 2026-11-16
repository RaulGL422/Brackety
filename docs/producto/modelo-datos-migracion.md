# Modelo de datos: plan de migración

Cómo pasar de lo actual al objetivo de `modelo-datos.md` sin perder los datos de la F1 (van a producción) y sin parar el desarrollo del calendario (20-12 y 24-01).

## Reglas
- **Ampliar, migrar, recortar.** Cada cambio en tres pasos: se añade lo nuevo junto a lo viejo y se rellena con una migración, el código pasa a usar lo nuevo y lo viejo se borra en una release posterior. Así un despliegue a medias nunca rompe nada.
- **Una PR por paso** (M1, M2…), sin mezclar cambios de comportamiento. Antes de cada una, tests de caracterización de lo que toca.
- **Flyway solo hacia delante**, con backup antes de desplegar (`09-despliegue.md`).
- **Prueba con datos reales anonimizados**: se restaura el backup de producción en local, un script cambia nombres y fechas por ficticios y el resultado se carga en debug (nunca datos reales en debug, `modulos/entornos.md`). Ahí se aplica la migración.
- **Comprobación de oro**: la clasificación de la liga, los resultados por categoría y el CSV de cada fase deben salir **idénticos** antes y después. Se automatiza como test con una exportación guardada de la F1 anonimizada.
- **Paquete del pabellón y export .zip**: cada paso que cambie su forma sube `schemaVersion` y sigue importando las versiones anteriores (la F1 se guardó con la 1).
- **API estable para la app**: los DTO no cambian mientras se pueda; si cambian, la app acepta los dos formatos durante una versión (hay móviles con caché offline).

## Pasos
| Paso | Qué | Necesario para | Tamaño |
|---|---|---|---|
| M1 | `ruleset` y `modality`: las reglas salen de `event`; evento, categoría y modalidad heredan y sobrescriben | 20-12 (3 modalidades), F1-4 advertencias | M |
| M2 | `organization`, `person`, `person_measure`, `registration`: el alumno global con peso y estatura; `participant` pasa a ser vista o se renombra | F2 (24-01): F2-1 peso y estatura, F2-2 edades | L |
| M3 | `competitor` y `group_slot` con `role`: un lado = una columna; fuera las marcas `ghost` y los equipos comodín de un solo uso | Simplificar marcador, tablero y CSV | L |
| M4 | `location` con estado y tapiz efectivo (grupo o combate): fuera `pinned` y el `mat_id` duplicado | Simplificar reparto, previsión y panel de control | M |
| M5 | `competition` y `competition_category`; `standing_rule` | F2-4 clasificaciones configurables, CSV claro (F2-3) | M |
| M6 | Limpieza: `event_staff_name`, `max_groups_per_mat`, columnas viejas de M1-M5 | – | S |

## Calendario propuesto
- **Antes del 20-12**: M1 (sin él, las 3 modalidades serían más columnas en `event`).
- **Antes del 24-01**: M2, para que el peso y la estatura nazcan ya en su sitio.
- **Después del 24-01**, en la etapa 3 (`calidad.md`): M3, M4, M5 y M6, junto al refactor de cada módulo que tocan.
- Si el calendario aprieta, M2 puede quedarse en `person` + `person_measure` sin tocar aún `participant` (se une por `person_id`, que ya existe).

## Cómo se ve cada paso (M1 de ejemplo)
1. Migración: crear `ruleset` y `modality`; por cada evento, un `ruleset` con sus columnas actuales y una modalidad "Única"; `event_category.ruleset_id` nulo (hereda).
2. Código: un solo `Rules rules(match)` que resuelve la herencia (modalidad → categoría → evento → plantilla). Todo lo que hoy lee `event.getMatchSeconds()` o `getTeamPointsLimit()` pasa a pedirle las reglas.
3. Tests: los de reglas del marcador (Dart y Java comparten casos), la simulación de jornadas y la comprobación de oro.
4. Release siguiente: borrar las columnas de reglas de `event`.

## Riesgos
| Riesgo | Mitigación |
|---|---|
| Romper la clasificación de la liga ya jugada | Comprobación de oro en cada paso |
| Móviles con caché vieja tras desplegar | DTO estables o doble formato durante una versión |
| M2 y M3 son grandes y chocan con trabajo en paralelo | Una línea de trabajo a la vez sobre esas tablas; el resto espera |
| El paquete .brackety de la F1 deja de abrirse | Importadores por `schemaVersion` con test del fichero real anonimizado |
| Retrasar el 20-12 | Solo M1 antes; lo demás no bloquea |

## Estado
Propuesta (2026-11-16). Falta que Raul la apruebe y responda las preguntas de `pendientes.md`.
