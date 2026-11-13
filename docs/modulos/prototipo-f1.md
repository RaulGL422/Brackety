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
- Tapiz: desplegable a la derecha de "Crear grupo". Por defecto **Automático** = el de menor fin estimado (empate: número más bajo), con una línea que lo dice; o uno con árbitro elegido a mano (sin árbitro, deshabilitado). Vuelve a Automático tras crear. Popup con el tapiz asignado.
- Alumno ya agrupado: fila deshabilitada, no desaparece.
- Deshacer grupo (2026-11-11): desde el aviso tras crearlo o con el icono en un alumno o equipo agrupado, con confirmación, mientras ningún combate suyo haya empezado (`DELETE /events/{id}/groups/{groupId}`, ayudante o club; después 409 y solo el superadmin).
- **Comodín** (antes "fantasma", 2026-11-13): casilla en el grupo; con 3 seleccionados se habilitan todos los de la categoría (también los ya agrupados, salvo los del mismo grupo) y se elige 1 comodín. El comodín combate pero no puntúa; mesa gestiona sus cruces.
- Grupo = 4 en total, de 1 a 4 reales y hasta 3 fantasmas (pedido de Raul, 2026-11-12). Con la casilla marcada, quien ya tiene grupo entra como fantasma, y también el 4.º elegido.

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
- Rojo y azul fijos. Cronómetro con la duración del evento (F1: 3:00) con iniciar/parar; tiempo restante visible. El reloj lo manda el servidor (eventos con hora).
- Contador +1 y −1 (nunca por debajo de 0) por competidor y deshacer última acción.
- Con el reloj parado, ajuste ±1 s y ±10 s (evento `CLOCK_ADJUST` con `deltaMs`; ni por debajo de 0 ni por encima de la duración).
- Menú por competidor: advertencia, descalificación; en 4-8 años (F1: la categoría 5-8, siempre a dos manos; 2026-11-13) además "advertencia por golpear con una mano". Cada 2.ª advertencia y cada 2.ª de una mano (contadas aparte) dan +1 al rival automático (2026-11-13). Siempre popup de confirmación con motivo obligatorio.
- Duración y límite por formato (2026-11-13): individual 1:00 y 15; equipos 3:00 y sin límite (0). Sin límite, la descalificación da al rival 15 o sus puntos si lleva más.
- Límite de puntos o fin del tiempo → desaparece el reloj y aparece "Finalizar combate". Descalificación también finaliza y da el resultado límite–0 al rival (15-0); al deshacerla vuelven los puntos de antes.
- Campana de ring: un golpe al iniciar, tres al acabar (límite, tiempo o descalificación) y carraca de madera a los 10 s.
- Todo queda en la línea de tiempo (quién, qué, cuándo, tiempo de combate).
- Estado = repetición de los eventos (`TamboMatch`, mismo caso en Dart); deshacer es un evento más que anula el último punto, −1, ajuste de reloj, aviso o descalificación.
- 15 puntos o descalificación paran el reloj con una parada automática registrada: al deshacer, sigue parado.
- Antes del primer "Iniciar" no se puntúa: punto, advertencias y descalificación → 409 "The match has not started: press Start first." (con `opId`, choque `RULES`). Con el reloj ya iniciado y parado sí.
- "Finalizar" solo con el combate acabado; después no se acepta nada. Un combate en curso por tapiz y ningún alumno en dos a la vez. El primer "Iniciar" de un combate bloquea la fila del evento hasta acabar (como crear grupos): dos tapices que empiezan a la vez con un alumno compartido no pasan los dos.
- Escribe solo el árbitro del tapiz; el club ve el combate y su línea de tiempo.

### Puntuación global
- Alumno = 10 por asistir (estar en un grupo como real) + lo que marca en cada combate (gane o no, hasta el límite). Descalificado: 0 en ese combate y su rival el límite.
- Fantasma: no suma en ese grupo; su rival sí.

