# Módulo · tiempo-real

## Objetivo
Actualizaciones casi instantáneas de marcador, llaves y cronómetro.

## Reglas
- WebSocket simple (no STOMP, decidido el 2026-11-11): solo avisa "esto cambió" y el cliente vuelve a pedir por REST. Así las vistas y sus permisos siguen en un solo sitio y un aviso perdido solo retrasa.
- Temas: `event:<id>` (tapices, puntuaciones), `mat:<id>` (tablero; cambia con cualquier combate del evento) y `match:<id>` (marcador). Solo staff del evento.
- Autenticación con el JWT en el primer mensaje (no en la URL: ni proxies ni logs lo guardan). Token caducado: el servidor cierra con 4001 y el cliente renueva y reconecta.
- Ping cada 25 s (Cloudflare corta a los 100 s); sin mensajes en 60 s el cliente reconecta. Reconexión 1, 2, 4, 8, 15 s; al reconectar cada pantalla pide una vez.
- Respaldo: sin socket, sondeo cada 20 s; con socket, red de seguridad cada 60 s. Ráfagas: como mucho una petición por pantalla y segundo.
- Escrituras siempre por REST. Un interceptor publica tras cualquier escritura con `eventId`, `matchId` o `groupId` en la ruta (no 400/401/403/404/5xx).

## API
`/api/v1/live` (ws en el portátil, wss en la Pi por el túnel). Cliente: `{"type":"auth","token":…}`, `{"type":"watch","topics":[…]}`. Servidor: `ready`, `watching` (temas permitidos), `changed` (`topics`), `ping`.

## Pantallas
Marcador del árbitro, tablero, Tapices y Puntuaciones del club, combate visto por el club.

## Tests
`ScoreboardLiveTest` (staff oye cambios de evento, tablero y combate; ajeno no; token malo; escritura rechazada no avisa). App: `polling_test` (cambio, ráfaga, socket caído, token caducado, segundo plano).

## Estado
En pruebas (2026-11-11, `feat/realtime-offline-web`). Falta probar a mano en la Pi (wss) y en el portátil.
