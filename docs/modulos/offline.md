# Módulo · offline

## Objetivo
Que el ayudante siga trabajando sin internet y no se pierda ningún dato.

## Reglas
- Disponible para todo ayudante en app y web (PWA).
- **Un único escritor por tapiz** a la vez, con traspaso explícito. Así no hay fusión de conflictos.
- Antes de empezar, el ayudante descarga **solo lo suyo**: su evento, su tapiz, sus grupos, combates y alumnos (con foto si tiene permiso).
- Los cambios se guardan en una base local (drift/SQLite; en web IndexedDB) con cola de operaciones y marca de tiempo.
- Al recuperar la red, sincroniza en orden; el servidor valida y registra un log de importación.
- Si hay choque inesperado (dos dispositivos escribieron): se detiene la sincronización de ese combate y se pide revisión manual al organizador.
- **Exportar a CSV** desde el dispositivo con versión de esquema; el ayudante o el dueño del evento pueden **importarlo** después.
- Idempotencia: cada operación tiene id único para que reimportar no duplique.
- Los datos locales se borran al finalizar la sincronización y al cerrar sesión.
- Datos personales en el dispositivo: mínimo, y sin fotos si no hay permiso.

## Adelanto F1 (marcador del árbitro)
Pedido por Raul el 2026-11-04 para la Fase 1. Solo APK Android (la web por http no puede guardar offline).
- Si se corta la red, el árbitro sigue con el combate en curso y puede empezar otros de su tapiz con lo último descargado.
- Sin red no hay recomendado (no se sabe quién combate en otros tapices): lista de pendientes y aviso de "sin conexión".
- Cada acción se guarda en el dispositivo con id único y reloj del combate; el reloj lo lleva el dispositivo mientras no hay red.
- Al volver la red se envían en orden; el servidor las acepta una vez (idempotentes) y recalcula el combate.
- Choque (otro dispositivo escribió el mismo combate, o un alumno quedó en dos combates a la vez): se para ese combate y el club lo revisa.
- Indicador visible: conectado / sin conexión / N acciones pendientes.
- Choque: el club elige **aplicar** las acciones del móvil o **descartarlas** (decidido por Raul el 2026-11-05).

### Servidor (contrato)
- `POST /matches/{id}/events` acepta además `opId` (UUID del dispositivo), `at` (hora de la acción) y `knownEvents` (acciones no automáticas que el dispositivo conocía antes de esta). Sin `opId` funciona como hoy (web).
- Con `opId`:
  - **Idempotente**: si ya se aplicó ese `opId`, devuelve 200 con el combate actual y no escribe nada.
  - **Hora**: `at` hace de "ahora" para esa acción: reglas, reloj y fin por tiempo. Si es posterior a la hora del servidor, se usa la del servidor; si es anterior a la última acción del combate, se usa esa.
  - **Choque**: el combate pasa a "en revisión" y la acción se guarda como rechazada, con 409 `MATCH_CONFLICT`. Hay choque si las acciones no automáticas del servidor no coinciden con `knownEvents`, si lo rechazan las reglas del marcador o si falla al empezar (otro combate en el tapiz o alumno combatiendo en otro).
  - Combate en revisión: toda acción con `opId` se guarda como rechazada (409 `MATCH_IN_REVIEW`). Sin `opId`, 409.
- Rechazadas en `offline_rejected_op`:
  - campos: combate, `opId`, tipo, lado, motivo, `at`, autor, recibida, código del motivo;
  - resolución: aplicada o descartada, quién y cuándo.
  - No se borran: son el log de importación.
- `GET /matches/{id}` y el tablero del tapiz devuelven `review` (motivo y acciones rechazadas en orden), o null.
- `POST /matches/{id}/review` `{action: APPLY|DISCARD}`, solo CLUB del evento:
  - **APPLY**: añade las rechazadas en orden con su `at` y sin comprobar `knownEvents` ni el alumno en otro tapiz; las que las reglas rechacen se saltan y se cuentan.
  - **DISCARD**: no aplica ninguna.
  - Las dos quitan "en revisión" y dejan la resolución en cada fila.
- La respuesta del marcador lleva la hora del servidor (`serverTime`), que la app usa para corregir el reloj del dispositivo.