## Protecciones
- Con grupos: no cambia la fecha del evento ni el nacimiento de un alumno agrupado (cambiarían categorías); no se quita un tapiz con grupos ni se borra un alumno agrupado (409).
- Crear grupos bloquea la fila del evento: dos ayudantes a la vez no eligen tapiz con datos viejos. Un alumno solo es real en un grupo (índice único en BD).
- Descanso mínimo (2026-11-13): el marcador no deja empezar antes (`readyAt` en la vista del combate) y el servidor rechaza el START con red (409 `FIGHTER_RESTING`). Sin red se acepta tal cual al sincronizar (decisión de Raul).
- Un tapiz con combates por jugar no se queda sin árbitro en Configuración (409 `MAT_HAS_MATCHES`); a uno sin árbitro no se le asigna grupo.

### Panel de control (club y superadmin, 2026-11-13)
- Orden previsto por tapiz: el tablero enseña la cola de ese tapiz (sus combates y los de equipos que cogería), en el orden y a la hora que saldrían según `MatPlanner`; se recalcula con cada cambio. Un combate de equipos movido a mano queda fijado en ese tapiz (`pinned`) y no vuelve al bote.
- Árbitro: puede mover a otro tapiz con árbitro un combate pendiente de su cola (`POST /matches/{id}/move`; necesita red).
- Club: menú "Cambiar" en el tablero de solo lectura de cada tapiz (combate pendiente, también de equipos: mover a otro tapiz, dejar empezar sin descanso; grupo individual: mover con sus pendientes, cambiar el orden) y botón de cambiar alumno de equipo en la pestaña Equipos. Superadmin: lo mismo en el detalle del evento, auditado (`CONTROL_CHANGE`).
- Límites (servidor, `MatchControlService`): solo combates sin empezar; un grupo no se mueve con un combate en curso; solo a tapices con árbitro; el orden nombra todos los pendientes; alumnos de equipo solo si el grupo de ninguno de los dos equipos ha empezado, equipos de 2 o 3 y sin repetir persona en el grupo. Quién dejó saltar el descanso queda en el combate.

## Datos
`event` (tapices, multigrupo, duración, límite), `event_category`, `mat` (árbitro), `event_staff` (cuenta, rol `CLUB`/`GROUPER`/`REFEREE`), `participant`, `fight_group`, `group_member` (orden, fantasma), `fight_match`, `match_event` (tipo, lado, motivo, autor, hora, reloj).

## API
- `GET /api/v1/me/events` · `GET|PUT /events/{id}/settings` · `GET|POST|PUT|DELETE /events/{id}/participants` (solo CLUB: lleva nacimiento y consentimiento; el ayudante usa el de su categoría).
- `GET /events/{id}/categories` (con nº inscritos y agrupados) · `GET /events/{id}/categories/{cat}/participants`.
- `POST /events/{id}/groups` (grupo → tapiz asignado; `matId` opcional: tapiz del evento con árbitro, si no 400/409).
- `GET /events/{id}/mats` (club y ayudantes) · `GET /mats/{id}/board` (árbitro de ese tapiz y club: grupos, combates, disponible, recomendado).
- `GET /matches/{id}` · `POST /matches/{id}/events` (`START`, `STOP`, `POINT`, `WARNING`, `ONE_HAND_WARNING`, `DISQUALIFICATION`, `UNDO`, `FINISH`).
- `GET /events/{id}/standings` · `GET /events/{id}/export/{standings|matches|timeline}.csv` (club; `;` y BOM para Excel en español; celdas que empiezan por `= + - @`, tabulador o retorno se neutralizan con `'`).
- Permisos por rol y evento en servidor; el árbitro solo escribe en su tapiz.

