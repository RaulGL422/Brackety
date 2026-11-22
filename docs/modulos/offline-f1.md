# offline · adelanto de la F1 (marcador, web y CSV)

Parte de `offline.md`, que sigue siendo el doc del módulo.

## Adelanto F1 (marcador del árbitro)
Pedido por Raul el 2026-11-04 para la Fase 1. Desde el 2026-11-11 también (y sobre todo) en la web: ver "Web (2026-11-11)".
- Si se corta la red, el árbitro sigue con el combate en curso y puede empezar otros de su tapiz con lo último descargado.
- Sin red no hay recomendado (no se sabe quién combate en otros tapices): lista de pendientes y aviso de "sin conexión".
- Cada acción se guarda en el dispositivo con id único y reloj del combate; el reloj lo lleva el dispositivo mientras no hay red.
- Al volver la red se envían en orden; el servidor las acepta una vez (idempotentes) y recalcula el combate.
- Choque (otro dispositivo escribió el mismo combate, o un alumno quedó en dos combates a la vez): se para ese combate y el club lo revisa.
- Indicador visible: conectado / sin conexión / N acciones pendientes.
- Choque: el club elige **aplicar** las acciones del móvil o **descartarlas** (decidido por Raul el 2026-11-05).

## Servidor (contrato)
- `POST /matches/{id}/events` acepta además `opId` (UUID del dispositivo), `at` (hora de la acción) y `knownEvents` (acciones no automáticas que el dispositivo conocía antes de esta; obligatorio en toda acción, también en la web). Sin `opId` (web): si `knownEvents` no cuadra, 409 `MATCH_STALE` sin guardar nada ni pasar a revisión (2026-11-09).
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

## Servidor: forma exacta (hecho el 2026-11-05)
- Petición: `{"type":"POINT","side":"RED","reason":null,"opId":"<uuid>","at":"2027-03-10T09:00:30Z","knownEvents":3}`. `at` en ISO-8601 UTC; sin `at` vale la hora del servidor. Sin `knownEvents` (o negativo): 400.
- 409 en `application/problem+json` con `code`: `MATCH_CONFLICT` (primera) o `MATCH_IN_REVIEW` (siguientes, y la web con el combate en revisión).
- Reintento de un `opId` rechazado: el mismo 409 y código, aunque el club ya lo haya revisado. Uno aplicado: 200.
- Con `opId`, el aviso de una mano a quien no tiene 4-8 años también es choque (en la web sigue siendo 400).
- Vista (`GET /matches/{id}`, `POST .../events`, `match` de `/review`):
  - `serverTime` (Instant); `remainingMs`, `running` y `endReason` están calculados a esa hora.
  - `review`: null o `{"reason","ops":[{"opId","type","side","reason","actor","at","receivedAt","cause"}]}`.
  - `review.reason`: `KNOWN_EVENTS`, `RULES`, `AGE`, `MAT_BUSY` o `FIGHTER_BUSY`. `cause` de cada op: lo mismo o `IN_REVIEW`. `ops[].reason`: el motivo del aviso; `actor`: usuario del árbitro.
- Tablero (`GET /mats/{id}/board`): cada combate lleva `inReview` (bool); en revisión, `available` es false y nunca es el recomendado. No lleva `review`: se ve al abrir el combate.
- Tapices (`GET /events/{id}/mats`): `matchesInReview` (int) por tapiz.
- `/review` responde `{"match":<vista>,"applied":2,"skipped":1}`. Sin revisión: 409 `MATCH_NOT_IN_REVIEW`. Sin token 401, árbitro y ayudante 403, ajeno 404.
- Resolución de cada fila: `APPLIED`, `SKIPPED` (al aplicar, las reglas la rechazaron) o `DISCARDED`. La hora de recepción es `created_at`.

## App (APK)
- Todas las acciones del árbitro pasan por una cola local, también con red: id único, `at` = hora del dispositivo corregida con la última `serverTime` y `knownEvents`. Con red se envía al momento.
- La cola se envía en orden, una acción a la vez:
  - 200: la acción sale de la cola.
  - Error de red: reintenta más tarde.
  - 409: ese combate muestra "en revisión del club"; sus acciones salen de la cola, porque el servidor ya las guarda.
- El estado del combate = la última vista del servidor + las acciones pendientes, con las reglas del marcador repetidas en Dart (mismos casos que `TamboMatch`).
- Caché en ficheros JSON del dispositivo (no drift para la F1): último tablero del tapiz, combates abiertos y cola. Al cerrar sesión, ver "Cierre de sesión" abajo.
- Sin red, el tablero sale de la caché, sin recomendado y con aviso. Se puede empezar un pendiente si en el tapiz no hay otro en curso.
- Club: el combate en revisión se marca en Tapices. Al abrirlo muestra lo que traía el móvil (quién, qué, cuándo) y los botones Aplicar y Descartar, con confirmación.

