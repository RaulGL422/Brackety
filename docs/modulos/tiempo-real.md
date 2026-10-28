# Módulo · tiempo-real

## Objetivo
Actualizaciones casi instantáneas de marcador, llaves y cronómetro.

## Reglas
- WebSocket (STOMP) solo para: marcador en directo, cronómetro, avance de llaves, cambios de grupo en un tapiz.
- Una sala por tapiz/grupo. Los espectadores se suscriben solo a lo que el evento permite ver.
- Autenticación del socket con el JWT; autorización por visibilidad del evento.
- Mensajes pequeños y con versión; el servidor es la fuente de verdad. Reconexión con reenvío del último estado.
- Límites de conexiones y de tasa de mensajes; heartbeat; cierre de sesiones inactivas.
- Si falla el socket, la app hace *polling* suave de respaldo.
- Escrituras (marcador) siempre por REST o por el canal del escritor único; los espectadores solo reciben.

## API
`/ws`, destinos `/topic/events/{id}/locations/{id}`, `/topic/matches/{id}`.

## Pantallas
Vista en directo del evento, cuadro en directo, pantalla grande de marcador (opcional futuro).

## Tests
Suscripción autorizada/denegada, reconexión, orden de mensajes, carga con 20 usuarios simultáneos.

## Estado
Pendiente.