## Pantallas
- Sesión y acceso: los de `auth` (`app/lib/features/auth/`, tarea 6); en debug, botones de acceso rápido a las cuentas demo.
- Ayudante: categorías (con inscritos/agrupados) → alumnos por nombre o estatura → grupos en borrador con color y número (nunca rojo/azul) y casilla de fantasma → popup con el tapiz. Listas en directo (aviso del evento): si otro ayudante o el superadmin agrupa a alguien del borrador, sale de él con un aviso con su nombre.
- Árbitro: tablero del tapiz (sondeo 5 s; grupos con color y número; en curso con borde e icono de reproducción; "Combate recomendado" arriba con su porqué y "Empezar este combate" (con uno en curso: "Cuando acabe el combate en curso"); luego "Otros combates disponibles", "En espera" con motivo y "Disputados"; rojo y azul con punto de color en cada combate; pendientes que esperan con candado y motivo, sin abrirse; terminados) → marcador (sondeo 2 s, reloj contado en el dispositivo y resincronizado, +1, menú de avisos con motivo, deshacer, finalizar, línea de tiempo). Sonidos generados (`app/tool/make_bell.py`); en la web con Web Audio, cargados al abrir y desbloqueados con el primer toque (antes a veces no sonaban por la política de autoplay).
- Correcciones (2026-11-12, pedido de Raul): **Cancelar combate** (empezado y sin finalizar; en el tablero junto a "Volver al marcador" y en la barra del marcador) vuelve a pendiente con todo a 0; **Reabrir combate** (finalizado, siempre visible; solo con el tapiz libre y sin luchadores ocupados) vuelve a en curso con su marcador para corregir y finalizar. Ambos con motivo, como acciones `CANCEL`/`REOPEN` en la línea de tiempo y la cola offline. Con un combate en curso el tablero no recomienda otro. En móvil vertical el número va junto al nombre. Flecha de volver sin texto (destino en el tooltip). Campana con el iPhone en silencio: sesión de audio "playback".
- Marcador (2026-11-06):
  - Vertical: reloj (16 % del alto), Iniciar o Finalizar (relleno) / Parar (con borde) y Deshacer arriba; rojo y azul debajo. Horizontal (más ancho que alto: móvil girado, tablet, escritorio): rojo | reloj y botones | azul.
  - Esquinas desactivadas hasta el primer Iniciar. Nombre en una línea (completo en tooltip y lector), número que llena el hueco; sin desbordes con texto al 200 %.
  - Reloj en color de aviso los últimos 10 s. Descalificación en color de error.
  - Deshacer bajo los botones, 48 dp: "Deshacer" y debajo qué y a qué minuto ("+1 Rojo · 0:05"); la línea de tiempo marca lo que deshará. Sin diálogo y con un aviso de 3 s.
  - Finalizado: una fila por esquina con su color y puntos; el ganador con borde, copa y "Ganador" (o "Empate").
  - Pantalla siempre encendida con el tablero o el marcador abiertos (`wakelock_plus`; en web nada).
- Sondeo (tablero, marcador, puntuaciones y tapices del club): el siguiente al acabar el anterior, nunca dos a la vez; en pausa con la app en segundo plano y sondeo inmediato al volver. La cola offline sigue enviando en segundo plano.
- Club (`app/lib/features/club/`): panel con 4 secciones (barra inferior en móvil, raíl en tablet/escritorio). Puntuaciones (sondeo 5 s, filtro por categoría, orden por puntos o nombre). Tapices (árbitro, en curso/parado, grupos, pendientes, fin estimado solo si queda algo por jugar) → tablero en solo lectura → combate ("Tapiz N · Grupo M") con marcador y línea de tiempo, sin controles. Inscripciones: alta, edición y borrado; casilla del tutor obligatoria si es menor el día del evento; chip "Falta tutor" en la lista. Configuración: nombre, fecha, duración (min:s, 0:30–20:00, no con un combate en curso) y límite de puntos (1–99, no tras empezar un combate), tapices con su árbitro (añadir/quitar el último, con confirmación), categorías solo lectura; cada cambio se guarda solo, sin botón (el nombre al dejar de escribir) y si el servidor lo rechaza vuelve el valor guardado. Exportar desde la barra (solo web): clasificación, inscritos, combates, línea de tiempo y todo el evento (.zip); importar resultados del pabellón (`servidor-local.md`). Clubes participantes en Configuración y club de cada inscrito (opcional; 409 al quitar uno con inscritos). Si hay grupos, el 409 se explica con un aviso.
- Personal (2026-11-12, pedido de Raul): en Configuración el club escribe la persona detrás de cada cuenta de ayudante o árbitro (`event_staff_name`, por evento; `PUT /events/{id}/staff/{cuenta}/name`). Se muestra "Juan Pérez (arbitro1)" en los tapices, el desplegable de árbitro y el superadmin, y quién hizo cada grupo ("por …") en el tablero, la lista del ayudante y el superadmin.

