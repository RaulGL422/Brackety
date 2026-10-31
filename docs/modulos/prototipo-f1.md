# Módulo · prototipo-f1 (Liga Yoseikan, Fase 1)

## Objetivo
Usar Brackety en la **Fase 1 real** (≈ 2026-11-14): inscripciones, grupos, tapices, marcador de Tambo, tiempo y puntuación global. Son versiones mínimas de los módulos reales (`eventos`, `inscripciones`, `ayudantes-permisos`, `liga-fases`, `marcador-tapiz`, `ranking`), no código desechable: el código vive en sus carpetas de feature y cada módulo crecerá desde aquí.

Fuera de alcance: offline, WebSocket (se usa sondeo), QR, invitaciones, pagos, fotos, Android nativo (se usa la web en móvil/tablet), varias fases.

## Cuentas (riesgo aceptado por Raul)
- Usuario = contraseña, sin email real: `club1`; `ayudante1`, `ayudante2`; `arbitro1`…`arbitro5`.
- Solo se crean si `DEMO_ACCOUNTS_ENABLED=true`; ya verificadas. El bloqueo por intentos y el limitador siguen activos.
- Se borran tras la fase (pendiente: quitar la variable y purgar).

## Reglas
### Club
- Configura el evento: nº de tapices, árbitro de cada tapiz, máximo de grupos por tapiz a la vez (1 = sin multigrupo).
- Inscribe alumnos de la fase: nombre, apellidos, nacimiento, estatura (cm). Menor sin cuenta: casilla "el tutor está de acuerdo" obligatoria (`06-legal-rgpd.md`).
- Ve en directo: puntuación por alumno (filtros por categoría, orden por nombre o puntos), tapices con sus grupos y fin estimado, línea de tiempo de cada combate.
- Exporta CSV al final (clasificación y combates).

### Categorías
- Por edad el día del evento, configurables por evento (nombre, edad mín./máx.). **Ficticias** hasta confirmar: tramos del ranking, mixtas.
- Ordenadas de más jóvenes a mayores.

### Ayudante (crear grupos)
- Lista de categorías con inscritos → alumnos ordenados por nombre; botón para ordenar por estatura.
- Selecciona 4 alumnos → "Crear grupo". Con multigrupo: va formando grupo 1, 2… (color/número por grupo) y "Crear grupos" los manda todos al mismo tapiz.
- Tapiz elegido: el de **menor fin estimado** (empate: número más bajo). Popup con el tapiz asignado.
- Alumno ya agrupado: fila deshabilitada, no desaparece.
- **Competidor fantasma**: casilla en el grupo; con 3 seleccionados se habilitan todos los de la categoría (también los ya agrupados, salvo los del mismo grupo) y se elige 1 fantasma. El fantasma combate pero no puntúa; mesa gestiona sus cruces.
- Grupo = 4 reales, o 3 reales + 1 fantasma; ningún otro tamaño.

### Fin estimado de un tapiz
- Restante = reloj del combate en curso + pendientes × (2:00 + 30 s); sin combate en curso, solo lo que quede de los 30 s tras el último.
- Fin = ahora + restante: si el tapiz está parado, el fin se retrasa solo.

### Árbitro (tapiz)
- Solo su tapiz. Ve sus grupos, los combates disponibles y el **recomendado**.
- Orden del grupo = orden en que el ayudante seleccionó (fantasma al final). Nórdico de 4: 1-2, 3-4, 1-3, 2-4, 1-4, 2-3 (rojo el primero).
- Recomendado (`MatchRecommender`), por pasos:
  1. Fuera los combates con alguien combatiendo ahora en cualquier tapiz (fantasma ocupado: se ve, no está disponible).
  2. Si hay alternativa, fuera los que repiten alumno del combate recién acabado en el tapiz.
  3. Primero los que tienen más alumnos sin combatir todavía.
  4. Mayor suma de descanso de los dos (desde su último combate o desde que se creó el grupo); sumas a menos de un hueco (2:00 + 30 s) cuentan como iguales.
  5. Empate: el grupo que lleva más sin combatir en el tapiz (así se intercalan: G1 1-2, G2 1-2, G1 3-4, G2 3-4…), luego nº de grupo y orden.

### Marcador Tambo
- Rojo y azul fijos. Cronómetro 2:00 con iniciar/parar; tiempo restante visible. El reloj lo manda el servidor (eventos con hora).
- Contador +1 por competidor y deshacer última acción.
- Menú por competidor: advertencia, descalificación; en 4-7 años además "advertencia por golpear con una mano" (a la 2.ª, +1 al rival automático). Siempre popup de confirmación con motivo obligatorio.
- 15 puntos o fin del tiempo → desaparece el reloj y aparece "Finalizar combate". Descalificación también finaliza.
- Campana al iniciar el tiempo y al acabar (límite, tiempo o descalificación).
- Todo queda en la línea de tiempo (quién, qué, cuándo, tiempo de combate).
- Estado = repetición de los eventos (`TamboMatch`); deshacer es un evento más que anula el último punto, aviso o descalificación.
- 15 puntos o descalificación paran el reloj con una parada automática registrada: al deshacer, sigue parado.
- "Finalizar" solo con el combate acabado; después no se acepta nada. Un combate en curso por tapiz y ningún alumno en dos a la vez.
- Escribe solo el árbitro del tapiz; el club ve el combate y su línea de tiempo.

