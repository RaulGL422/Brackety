# Modelo de datos: estado actual y objetivo

Propuesta del 2026-11-16, pedida por Raul ("se está enredando el código"); versión ligera tras su revisión. **Nada decidido**: el plan está en `modelo-datos-migracion.md` y las preguntas, en `pendientes.md`.

## Regla de oro (Raul, 2026-11-16)
- **Un dato vive en un solo sitio** de la BD. Lo que se puede calcular a partir de otro dato se calcula, no se guarda.
- Una caché solo se permite si se ha medido que hace falta, figura en la lista de abajo y tiene un test que la reconstruye y la compara.
- **En el código, igual**: una regla o un cálculo tiene un solo dueño (servicio o función) y el resto lo llama.

## Hoy: 28 tablas
| Bloque | Tablas | Qué hacer |
|---|---|---|
| Login y seguridad (7) | `account`, `identity`, `profile`, `consent`, `refresh_token`, `email_token`, `login_attempt` | Nada: normal para email + Google, verificación y RGPD |
| Registros obligatorios (3) | `admin_audit`, `participant_import`, `offline_rejected_op` | Nada |
| Competición (18) | `league`, `league_category_podium`, `event`, `event_category`, `event_organization`, `event_rulebook`, `event_staff`, `event_staff_name`, `mat`, `participant`, `fight_group`, `group_member`, `team`, `team_member`, `fight_match`, `match_event` | Aquí está el enredo |

## Datos repetidos hoy
| Dato | Dónde se repite | Objetivo |
|---|---|---|
| Alumno (nombre, nacimiento, estatura) | Un `participant` por fase | Una vez en `person` |
| Club participante | `event_organization` en cada fase; organizador en `profile` | Una vez en `organization` |
| Categorías de la liga | Copiadas en cada fase; podios unidos por nombre | Una vez en `competition_category` |
| Reglas | Columnas de `event`, por formato (`match_seconds`, `team_match_seconds`…) | Una fila por modalidad |
| Comodín | `group_member.ghost`, `team.ghost`, `team_member.ghost` | Papel del puesto en `group_slot` |
| Tapiz de un combate | `fight_group.mat_id`, `fight_match.mat_id`, `pinned` | Del grupo, salvo excepción del combate |
| Lado de un combate | Columnas de alumno y de equipo | Una columna por lado |
| Evento de un combate | `fight_match.event_id` (sale del grupo) | Del grupo |
| Marcador | Puntos y reloj en `fight_match` y en `match_event` | Calculado de `match_event` (o caché medida) |
| Nombre de la persona del staff | `event_staff_name` | Fuera: cuentas propias |

## Objetivo ligero: unas 26-27 tablas
Las 10 de login y registros siguen igual. Competición:
- **`organization`**: club o entidad (nombre, nombre corto, CIF). `event_organization` queda como enlace evento ↔ organización, sin copiar el nombre.
- **`person`**: alumno de una organización (nombre, apellidos, nacimiento, sexo opcional, tutor, último peso y estatura). Si se quiere historial de pesajes, `person_measure`; si no, son 2 columnas.
- **`registration`** (hoy `participant`): persona × evento con categoría elegida, medidas del día, pagado o no y consentimiento. Sin nombre ni nacimiento: los saca de `person`.
- **`competition`** (hoy `league`) y **`competition_category`**: las categorías se definen una vez y cada fase las usa. Sustituye a `league_category_podium`.
- **`event`**: fase, jornada o torneo de una competición. Sin columnas de reglas.
- **`event_category`**: la categoría en esa fase (edad, sexo y peso mín./máx., formato y tamaños), enlazada a su `competition_category`.
- **`modality`**: lista ordenada por evento (1 en la liga, 3 el 20-12), con sus reglas (duración, límite, descanso, cambio entre combates, descalificación, +1 cada N advertencias, motivos de advertencia, datos obligatorios) y su forma de clasificar (por categoría, sexo, peso o edad; global sí o no). Una categoría puede sobrescribir alguna regla.
- **`event_staff`** y **`location`** (hoy `mat`): nombre ("Tapiz 1", "Pista 2"), estado (en uso o inhabilitado) y árbitro.
- **`entry`** y **`entry_member`**: quien compite. **Un individual es una entrada de 1**; un equipo, de 2 o 3. Sustituye a `team` y `team_member`.
- **`fight_group`** y **`group_slot`** (`entry_id`, posición y papel: real o comodín). Sustituye a `group_member` y a las 3 marcas `ghost`.
- **`fight_match`** (`group_id`, `modality_id`, `red_entry_id`, `blue_entry_id`, orden y `location_override_id` si se movió a mano) y **`match_event`**.
- **`event_rulebook`**: igual, o un fichero en disco (a decidir).

Salen `event_staff_name`, `league_category_podium`, `team`, `team_member` y `group_member`. Entran `organization`, `person`, `competition_category`, `modality`, `entry`, `entry_member` y `group_slot`.

## En el código
- **Sin "¿es de equipos?"**: con `entry` hay un solo camino para el marcador, el tablero, la clasificación y los CSV.
- Un solo dueño por cálculo: nombre del competidor, tapiz efectivo, reglas que aplican a un combate, puntos de un combate y permiso "club o árbitro del tapiz" (hoy repetidos en varios servicios, `revision-f1.md`).
- Las reglas del marcador existen en Java y en Dart (hace falta para el modo offline): un solo juego de casos JSON que pasan los dos.
- La caché offline de la app no cuenta como dato repetido: es una copia del servidor que se reemplaza entera.
