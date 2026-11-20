# Modelo de datos: plan de migración

Cómo pasar de lo actual al objetivo ligero de `modelo-datos.md` (un dato en un solo sitio) sin perder los datos de la F1 (van a producción) y sin parar el desarrollo del calendario (20-12 y 24-01).

## Reglas
- **Ampliar, migrar, recortar.** Cada cambio en tres pasos: se añade lo nuevo junto a lo viejo y se rellena con una migración, el código pasa a usar lo nuevo y lo viejo se borra en una release posterior. Así un despliegue a medias nunca rompe nada.
- **Una PR por paso** (M1, M2…), sin mezclar cambios de comportamiento. Antes de cada una, tests de caracterización de lo que toca.
- **Flyway solo hacia delante**, con backup antes de desplegar (`09-despliegue.md`).
- **Prueba con datos reales anonimizados**: se restaura el backup de producción en local, un script cambia nombres y fechas por ficticios y el resultado se carga en debug (nunca datos reales en debug, `modulos/entornos.md`). Ahí se aplica la migración.
- **Comprobación de oro**: la clasificación de la liga, los resultados por categoría y el CSV de cada fase deben salir **idénticos** antes y después. Automatizada en `EventExportsGoldenTest` con una jornada ficticia de guion fijo (`plan-limpieza.md`, L0); una copia anonimizada de la F1 real se puede añadir como segundo juego cuando haya backup.
- **Paquete del pabellón y export .zip**: cada paso que cambie su forma sube `schemaVersion` y sigue importando las versiones anteriores (la F1 se guardó con la 1).
- **API estable para la app**: los DTO no cambian mientras se pueda; si cambian, la app acepta los dos formatos durante una versión (hay móviles con caché offline).

## Pasos
| Paso | Qué | Necesario para | Tamaño |
|---|---|---|---|
| M1 | `modality` con reglas y forma de clasificar: las reglas salen de `event`; las categorías por equipos sobrescriben duración y límite | 20-12 (3 modalidades), F1-4 advertencias, F2-4 clasificaciones | M · en pruebas (2026-11-16) |
| M2 | `organization`, `person` (con último peso y estatura) y `registration`: el alumno y el club, una sola vez. En tres PR: **M2a** `person` (fusionado, 2026-11-17), **M2b** `organization` (fusionado, 2026-11-17), **M2c** sexo, peso y estatura (en pruebas, 2026-11-17), **M2d** el club del alumno en `person` | F2 (24-01): F2-1 peso y estatura, F2-2 edades | L |
| M3 | `entry`, `entry_member` y `group_slot` con papel: individual = entrada de 1; fuera `team`, `team_member`, `group_member` y las marcas `ghost` | Un solo camino en marcador, tablero, clasificación y CSV | L |
| M4 | `location` con estado y `location_override_id` en el combate: fuera `pinned`, `fight_match.mat_id` y `fight_match.event_id` | Simplificar reparto, previsión y panel de control | M |
| M5 | `competition_category`: categorías una vez por liga; fuera `league_category_podium` | CSV claro (F2-3) y podios sin unir por nombre | M |
| M6 | Limpieza y datos calculados: fuera `event_staff_name` y lo viejo de M1-M5; puntos y reloj del combate calculados de `match_event` salvo caché medida | – | S |

## Calendario propuesto
- **Antes del 20-12**: M1 (sin él, las 3 modalidades serían más columnas en `event`).
- **Antes del 24-01**: M2, para que el peso y la estatura nazcan ya en su sitio.
- **Después del 24-01**, en la etapa 3 (`calidad.md`): M3, M4, M5 y M6, junto al refactor de cada módulo que tocan.
- Si el calendario aprieta, M2 puede quedarse en `organization` + `person` sin renombrar aún `participant`: sus nombres y nacimientos se mueven a `person` (se unen por `person_id`, que ya existe) y `participant` se queda solo con lo de la inscripción.

## Cómo se ve cada paso (M1 de ejemplo)
1. Migración: crear `modality`; por cada evento, una modalidad "Única" con sus reglas actuales; las categorías por equipos guardan solo lo que cambian (duración y límite de equipos).
2. Código: un solo `Rules rules(match)` que resuelve la herencia (categoría → modalidad). Todo lo que hoy lee `event.getMatchSeconds()` o `getTeamPointsLimit()` pasa a pedirle las reglas; desaparece el `if (equipo)` de las reglas.
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
Aprobado (2026-11-16). M2c en pruebas (2026-11-17): sexo en `person` (vacío para la F1 hasta que el club lo rellene), último peso y estatura en `person`, las medidas del día en la inscripción. M2b fusionado (2026-11-17): un club por cuenta dueña, enlazado a cada evento (`OrganizationMigrationTest`). M2a fusionado (2026-11-17): `person` con los datos de la fase más reciente (`PersonMigrationTest`); antes de desplegar, comprobar en la Pi que nadie tiene dos nacimientos distintos entre fases (consulta en la PR). M1 en pruebas: modalidades con migración probada (`ModalityMigrationTest`); las columnas de reglas de `event` siguen en la BD sin usarse hasta la siguiente release.
