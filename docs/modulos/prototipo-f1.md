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
- Restante = tiempo del combate en curso + combates pendientes × (2:00 + 30 s de cambio).
- Fin = ahora + restante: si el tapiz está parado, el fin se retrasa solo.

### Árbitro (tapiz)
- Solo su tapiz. Ve sus grupos, los combates disponibles y el **recomendado**.
- Recomendado: mayor suma del tiempo sin combatir de los dos alumnos (desde su último combate o desde la creación del grupo). Empate: primero alumnos que aún no han combatido y se intercala entre grupos (G1 1-2, G2 1-2, G1 3-4, G2 3-4…). Orden base del nórdico de 4: 1-2, 3-4, 1-3, 2-4, 1-4, 2-3. Nunca un alumno dos seguidos si hay alternativa. Algoritmo puro con tests.
- Fantasma ocupado en otro tapiz: su combate se muestra pero no se recomienda.

### Marcador Tambo
- Rojo y azul fijos. Cronómetro 2:00 con iniciar/parar; tiempo restante visible. El reloj lo manda el servidor (eventos con hora).
- Contador +1 por competidor y deshacer última acción.
- Menú por competidor: advertencia, descalificación; en 4-7 años además "advertencia por golpear con una mano" (a la 2.ª, +1 al rival automático). Siempre popup de confirmación con motivo obligatorio.
- 15 puntos o fin del tiempo → desaparece el reloj y aparece "Finalizar combate". Descalificación también finaliza.
- Campana al iniciar el tiempo y al acabar (límite, tiempo o descalificación).
- Todo queda en la línea de tiempo (quién, qué, cuándo, tiempo de combate).

### Puntuación global
- Alumno = 10 por asistir (estar en un grupo como real) + lo que marca en cada combate (gane o no, hasta 15). Descalificado: 0 en ese combate.
- Fantasma: no suma en ese grupo; su rival sí.

## Datos
`event` (tapices, multigrupo, duración, límite), `event_category`, `mat` (árbitro), `event_staff` (cuenta, rol `CLUB`/`GROUPER`/`REFEREE`), `participant`, `fight_group`, `group_member` (orden, fantasma), `match`, `match_event` (tipo, lado, motivo, autor, hora, reloj).

## API
- `GET /api/v1/me/events` · `GET|PUT /events/{id}/settings` · `GET|POST|PUT|DELETE /events/{id}/participants`.
- `GET /events/{id}/categories` (con nº inscritos y agrupados) · `GET /events/{id}/categories/{cat}/participants`.
- `POST /events/{id}/groups` (uno o varios grupos → tapiz asignado).
- `GET /mats/{id}/board` (grupos, combates, recomendado) · `GET /matches/{id}` · `POST /matches/{id}/events` · `POST /matches/{id}/finish`.
- `GET /events/{id}/standings` · `GET /events/{id}/mats` (fin estimado) · `GET /events/{id}/export/{standings|matches}.csv`.
- Permisos por rol y evento en servidor; el árbitro solo escribe en su tapiz.

## Pantallas
Login, inicio por rol, categorías → alumnos → crear grupos, tablero del tapiz, marcador, panel del club (config, inscripciones, puntuaciones, tapices, línea de tiempo, exportar). Responsive (`07-diseno.md`), textos i18n.

## Tests
Recomendado (empates, intercalado, fantasma ocupado), fin estimado, asignación de tapiz, fantasma, puntuación global, reglas del marcador (15, tiempo, una mano 4-7, descalificación, deshacer), permisos por rol. Widget tests de marcador y crear grupos en 3 tamaños.

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
