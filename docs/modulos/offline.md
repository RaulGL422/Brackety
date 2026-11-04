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

## Datos
`offline_op` (cliente), `import_log` (servidor), formato CSV versionado.

## Pantallas
Estado de conexión, descarga previa, cola pendiente, exportar/importar CSV, resolución de choques.

## Tests
Sin red → operaciones → sincronización; idempotencia; CSV round trip; choque de dos escritores; traspaso de tapiz.

## Estado
Pendiente; adelanto F1 planificado (2026-11-04). Más casos se afinarán en la construcción.