### Puntuación global
- Alumno = 10 por asistir (estar en un grupo como real) + lo que marca en cada combate (gane o no, hasta 15). Descalificado: 0 en ese combate.
- Fantasma: no suma en ese grupo; su rival sí.

## Protecciones
- Con grupos: no cambia la fecha del evento ni el nacimiento de un alumno agrupado (cambiarían categorías); no se quita un tapiz con grupos ni se borra un alumno agrupado (409).
- Crear grupos bloquea la fila del evento: dos ayudantes a la vez no eligen tapiz con datos viejos. Un alumno solo es real en un grupo (índice único en BD).

## Datos
`event` (tapices, multigrupo, duración, límite), `event_category`, `mat` (árbitro), `event_staff` (cuenta, rol `CLUB`/`GROUPER`/`REFEREE`), `participant`, `fight_group`, `group_member` (orden, fantasma), `fight_match`, `match_event` (tipo, lado, motivo, autor, hora, reloj).

## API
- `GET /api/v1/me/events` · `GET|PUT /events/{id}/settings` · `GET|POST|PUT|DELETE /events/{id}/participants`.
- `GET /events/{id}/categories` (con nº inscritos y agrupados) · `GET /events/{id}/categories/{cat}/participants`.
- `POST /events/{id}/groups` (uno o varios grupos → tapiz asignado).
- `GET /events/{id}/mats` (club y ayudantes) · `GET /mats/{id}/board` (árbitro de ese tapiz y club: grupos, combates, disponible, recomendado).
- `GET /matches/{id}` · `POST /matches/{id}/events` (`START`, `STOP`, `POINT`, `WARNING`, `ONE_HAND_WARNING`, `DISQUALIFICATION`, `UNDO`, `FINISH`).
- `GET /events/{id}/standings` · `GET /events/{id}/export/{standings|matches|timeline}.csv` (club; `;` y BOM para Excel en español; celdas que empiezan por `= + - @` se neutralizan).
- Permisos por rol y evento en servidor; el árbitro solo escribe en su tapiz.

## Pantallas
- Sesión provisional (`app/lib/features/session/`): login real contra `/auth/login`, acceso en memoria, refresh por la cookie web y un reintento automático tras un 401; recarga de página = sesión recuperada. En debug, botones de acceso rápido a las cuentas demo. Las pantallas de `auth` sustituirán la de acceso.
- Ayudante: categorías (con inscritos/agrupados) → alumnos por nombre o estatura → grupos en borrador con color y número (nunca rojo/azul) y casilla de fantasma → popup con el tapiz.
- Árbitro: tablero del tapiz (sondeo 5 s; grupos con color y número, recomendado, en curso, pendientes con motivo si esperan, terminados) → marcador (sondeo 2 s, reloj contado en el dispositivo y resincronizado, +1, menú de avisos con motivo, deshacer, finalizar, línea de tiempo). Campana generada (`app/tool/make_bell.py`), una vez al iniciar y una al acabar.
- Club (`app/lib/features/club/`): panel con 4 secciones (barra inferior en móvil, raíl en tablet/escritorio). Puntuaciones (sondeo 5 s, filtro por categoría, orden por puntos o nombre). Tapices (árbitro, en curso/parado, grupos, pendientes, fin estimado) → tablero en solo lectura → combate con marcador y línea de tiempo, sin controles. Inscripciones: alta, edición y borrado; casilla del tutor obligatoria si es menor el día del evento. Configuración: nombre, fecha, multigrupo 1-4, tapices con su árbitro (añadir/quitar el último), categorías solo lectura. Exportar los 3 CSV desde la barra (solo web). Si hay grupos, el 409 se explica con un aviso.

Login, inicio por rol, categorías → alumnos → crear grupos, tablero del tapiz, marcador, panel del club (config, inscripciones, puntuaciones, tapices, línea de tiempo, exportar). Responsive (`07-diseno.md`), textos i18n.

## Tests
Recomendado (empates, intercalado, fantasma ocupado), fin estimado, asignación de tapiz, fantasma, puntuación global, reglas del marcador (15, tiempo, una mano 4-7, descalificación, deshacer), permisos por rol. Widget tests de marcador, crear grupos y panel del club en 3 tamaños.

## Plan (PRs en serie hacia `development`)
1. Back: evento, categorías, tapices, staff, inscripciones, cuentas demo.
2. Back: grupos, asignación de tapiz, fantasma, combates, recomendado.
3. Back: marcador (eventos, reglas, finalizar), puntuación, CSV.
4. Front: inicio por rol, crear grupos (el login lo trae `auth`).
5. Front: tapiz, marcador, campana.
6. Front: panel del club.
7. Despliegue en la Pi (Postgres persistente del compose, URL de Raul) y ensayo con varios dispositivos.

## Estado
En curso desde 2026-10-30.