### Servidor: forma exacta (hecho el 2026-11-05)
- Petición: `{"type":"POINT","side":"RED","reason":null,"opId":"<uuid>","at":"2027-03-10T09:00:30Z","knownEvents":3}`. `at` en ISO-8601 UTC; sin `at` vale la hora del servidor. Con `opId` y sin `knownEvents` (o negativo): 400.
- 409 en `application/problem+json` con `code`: `MATCH_CONFLICT` (primera) o `MATCH_IN_REVIEW` (siguientes, y la web con el combate en revisión).
- Reintento de un `opId` rechazado: el mismo 409 y código, aunque el club ya lo haya revisado. Uno aplicado: 200.
- Con `opId`, el aviso de una mano a quien no tiene 4-7 años también es choque (en la web sigue siendo 400).
- Vista (`GET /matches/{id}`, `POST .../events`, `match` de `/review`):
  - `serverTime` (Instant); `remainingMs`, `running` y `endReason` están calculados a esa hora.
  - `review`: null o `{"reason","ops":[{"opId","type","side","reason","actor","at","receivedAt","cause"}]}`.
  - `review.reason`: `KNOWN_EVENTS`, `RULES`, `AGE`, `MAT_BUSY` o `FIGHTER_BUSY`. `cause` de cada op: lo mismo o `IN_REVIEW`. `ops[].reason`: el motivo del aviso; `actor`: usuario del árbitro.
- Tablero (`GET /mats/{id}/board`): cada combate lleva `inReview` (bool); en revisión, `available` es false y nunca es el recomendado. No lleva `review`: se ve al abrir el combate.
- Tapices (`GET /events/{id}/mats`): `matchesInReview` (int) por tapiz.
- `/review` responde `{"match":<vista>,"applied":2,"skipped":1}`. Sin revisión: 409 `MATCH_NOT_IN_REVIEW`. Sin token 401, árbitro y ayudante 403, ajeno 404.
- Resolución de cada fila: `APPLIED`, `SKIPPED` (al aplicar, las reglas la rechazaron) o `DISCARDED`. La hora de recepción es `created_at`.

### App (APK)
- Todas las acciones del árbitro pasan por una cola local, también con red: id único, `at` = hora del dispositivo corregida con la última `serverTime` y `knownEvents`. Con red se envía al momento.
- La cola se envía en orden, una acción a la vez:
  - 200: la acción sale de la cola.
  - Error de red: reintenta más tarde.
  - 409: ese combate muestra "en revisión del club"; sus acciones salen de la cola, porque el servidor ya las guarda.
- El estado del combate = la última vista del servidor + las acciones pendientes, con las reglas del marcador repetidas en Dart (mismos casos que `TamboMatch`).
- Caché en ficheros JSON del dispositivo (no drift para la F1): último tablero del tapiz, combates abiertos y cola. Se borra al cerrar sesión.
- Sin red, el tablero sale de la caché, sin recomendado y con aviso. Se puede empezar un pendiente si en el tapiz no hay otro en curso.
- La web no cambia (sin cola ni caché).
- Club: el combate en revisión se marca en Tapices. Al abrirlo muestra lo que traía el móvil (quién, qué, cuándo) y los botones Aplicar y Descartar, con confirmación.

## Datos
`offline_op` (cliente), `import_log` (servidor), formato CSV versionado.

## Pantallas
Estado de conexión, descarga previa, cola pendiente, exportar/importar CSV, resolución de choques.

## Tests
Sin red → operaciones → sincronización; idempotencia; CSV round trip; choque de dos escritores; traspaso de tapiz.
- Servidor F1 (`ScoreboardOfflineTest`, `ScoreboardReviewControllerTest`): con `opId` igual que sin él; reintentos sin duplicar (200 y 409); `at` recortado a ahora y subido a la última acción; combate jugado offline y fin por tiempo con los `at`; `knownEvents` distinto, alumno en otro tapiz y siguientes en revisión; web en revisión; paradas automáticas fuera de `knownEvents`; APPLY en orden saltando las que no valen y finalizando; DISCARD; permisos de `/review`, `serverTime`, `review`, tablero y códigos del problem+json.

## Estado
Pendiente; adelanto F1 en curso (2026-11-05, rama `feat/offline-f1-scoreboard`: back y luego app, una PR). Más casos se afinarán en la construcción.
