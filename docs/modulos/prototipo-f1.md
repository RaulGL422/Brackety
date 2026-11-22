# Módulo · prototipo-f1 (Liga Yoseikan, Fase 1)

## Objetivo
Usar Brackety en la **Fase 1 real** (≈ 2026-11-14): inscripciones, grupos, tapices, marcador de Tambo, tiempo y puntuación global. Son versiones mínimas de los módulos reales (`eventos`, `inscripciones`, `ayudantes-permisos`, `liga-fases`, `marcador-tapiz`, `ranking`), no código desechable: el código vive en sus carpetas de feature y cada módulo crecerá desde aquí.

Fuera de alcance: offline, WebSocket (se usa sondeo), QR, invitaciones, pagos, fotos, Android nativo (se usa la web en móvil/tablet), varias fases.

## Cuentas (riesgo aceptado por Raul)
- Usuario = contraseña, sin email real: `club1`; `ayudante1`, `ayudante2`; `arbitro1`…`arbitro5` (la F1 usa 3 tapices: se quitan el 4 y el 5 en Configuración).
- Solo se crean si `DEMO_ACCOUNTS_ENABLED=true`; ya verificadas. El bloqueo por intentos y el limitador siguen activos.
- Se borran tras la fase (pendiente: quitar la variable y purgar).

## Reglas
### Club
- Configura el evento: nº de tapices, árbitro de cada tapiz. Sin multigrupo (2026-11-07): un grupo cada vez.
- Inscribe alumnos de la fase: nombre, apellidos, nacimiento, estatura (cm). Menor sin cuenta: casilla "el tutor está de acuerdo" obligatoria (`06-legal-rgpd.md`).
- Ve en directo: puntuación por alumno (filtros por categoría, orden por nombre o puntos), tapices con sus grupos y fin estimado, línea de tiempo de cada combate.
- Exporta CSV al final (clasificación y combates).

### Categorías
- Por edad el día del evento, configurables por evento (nombre, edad mín./máx.). **Ficticias** hasta confirmar: tramos del ranking, mixtas.
- Ordenadas de más jóvenes a mayores.

### Ayudante (crear grupos)
- Lista de categorías con inscritos → alumnos ordenados por nombre; botón para ordenar por estatura.
- Selecciona 4 alumnos (casilla marcada) → "Crear grupo".
- Tapiz: desplegable a la derecha de "Crear grupo". Por defecto **Automático** = el de menor fin estimado (empate: número más bajo), con una línea que lo dice; o uno en uso elegido a mano, tenga ya árbitro o no (inhabilitado, deshabilitado; Raul, 2026-11-22). Vuelve a Automático tras crear. Popup con el tapiz asignado.
- Alumno ya agrupado: fila deshabilitada, no desaparece.
- Deshacer grupo (2026-11-11): desde el aviso tras crearlo o con el icono en un alumno o equipo agrupado, con confirmación, mientras ningún combate suyo haya empezado (`DELETE /events/{id}/groups/{groupId}`, ayudante o club; después 409 y solo el superadmin).
- **Comodín** (antes "fantasma", 2026-11-13): casilla en el grupo; con 3 seleccionados se habilitan todos los de la categoría (también los ya agrupados, salvo los del mismo grupo) y se elige 1 comodín. El comodín combate pero no puntúa; mesa gestiona sus cruces.
- Grupo = 4 en total, de 1 a 4 reales y hasta 3 fantasmas (pedido de Raul, 2026-11-12). Con la casilla marcada, quien ya tiene grupo entra como fantasma, y también el 4.º elegido. Además, «Añadir como: Normal | Comodín» elige el papel del siguiente toque, en cualquier orden (F1-2, 2026-11-16: un comodín elegido primero se guardaba como normal); con 3 reales o 3 comodines el papel del 4.º queda fijo.

### Fin estimado de un tapiz
- Restante = reloj del combate en curso + pendientes × (duración + 30 s); sin combate en curso, solo lo que quede de los 30 s tras el último.
- Fin = ahora + restante: si el tapiz está parado, el fin se retrasa solo.