## App (APK): cómo quedó (2026-11-05)
- Código: `app/lib/features/offline/` (cola, caché, indicador) y `scoreboard/data/tambo_match.dart` (reglas).
- Antes de encolar, el móvil rechaza lo que el servidor mandaría a revisión: reglas, aviso de una mano fuera de 4-8, combate en revisión, otro combate en curso en el tapiz (según lo que sabe el móvil).
- Con acciones pendientes de un combate, el sondeo no cambia su vista (podría traer ya alguna y `knownEvents` las contaría dos veces). Solo la cambia la respuesta de cada envío.
- Una acción que ya está en el timeline del servidor (`opId`) sale de la cola. Si son las primeras de la cola, el sondeo sí acepta esa vista.
- Otro 4xx (no 401): esa acción y las siguientes de su combate quedan "rechazadas", fuera del estado mostrado; el indicador las cuenta y deja verlas y quitarlas. No frenan a otros combates. 5xx y 401: reintento.
- Reintento: cada 3 s mientras haya pendientes y al responder cualquier otra petición.
- "En revisión" = la última vista trae `review`; tras un 409, también hasta que llegue la vista nueva.
- Una vista igual a la guardada (solo cambian `serverTime` y el tiempo restante) no se escribe ni avisa a la pantalla. La diferencia de reloj con el servidor se actualiza en cada respuesta, pero solo se guarda junto con las vistas.
- Caché: en la carpeta privada de la app, `offline/queue.json`, `views.json` y `board-<tapiz>.json`, con fichero temporal + rename. Fuera de la copia de Google y de la transferencia a otro móvil (`allowBackup="false"`, `dataExtractionRules`). Con red, el tablero descarga la vista de cada combate del tapiz que falte o haya cambiado, para poder abrir cualquiera sin red.
- Cierre de sesión (decidido por Raul el 2026-11-05: no perder acciones del árbitro):
  - Salir a mano, cambio de servidor o sesiones cerradas por una acción de la cuenta: se borra todo. Si hay acciones sin enviar, "Salir" avisa con cuántas se perderán y pide confirmar.
  - Sesión caducada o rechazada por el servidor (refresh 400/401): se borran tablero y vistas (llevan nombres), pero la cola se queda guardada con la cuenta que la creó y sin enviarse.
  - Al volver a entrar esa misma cuenta, la cola se envía como siempre. Otra cuenta no la ve ni la envía; sigue guardada hasta que entre la suya o se salga a mano con ella.
- En el móvil quedan solo nombres del tapiz y motivos de avisos.

## Web (2026-11-11, pedido de Raul: el domingo solo web)
- La web usa la misma cola que la APK (`opId`, `at`, `knownEvents`), estado optimista con `LocalMatch` y envío de una en una en segundo plano. Ya no hay camino directo ni `MATCH_STALE` en la app.
- Guardado en `localStorage` (`brackety.offline.queue`, `.views`, `.board-<tapiz>`), un documento entero por clave. Sobrevive a recargar y a cerrar la pestaña.
- Sin red, una página recargada no vuelve hasta que vuelve la red (http en el pabellón: sin service worker). Con acciones pendientes el navegador pregunta antes de recargar o cerrar; sin "deslizar para recargar" (`web/index.html`).
- Toques rápidos: se comprueban y encolan antes del primer `await`; la pantalla los muestra al momento.
- Dos pestañas del mismo navegador comparten la cola: al guardar, cada una incorpora lo que la otra guardó (los `opId` repetidos el servidor los ignora).
- Sesión: marca `brackety.session` junto a la cookie. Si al recargar el servidor no responde, la sesión sigue y la cola se envía cuando vuelve (el refresh por cookie renueva el token).
- Sin nada en la cola se muestra la vista del servidor tal cual (solo corre su reloj desde `serverTime`); las reglas en Dart solo ponen encima lo pendiente.
- Indicador (sin conexión / N pendientes / rechazadas) también en la web; con todo enviado no se muestra, para no quitar altura al marcador en el móvil.

## Rescate por CSV (2026-11-11)
- Icono de estado del árbitro (barra superior; sale sin conexión, con rechazadas o si algo lleva 5 s sin llegar): su diálogo ofrece "Descargar CSV" (con algo sin enviar). CSV con BOM y `;`: `brackety-offline-ops;2`, luego `opId;matchId;type;side;reason;at;knownEvents;actor;deltaMs` (`deltaMs`: ajuste de reloj; el servidor aún lee la versión 1) (`actor` = id de la cuenta que encoló).
- Club (web): "Importar acciones de un dispositivo" en la barra del panel. `POST /api/v1/events/{id}/offline-ops/import` (cuerpo `text/csv`, solo CLUB): comprueba todo el fichero (versión, columnas, combates del evento) y luego aplica cada fila por el mismo camino que la cola, en su transacción. Responde `{applied, duplicates, inReview, skipped}`. Reimportar no cambia nada. Autor: el `actor` si es del staff, si no el club.
