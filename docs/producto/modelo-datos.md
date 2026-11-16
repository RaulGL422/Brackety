# Modelo de datos: estado actual y objetivo

Propuesta del 2026-11-16, pedida por Raul ("se está enredando el código"). **Nada decidido**: el plan está en `modelo-datos-migracion.md` y las preguntas, en `pendientes.md`.

## Hoy (24 migraciones, 28 tablas)
| Bloque | Tablas | Nota |
|---|---|---|
| Cuentas | `account`, `identity`, `profile`, `consent`, `refresh_token`, `email_token`, `login_attempt` | Bien separado; `auth` cerrado |
| Liga y evento | `league`, `league_category_podium`, `event`, `event_category`, `event_organization`, `event_rulebook` | Cada evento es una fase de una liga |
| Staff | `event_staff`, `event_staff_name`, `mat` | `event_staff_name` ya no sirve (cuentas propias) |
| Alumnos | `participant`, `participant_import` | Un `participant` por evento |
| Competición | `fight_group`, `group_member`, `team`, `team_member`, `fight_match`, `match_event`, `offline_rejected_op` | Lo más enredado |
| Admin | `admin_audit` | – |

## Problemas (de más a menos coste en el código)
1. **Reglas como columnas de `event`**: `match_seconds`, `points_limit`, `team_match_seconds`, `team_points_limit`, `min_rest_seconds`, `changeover_seconds` y `max_groups_per_mat` (sin uso). Cada formato nuevo añade columnas e `if (equipo)`. No sirve para las 3 modalidades del 20-12, los motivos de advertencia (F1-4) ni los datos obligatorios por deporte (F2-1).
2. **El alumno no existe fuera del evento**: `participant` copia nombre, nacimiento y estatura en cada fase; `person_id` es un UUID sin tabla que solo une las fases de una liga. No hay dónde guardar el peso "en la ficha global", ni sexo, ni historial.
3. **Un combate tiene dos tipos de lado**: `fight_match` lleva `red/blue_participant_id` y `red/blue_team_id`, y en `group_member` pasa lo mismo (`participant_id` o `team_id`). Por eso el nombre del competidor se calcula en 3 servicios y cada consulta pregunta si es de equipos.
4. **"Comodín" en tres sitios**: `group_member.ghost`, `team.ghost` y `team_member.ghost`. Un equipo comodín es una fila de `team` creada para un solo grupo. El papel se deducía y falló (F1-2).
5. **"Dónde se juega" repartido**: `mat_id` en el grupo y en cada combate, `mat_id` nulo = bote y `pinned` = movido a mano. `MatSchedule`, `MatPlanner` y el panel de control repiten esa lógica.
6. **Organizaciones por evento**: `profile.organization_name` (el organizador) y `event_organization` (clubes participantes) son copias sueltas; el mismo club se escribe en cada fase.
7. **Categorías por nombre**: `league_category_podium.category_name` une fases por texto; renombrar una categoría rompe la clasificación.
8. **Marcador**: `fight_match` guarda reloj y puntos además de `match_event`. Es una caché válida, pero hoy no se dice en ningún sitio.

## Objetivo
### Personas y organizaciones
- `organization`: club o entidad global (nombre, nombre corto, CIF), con el organizador como miembro. Sustituye a `profile.organization_name` y a `event_organization` (pasa a ser `event_organization(event_id, organization_id)`).
- `person`: alumno global de una organización (nombre, apellidos, nacimiento, sexo opcional, tutor). Es el `student_profile` de `perfiles-menores`.
- `person_measure`: peso y estatura con fecha y origen (declarado o pesaje). La ficha global enseña la última.
- `registration`: persona × evento (categoría elegida, medidas del día, pagado o no, consentimiento). Sustituye a `participant`.

### Competición y reglas
- `competition`: la liga o el torneo (hoy `league`), con sus `competition_category` compartidas por todas las fases.
- `event`: una fase, jornada o torneo de una competición (fecha, estado, origen del paquete).
- `ruleset`: duración, límite, descanso, cambio entre combates (`changeover_seconds`), descalificación, advertencias (+1 cada N), motivos de advertencia y datos obligatorios (peso, estatura, sexo). Viene de una plantilla de deporte; el evento, la categoría o la modalidad lo pueden sobrescribir.
- `modality`: lista ordenada por evento (1 en la liga; 3 el 20-12), cada una con su `ruleset`.
- `event_category`: edad, sexo y peso (mín./máx.), formato, tamaños y la `competition_category` a la que pertenece.
- `standing_rule`: cómo se clasifica (por categoría, sexo, peso o edad; global sí o no). Cubre F2-4.

### Combates
- `competitor`: lo que ocupa un lado, alumno o equipo (`registration_id` o `team_id`, exactamente uno). Un sitio para su nombre.
- `team` + `team_member(registration_id)`: solo equipos reales.
- `group_slot(group_id, position, competitor_id, role)` con `role` = `real` o `comodin`. Sustituye a `group_member` y a las tres marcas `ghost`; un equipo comodín es un `competitor` del grupo, no una fila nueva de `team`.
- `fight_match(red_competitor_id, blue_competitor_id, modality_id, …)`: un lado = una columna.
- Dónde se juega: `fight_group.location_id` (nulo = bote) y `fight_match.location_override_id` (movido a mano). Tapiz efectivo = el del combate o el de su grupo. Desaparecen `pinned` y el `mat_id` duplicado.
- `location` (hoy `mat`): nombre ("Tapiz 1", "Pista 2"), estado (en uso / inhabilitado, F1-1) y árbitro.
- `match_event`: igual. El reloj y los puntos de `fight_match` quedan documentados como caché.

### Se quita
`event_staff_name`, `max_groups_per_mat`, las marcas `ghost` y `league_category_podium.category_name` (pasa a `competition_category_id`).

## Qué no cambia
Cuentas, sesiones, consentimientos, auditoría, `match_event` y `offline_rejected_op`, y la regla de oro: el servidor es la fuente de verdad y el móvil manda acciones (`opId`).