Login, inicio por rol, categorías → alumnos → crear grupos, tablero del tapiz, marcador, panel del club (config, inscripciones, puntuaciones, tapices, línea de tiempo, exportar). Responsive (`07-diseno.md`), textos i18n.

## Tests
Recomendado (empates, intercalado, fantasma ocupado), fin estimado, asignación de tapiz, fantasma, puntuación global, reglas del marcador (límite, tiempo, una mano 4-8, descalificación 15-0, −1, ajuste de reloj, deshacer); simulaciones del recomendador y del tablero con semilla fija (1-3 grupos, equipos, fantasma, alumno ocupado en otro tapiz, grupo creado a mitad); jornadas completas al azar por la API (`EventDaySimulationTest`: 3 tapices o uno sin árbitro, grupos a mitad, equipos comodín, cancelaciones, descalificaciones, deshacer grupos, árbitros que no siguen la recomendación; nadie en dos combates, descanso, ningún tapiz parado con combates de equipos libres, todo jugado una vez); deshacer grupo, permisos por rol. Widget tests de marcador, crear grupos y panel del club en 3 tamaños.

## Plan (PRs en serie hacia `development`)
1. Back: evento, categorías, tapices, staff, inscripciones, cuentas demo.
2. Back: grupos, asignación de tapiz, fantasma, combates, recomendado.
3. Back: marcador (eventos, reglas, finalizar), puntuación, CSV.
4. Front: inicio por rol, crear grupos (el login lo trae `auth`).
5. Front: tapiz, marcador, campana.
6. Front: panel del club.
7. Despliegue en la Pi (Postgres persistente del compose, URL de Raul) y ensayo con varios dispositivos.
8-11. Categorías por equipos: ver `prototipo-f1-equipos.md`.

## Despliegue en la Pi (paso 7)
Pasos generales: `09-despliegue.md`. Aquí solo lo propio del prototipo.
- Hostnames del túnel: `brackety.rgal.dev` → `http://web:80` y `brackety-api.rgal.dev` → `http://api:8080`. `brackety-admin.rgal.dev` → `http://admin:80` solo cuando haya Cloudflare Access (el prototipo no usa superadmin). Un solo nivel de subdominio: el SSL gratuito de Cloudflare no cubre `api.brackety.rgal.dev`.
- Imágenes: release `v0.3.0` (PR `release/v0.3.0` → `main` con merge commit y tag); el CI publica `ghcr.io/raulgl422/brackety-*` arm64. Las variables de repo `API_BASE_URL` y `ADMIN_API_BASE_URL` ya están puestas.
- `.env` (además de lo obligatorio: `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`, `CLOUDFLARE_TUNNEL_TOKEN`):
  - `IMAGE_TAG=0.3.0`, `CORS_ALLOWED_ORIGINS=https://brackety.rgal.dev`, `PUBLIC_BASE_URL=https://brackety.rgal.dev`.
  - `API_PORT=38080`, `WEB_PORT=38081`, `ADMIN_PORT=38082`: en la Pi de Raul 8080-8082 los usa otra app. El túnel no los usa (va por la red de Docker).
  - `API_BASE_URL=https://brackety-api.rgal.dev`, `ADMIN_API_BASE_URL=https://brackety-admin.rgal.dev`.
  - `DEMO_ACCOUNTS_ENABLED=true`, `DEMO_EVENT_DATE=2026-11-14`: crea las cuentas y el evento sin alumnos (los inscribe el club).
  - Vacías: Resend (emails al log), Google, superadmin y Cloudflare Access.
- Sin SSD: `DB_DATA=pgdata` (volumen en la SD; aceptado por Raul para la F1). Copia al acabar cada jornada, bajada al PC:
  - Pi: `docker compose exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" -d brackety -Fc' > ~/brackety-$(date +%F).dump`.
  - PC: `scp <usuario>@<pi>:~/brackety-<fecha>.dump .` (no `ssh … >` en PowerShell: estropea el binario).
- Accesos de la Pi: clave de despliegue SSH de solo lectura (alias `github-brackety` en `~/.ssh/config`) y `docker login ghcr.io` con un token classic solo `read:packages`.
- Ensayo: móvil y tablet con datos móviles (fuera de la wifi de casa), una cuenta por rol, un combate completo con campana y el CSV.

## Estado
En curso desde 2026-10-30.