### Árbitro (tapiz)
- Solo su tapiz. Ve sus grupos, los combates disponibles y el **recomendado**.
- Orden del grupo = orden en que el ayudante seleccionó (fantasma al final). Nórdico de 4: 1-2, 3-4, 1-3, 2-4, 1-4, 2-3 (rojo el primero).
- Recomendado (`MatchRecommender`), por pasos:
  1. Fuera los combates con alguien combatiendo ahora en cualquier tapiz (comodín ocupado: se ve, no está disponible) o sin el **descanso mínimo** desde su último combate en cualquier tapiz (30 s por defecto, "Descanso mínimo" en Configuración; sale "Descansando hasta las …").
  2. Si hay alternativa, fuera los que repiten alumno del combate recién acabado en el tapiz.
  3. Primero los que tienen más alumnos sin combatir todavía.
  4. Mayor suma de descanso de los dos (desde su último combate o desde que se creó el grupo); sumas a menos de un hueco (2:00 + 30 s) cuentan como iguales.
  5. Empate: el grupo que lleva más sin combatir en el tapiz (así se intercalan: G1 1-2, G2 1-2, G1 3-4, G2 3-4…), luego nº de grupo y orden.

### Marcador Tambo
En `prototipo-f1-marcador-pantallas.md`.

### Puntuación global
- Alumno = 10 por asistir (estar en un grupo como real) + lo que marca en cada combate (gane o no, hasta el límite). Descalificado: 0 en ese combate y su rival el límite.
- Fantasma: no suma en ese grupo; su rival sí.
- Ficha del alumno (club, 2026-11-14): junto a los puntos, sus advertencias (y descalificaciones); al desplegar, cada una con combate, minuto, motivo y árbitro, y abre el combate. Solo las que siguen en pie (sin deshacer ni anteriores a una cancelación). Desde la fase, las de la fase; desde la liga, las de todas sus fases agrupadas (`GET /events/{id}/league/people/{personId}/record`; `incidents` en cada combate del record).

## Protecciones
- Con grupos: no cambia la fecha del evento ni el nacimiento de un alumno agrupado (cambiarían categorías); no se quita un tapiz con grupos ni se borra un alumno agrupado (409).
- Crear grupos bloquea la fila del evento: dos ayudantes a la vez no eligen tapiz con datos viejos. Un alumno solo es real en un grupo (índice único en BD).
- Descanso mínimo (2026-11-13): el marcador no deja empezar antes (`readyAt` en la vista del combate) y el servidor rechaza el START con red (409 `FIGHTER_RESTING`). Sin red se acepta tal cual al sincronizar (decisión de Raul).
- Un tapiz con combates por jugar no se queda sin árbitro en Configuración (409 `MAT_HAS_MATCHES`); uno sin árbitro sí recibe grupos (los disputa cuando llegue su árbitro); solo uno inhabilitado no (409 `MAT_DISABLED`).

### Panel de control (club y superadmin, 2026-11-13)
- Orden previsto por tapiz: el tablero enseña la cola de ese tapiz (sus combates y los de equipos que cogería), en el orden y a la hora que saldrían según `MatPlanner`; se recalcula con cada cambio. Un combate de equipos movido a mano queda fijado en ese tapiz (`pinned`) y no vuelve al bote.
- Árbitro: puede mover a otro tapiz en uso un combate pendiente de su cola (`POST /matches/{id}/move`; necesita red).
- Club: menú "Cambiar" en el tablero de solo lectura de cada tapiz (combate pendiente, también de equipos: mover a otro tapiz, dejar empezar sin descanso; grupo individual: mover con sus pendientes, cambiar el orden) y botón de cambiar alumno de equipo en la pestaña Equipos. Superadmin: lo mismo en el detalle del evento, auditado (`CONTROL_CHANGE`).
- Inhabilitar tapiz (2026-11-14, club en su tablero y superadmin; `POST /control/mats/{id}/disable`): cada grupo individual con pendientes va al tapiz elegido o, en Automático, al de menor fin estimado; los de equipos fijados ahí vuelven al bote; se queda sin árbitro, así que el reparto y la previsión de equipos lo ignoran. No con un combate en curso o en revisión, ya inhabilitado (`MAT_DISABLED`) ni sin otro tapiz en uso (`NO_OTHER_MAT`) (409). Desde el 2026-11-16 (F1-1) guarda cuándo y qué árbitro tenía (`mat.disabled_at`, `disabled_referee_account_id`): la pestaña Tapices del club lo enseña atenuado («Inhabilitado desde las…», su árbitro) con «Inhabilitar tapiz» a la vista en cada tapiz en uso y «Reactivar tapiz» en el inhabilitado (`POST /control/mats/{id}/enable`, también en el superadmin: le devuelve su árbitro; 409 si ese árbitro ya no es del evento o está en otro tapiz). Asignarle árbitro en Configuración también lo reactiva.
- Sincronizando combates (2026-11-14): tras cambiar los tapices (uno más o menos, un árbitro, uno inhabilitado), cada tablero avisa qué tapices aún no han cargado el cambio (`syncingMats`; un minuto como mucho) y vuelve a preguntar cada 3 s. No bloquea nada.
- Límites (servidor, `MatchControlService`): solo combates sin empezar; un grupo no se mueve con un combate en curso; solo a tapices en uso (no inhabilitados), con árbitro o sin él; el orden nombra todos los pendientes; alumnos de equipo solo si el grupo de ninguno de los dos equipos ha empezado, equipos de 2 o 3 y sin repetir persona en el grupo. Quién dejó saltar el descanso queda en el combate.

