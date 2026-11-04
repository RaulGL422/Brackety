# Módulo · servidor-local (pabellón sin Internet)

Pedido por Raul el 2026-11-04 como medida de seguridad para la Fase 1: un portátil Windows hace de servidor y de punto de acceso; los móviles se conectan a él. Complementa a la Pi (`prototipo-f1.md`), no la sustituye.

## Objetivo
Llevar el evento ya preparado (configuración e inscripciones) y arrancarlo en cualquier portátil Windows con un solo comando, sin Internet, Docker ni instalaciones.

## Reglas
### Servidor portable
- Un script `deploy/local/start-event.ps1`: arranca la API (JDK 25) con PostgreSQL 18 embebido y **datos persistentes** en una carpeta (`brackety-data/`), y sirve la web desde la misma API (mismo origen, sin CORS).
- Parar y volver a arrancar no pierde nada; solo se borra a mano.
- Copia de la BD al cerrar cada jornada (y con `-Backup` cuando se quiera) en `brackety-data/backups/`.
- Primera vez: regla del firewall para el puerto en la red del punto de acceso (pide admin una vez).
- Muestra al arrancar la URL que deben usar los móviles (`http://192.168.137.1:8080`, IP fija del punto de acceso de Windows).
- Sin Internet: sin emails, sin Google, sin importación con Claude (los alumnos se importan antes, en la Pi o en local).

### Paquete del evento
- El club exporta desde cualquier servidor un fichero `.brackety` (JSON con versión de esquema): evento, categorías, tapices, staff (cuentas por nombre de usuario) e inscritos. Sin grupos, combates ni datos de cuentas.
- `start-event.ps1 -Package f1.brackety`: solo con la BD vacía lo carga y crea las cuentas demo del staff; con BD ya usada lo rechaza (no mezcla eventos).
- Tras arrancar, el evento está listo: el club ve sus inscritos y los ayudantes ya pueden crear grupos.
- El fichero lleva datos de menores: se guarda solo en el portátil del evento y se borra después (ver Legal).

### Dispositivos
- Árbitros y ayudantes usan la **APK Android** (el offline de la web exige https, ver `offline.md`).
- La APK elige el servidor en el login: "Pabellón" (`http://192.168.137.1:8080`), "Internet" (`https://brackety-api.rgal.dev`) o una URL a mano. Se recuerda en el dispositivo.
- http sin cifrar solo hacia la IP del pabellón (configuración de red de Android); el resto, https.
- El club puede usar el navegador del propio portátil (`http://localhost:8080`).

## Legal
- El portátil guarda datos de menores: disco cifrado (BitLocker) y cuenta de Windows con contraseña. Al acabar la fase, borrar `brackety-data/` y el `.brackety` (pendiente de confirmar por Raul).

## Datos
Sin tablas nuevas. Formato del paquete versionado (`schemaVersion`).

## API
- `GET /api/v1/events/{id}/export/package` (club): descarga el paquete.
- Carga del paquete al arrancar (`--brackety.package=<ruta>`), no por API.

## Pantallas
- Club: botón "Exportar paquete del evento" junto a los CSV.
- Login (app): selector de servidor; la pantalla Conexión muestra el elegido.

## Offline
Ver `offline.md` (adelanto F1: marcador del árbitro).

## Tests
Paquete: exportar → cargar en BD vacía → mismo evento e inscritos; rechazo con BD usada y con versión desconocida. Arranque persistente: datos tras reiniciar. Selector de servidor: widget test en 3 tamaños.

## Plan (PRs en serie)
1. Servidor portable (`start-event.ps1`, BD persistente, web servida por la API, firewall, copia).
2. Paquete del evento (exportar y cargar al arrancar).
3. APK: selector de servidor, http solo al pabellón, build de release y cómo instalarla.
4. Ensayo: portátil como punto de acceso sin Internet, 3 móviles, un combate completo.

## Estado
Pendiente (2026-11-04).
