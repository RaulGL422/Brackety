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
Servidor, APK, web y rescate por CSV: en `offline-f1.md`.

## Datos
`offline_op` (cliente), `import_log` (servidor), formato CSV versionado.

## Pantallas
Estado de conexión, descarga previa, cola pendiente, exportar/importar CSV, resolución de choques.

## Tests
Sin red → operaciones → sincronización; idempotencia; CSV round trip; choque de dos escritores; traspaso de tapiz.
- Servidor F1 (`ScoreboardOfflineTest`, `ScoreboardReviewControllerTest`): con `opId` igual que sin él; reintentos sin duplicar (200 y 409); `at` recortado a ahora y subido a la última acción; combate jugado offline y fin por tiempo con los `at`; `knownEvents` distinto, alumno en otro tapiz y siguientes en revisión; web en revisión; web sin `knownEvents` (400) y dos pestañas a la vez (la segunda, 409 `MATCH_STALE`, `ScoreboardControllerTest`); paradas automáticas fuera de `knownEvents`; APPLY en orden saltando las que no valen y finalizando; DISCARD; permisos de `/review`, `serverTime`, `review`, tablero y códigos del problem+json.
- App F1: `tambo_match_test` (los casos de `TamboMatchTest`); `local_match_test` (cola sobre la vista, parada automática, deshacer, `at` subido, tablero sin red); `offline_sync_test` (orden, sin red y envío al volver, reintento con el mismo `opId`, vista que ya trae una pendiente (sale de la cola, cuenta una vez y `knownEvents` correcto), desfase con `serverTime`, 409 a revisión, revisión resuelta, otro 4xx, sobrevive al reinicio, borrado al salir, ficheros atómicos); `offline_session_test` (sesión rechazada: cola guardada sin vistas, misma cuenta la envía, otra no la ve ni la borra al salir, salir a mano y cambio de servidor la borran, `queue.json` sin cuenta); `confirm_sign_out_test` en 3 tamaños (aviso al salir con pendientes); `offline_screens_test` en 3 tamaños (tablero sin red con indicador, marcador con pendientes, revisión del club); `match_controller_test` (5 puntos seguidos salen al momento y se envían en orden con su `knownEvents`).

## Estado
Web con cola, sesión tras recarga y rescate CSV hechos (2026-11-11, `feat/realtime-offline-web`); tests de servidor y app en verde. Falta la prueba a mano en el portátil y en la Pi.
Pendiente; adelanto F1 en pruebas (2026-11-05, rama `feat/offline-f1-scoreboard`): servidor y app hechos. Falta la prueba manual de Raul y un escenario de datos con un combate en revisión (es de `server/`, sin hacer). Prueba a mano: APK sin red (modo avión) en un combate y en el tablero; volver la red; choque con el mismo árbitro en la web escribiendo el combate mientras el móvil está sin red; Aplicar y Descartar desde el club.

## Ayudantes y lecturas sin red (2026-11-13, pedido de Raul)
- Sin red las pantallas no esperan: el cliente sabe que no hay conexión y sirve lo guardado al instante; un sondeo ligero (`GET /api/v1/info` cada 3 s) detecta la vuelta y entonces se pide todo de nuevo.
- Lecturas guardadas en el dispositivo (`OfflineGetCache`): mis eventos, categorías, alumnos y equipos de cada categoría, tapices, configuración, clasificación e inscritos. El tablero y los combates del árbitro siguen con su caché propia.
- Equipos y grupos creados sin red van a una cola (`HelperQueue`, documento `helper-queue`): sus alumnos salen "Pendiente de enviar" y se envían en orden al volver. Si el servidor los rechaza (alguien ya agrupado por otro ayudante) se descartan y se avisa.