## Datos
`event` (tapices, multigrupo, duración, límite), `event_category`, `mat` (árbitro), `event_staff` (cuenta, rol `CLUB`/`GROUPER`/`REFEREE`), `participant`, `fight_group`, `group_member` (orden, fantasma), `fight_match`, `match_event` (tipo, lado, motivo, autor, hora, reloj).

## API
- `GET /api/v1/me/events` · `GET|PUT /events/{id}/settings` · `GET|POST|PUT|DELETE /events/{id}/participants` (solo CLUB: lleva nacimiento y consentimiento; el ayudante usa el de su categoría).
- `GET /events/{id}/categories` (con nº inscritos y agrupados) · `GET /events/{id}/categories/{cat}/participants`.
- `POST /events/{id}/groups` (grupo → tapiz asignado; `matId` opcional: tapiz del evento no inhabilitado, si no 400/409 `MAT_DISABLED`).
- `GET /events/{id}/mats` (club y ayudantes) · `GET /mats/{id}/board` (árbitro de ese tapiz y club: grupos, combates, disponible, recomendado).
- `GET /matches/{id}` · `POST /matches/{id}/events` (`START`, `STOP`, `POINT`, `WARNING`, `ONE_HAND_WARNING`, `DISQUALIFICATION`, `UNDO`, `FINISH`).
- `GET /events/{id}/standings` · `GET /events/{id}/export/{standings|matches|timeline}.csv` (club; `;` y BOM para Excel en español; celdas que empiezan por `= + - @`, tabulador o retorno se neutralizan con `'`).
- Permisos por rol y evento en servidor; el árbitro solo escribe en su tapiz.

## Pantallas
En `prototipo-f1-marcador-pantallas.md`.

## Tests
Recomendado (empates, intercalado, fantasma ocupado), fin estimado, asignación de tapiz, fantasma, puntuación global, reglas del marcador (límite, tiempo, una mano 4-8, descalificación 15-0, −1, ajuste de reloj, deshacer); simulaciones del recomendador y del tablero con semilla fija (1-3 grupos, equipos, fantasma, alumno ocupado en otro tapiz, grupo creado a mitad); jornadas completas al azar por la API (`EventDaySimulationTest`: 3 tapices o uno inhabilitado, grupos a mitad, equipos comodín, cancelaciones, descalificaciones, deshacer grupos, árbitros que no siguen la recomendación; nadie en dos combates, descanso, ningún tapiz parado con combates de equipos libres, todo jugado una vez); deshacer grupo, permisos por rol. Widget tests de marcador, crear grupos y panel del club en 3 tamaños.

## Estado
Usado en la Fase 1 real (2026-11-14) con éxito. Pasos 1-7 hechos (back, front y despliegue en la Pi); los de equipos (8-11), en `prototipo-f1-equipos.md`. Lo propio de la Pi está en `entornos.md`. Lo que queda abierto pasa a los módulos reales (`eventos`, `puntuacion`, `liga-fases`, `marcador-tapiz`) con el plan de limpieza (`../producto/plan-limpieza.md`).
