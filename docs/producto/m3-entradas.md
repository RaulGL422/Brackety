# M3 · Entradas: un individual es un equipo de 1

Diseño del paso M3 de `modelo-datos-migracion.md`. Decisión de calendario en `decisiones.md` (2026-11-26): diseño y tests ya; migración tras el 20-12.

## Objetivo
Un solo camino para competir. Hoy hay 100 bifurcaciones «¿es equipo? ¿es fantasma?» en 26 archivos del servidor y 181 en 22 de la app. El código ya lo esconde en memoria (`CompetitorDirectory` → `Competitor`); M3 lo lleva a la BD.

## Lo único que distingue a un equipo
1. Tiene número: se muestra «Equipo N»; un individual, el nombre de la persona.
2. Tiene de 2 a 5 miembros; un individual, 1.
3. Puede ser fantasma entero, o tener miembros fantasma: combaten y no puntúan.
Todo lo demás (grupo, combates, marcador, descanso, ocupado en otro tapiz, clasificación) ya es igual.

## Tablas
| Hoy | Con M3 |
|---|---|
| `team` (evento, categoría, número, fantasma) | `entry` (evento, categoría, `number` nulo si es individual) |
| `team_member` (equipo, alumno, orden, fantasma) | `entry_member` (entrada, inscrito, orden, `scores`) |
| `group_member` (grupo, alumno **o** equipo, orden, fantasma) | `group_slot` (grupo, entrada, orden, `ghost`) |
| `fight_match.red_participant_id`, `red_team_id` (y azul) + `check` de exclusión | `fight_match.red_entry_id`, `blue_entry_id` no nulos |

Reglas en la BD:
- `entry_member`: `unique (entry_id, participant_id)`, `unique (entry_id, position)`.
- `group_slot`: `unique (group_id, position)`, `unique (group_id, entry_id)`, y `unique (entry_id) where not ghost` (una entrada juega de verdad en un solo grupo).
- Un individual tiene una sola entrada por evento y persona, reutilizada si hace de fantasma en otro grupo. Lo garantiza el servicio al crearla (bajo el bloqueo del evento): un índice de `entry` no ve sus miembros.
- Fuera: el `check` de exclusión de `fight_match`, `group_member_team_once_uk`, las dos marcas `ghost` repetidas.

## «Puntúa en un solo sitio»
Hoy lo vigilan `group_member_real_uk` y `team_member_real_uk`. Con M3 una persona puntúa si está en una entrada con `scores` cuyo `group_slot` no es `ghost`. No cabe en un índice: lo comprueba `CategoryRoster.requireFree` (como hoy) bajo el bloqueo del evento.
**Pregunta abierta para Raul**: ¿un individual puede seguir siendo fantasma en un grupo y real en otro? Hoy sí (fantasma rellena huecos); con M3 se mantiene con `group_slot.ghost`.

## Código
- `Competitor` pasa a ser la entrada leída de la BD; `CompetitorDirectory` lee 2 tablas en vez de 3 y deja de componer.
- Crear grupo: un solo flujo. Para individuales crea (o reutiliza) sus entradas y sigue el camino de equipos. `POST …/groups` acepta `entryIds` + `ghostEntryIds`; durante una versión sigue aceptando `participantIds`/`teamIds` (móviles con caché vieja).
- Marcador, tablero, control, planificador, hojas y paquete: `getRedId()`/`getBlueId()` ya devuelven el id del competidor; pasan a `entry`. Desaparecen las ramas por tipo.
- App: `participantId`/`teamId` en los DTO del combate y del grupo → `entryId`; nombre y miembros vienen del servidor.
- Se dividen con M3 (no antes, sería trabajo doble): `AdminEventService` (SQL sobre `team_member`/`group_member`), `EventPackageService`, `EventResultsTransfer`, `MatPlanner.simulate`, `MatBoardService.board`, `MatFloor.load`: los métodos largos del servidor que quedan.

## Migración (Flyway, una sola, con test)
1. Crear `entry` por cada `team` (mismo id: no cambian enlaces ni paquetes) y por cada inscrito que esté en algún `group_member` o combate.
2. `entry_member` desde `team_member` (`scores = not ghost and not team.ghost`) y uno por individual (`scores = true`).
3. `group_slot` desde `group_member` (`ghost` = el del miembro o el del equipo).
4. Rellenar `red_entry_id`/`blue_entry_id`; después `not null`.
5. Las tablas viejas se borran en la release siguiente (como M1), no en esta.

## Red de seguridad (antes de migrar)
- Comprobación de oro (`EventExportsGoldenTest`): ya cubre equipos con bote, comodín y fantasmas; las descargas deben salir idénticas.
- Tests de caracterización que faltan: ver «Tests» abajo; se escriben ya, sobre el modelo actual.
- `EntryMigrationTest`: un evento con todos los casos se migra y responde igual (grupos, combates, clasificación, paquete).
- Paquete `.brackety`: importador por `schemaVersion`; el de la F1 (anonimizado) se sigue abriendo.

## Tests
La red ya existe y debe pasar igual tras M3 (sin cambiar los tests, solo cómo crean datos):
- `TeamControllerTest` y los de `grouping` y `scoreboard` (más de 30 casos): equipo y alumno fantasma, solo fantasmas, `SAME_FIGHTER`, grupo individual en categoría por equipos, mover entre equipos.
- `MatchDispatchSimulationTest` y tablero: equipo ocupado por cualquier miembro (también como comodín en otro grupo), descanso del miembro con menos descanso, bote de tapices libres; simulación del día con semillas.
- `EventExportsGoldenTest` (descargas byte a byte) y `EventPackageServiceTest` (paquete con equipos).
- Falta: `EntryMigrationTest` (se escribe con la migración).

## Estado
Diseño (2026-11-26). Migración tras el 20-12.
