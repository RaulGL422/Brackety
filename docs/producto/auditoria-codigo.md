# Auditoría del código (2026-11-18)

Pedido de Raul: buscar a fondo el código enrevesado, repetido u optimizable antes de que crezca. Es la tarea 2 de la etapa 3 (`calidad.md`, "Inventario con números"). Plan de arreglo en `plan-limpieza.md`; diseño en `diseno-revision.md`.

## Tamaño (sin generados ni l10n)
| Parte | Archivos | Líneas | Tests (líneas) |
|---|---|---|---|
| `server` | 287 | 21.700 | 16.400 |
| `app` | 178 | 33.800 | 12.000 |
| `admin` | 48 | 10.100 | 2.300 |
| `brackety_core` | 19 | 1.700 | – |
| Migraciones | 35 | 660 | – |

## Veredicto
- **Bien**: tokens de diseño respetados (4 colores sueltos en toda la app, 2 `fontSize`), sin textos fijos en widgets, servidor sin ciclos entre paquetes, un solo sitio para permisos (`EventAccess`) y errores tipados (`EventException`), tests de servicio y controller con BD real, CI por componentes.
- **Mal**: pantallas gigantes, dos caminos para todo (individual y equipos), ciclos entre features de la app, el panel de control escrito dos veces (app y admin), cada deporte escrito en código, y reglas del backend que el código no cumple.

## Hallazgos por orden de impacto
### 1. Dos caminos: individual y equipos
- 70 ramas "¿es de equipos?" o "¿es comodín?" en 16 archivos del servidor (`GroupService`, `MatBoardService`, `MatchControlService`, `MatPlanner`, `MatSchedule`, `EventSheets`, `ScoreboardService`…).
- En la app: `group_builder_screen.dart` (350) y `team_category_screen.dart` (992) hacen lo mismo con dos formas.
- Arreglo: M3 de `modelo-datos-migracion.md` (`entry`: un individual es una entrada de 1). Es **la mayor simplificación posible** del proyecto.

### 2. Pantallas y métodos largos
- 13 archivos Dart > 400 líneas y 8 Java > 300. 68 métodos o `build` de ≥ 60 líneas (la regla del backend dice ~30).
- Peores `build`: `settings_tab.dart` (209), `group_builder_screen.dart` (189), `draft_panel.dart` (159), `team_category_screen.dart` (126 y 4 más), `mat_board_screen.dart` (122, 108, 106, 85), `league_tab.dart` (122).
- Peores métodos Java: `EventResultsTransfer.export` y `write` (126 cada uno), `MatPlanner.simulate` (108), `EventPackageService.load` (99), `LeagueStandingsService.of` (78), `MatBoardService.board` (76), `EventService.updateSettings` (76).
- `club_models.dart` (554): 13 clases de 5 temas distintos en un archivo.

### 3. Ciclos entre features de la app
- Directos: `scoreboard ↔ mat`, `scoreboard ↔ offline`, `mat ↔ offline`, `club ↔ league`, `auth ↔ offline`.
- Contando los indirectos, **las 14 features de la app se alcanzan unas a otras**: un solo ciclo (`tools/code_metrics.py`).
- Causa: el modelo del combate (`Corner`, `MatchView`, `Side`) vive en `scoreboard`, y `offline` es infraestructura pero está como feature.
- Efecto: no se puede tocar el marcador sin arrastrar tablero y cola offline; los tests necesitan muchos fakes.

### 4. Código repetido entre app y admin
| Qué | app | admin |
|---|---|---|
| Panel de control | `control/control_ui.dart` (546) | `events/ui/event_control.dart` (504) |
| `AsyncView` | `core/async_view.dart` | `core/async_view.dart` (idéntico) |
| Diálogo de confirmar / motivo | `auth/ui/widgets/confirm_dialog.dart` | `core/confirm_dialog.dart`, `reason_dialog.dart` |
| Textos | 66 textos iguales en las ARB de app y admin; 32 + 24 repetidos con otra clave dentro de cada una |
- En admin, `events_screen` ↔ `users_screen` y `event_detail_view` ↔ `user_detail_view` repiten la estructura lista + detalle.

### 5. Cada deporte, escrito en código
- `Discipline` (enum Java) y `TamboMatch` en Java (273) y Dart (271) con las mismas reglas. Sin casos compartidos entre los dos.
- Añadir un deporte = programar en servidor y app. Choca con las plantillas creadas desde la app (`plantillas-deporte.md`).
- Consecuencia práctica: **no conviene refactorizar a fondo `TamboMatch`**; se sustituye por el motor de reglas por datos.

### 6. Errores sin código
- ~127 errores de evento en el servidor; solo 17 llevan `code`. El resto llega con un `detail` en inglés que la app no traduce: el usuario ve un error genérico.
- Arreglo: todo 4xx con `code` estable; la app traduce el código (como ya hace con `MATCH_STALE` o `MAT_HAS_GROUPS`).

### 7. Navegación
- Las pestañas del panel del club (Puntuaciones, Tapices, Inscripciones, Configuración) son estado interno, no rutas: recargar la web o volver atrás pierde la pestaña y no se puede compartir un enlace a una.
- `settings_tab.dart` mete reglas, tapices, staff, medidas, motivos y reglamento en un formulario plano (ya señalado en `eventos-ux.md`).

### 8. Base de datos
- 17 claves foráneas sin índice. Importan: `event.owner_account_id`, `league.owner_account_id`, `participant.category_id`, `fight_group.category_id`, `fight_match.red_participant_id`/`blue_participant_id`, `mat.referee_account_id`, `modality_rules.modality_id`. Las de auditoría (`created_by`, `resolved_by`…) se notan al borrar cuentas.
- 9 `drop constraint` + recrear `check` (sobre todo `admin_audit.action`): cada acción nueva pide migración.
- Columnas de reglas de `event` (`match_seconds`, `points_limit`…) siguen en la BD sin usarse (M1, se borran en M6).
- Reglas del backend sin cumplir: `updated_at` en tablas de negocio (1 columna en todo el esquema), borrado lógico de eventos (no existe) y paginación (0 `Pageable`).
- Lo demás está en el plan M2d-M6, que sigue siendo correcto.

### 9. Estructura del servidor
- `event` (33 archivos sueltos), `grouping` (29) y `scoreboard` (16) superan las ~15 que pide la regla; `auth` sí está dividido y sirve de ejemplo.
- `grouping` mezcla 4 temas: grupos, equipos, tablero del tapiz y panel de control.
- `eventpackage → demo`: el paquete depende del paquete de demostración.

### 10. Lints y accesibilidad
- Flutter usa solo `flutter_lints` por defecto: sin `strict-casts`, `strict-raw-types` ni `unawaited_futures`, con 134 `fromJson` a mano.
- 7 `Semantics` en toda la app; listas largas (Puntuaciones) se leen como un bloque (`pendientes.md`).
- Tests en 3 tamaños: solo en 15 de 54 archivos de test de front.

## Cómo repetir la medición
`python tools/code_metrics.py` (fase L0, PR #137) saca las cifras de esta página; el CI no deja que empeoren. Se repite al cerrar cada fase.
