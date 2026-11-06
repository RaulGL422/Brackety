# Revisión antes de la Fase 1 (2026-11-06)

Revisión de seguridad, código y diseño visual (86 capturas en 3 tamaños, horizontal, oscuro y texto al 200 %) antes de la prueba en el pabellón del 10-11 y del evento del 14-11. Se borra tras la fase; lo que quede abierto pasa a `pendientes.md`.

## Decisiones de Raul (2026-11-06)
- Contraseñas del staff del paquete: aleatorias al cargar, en consola y en `brackety-data/credentials.txt`. Las de `-Demo` siguen usuario = contraseña.
- No se puntúa antes de "Iniciar": botones desactivados y el servidor lo rechaza. Con el reloj ya iniciado y parado sí.
- Marcador en horizontal con diseño propio: rojo, reloj y botones en el centro, azul.
- Sesión: repetir el refresh dentro del margen de gracia devuelve el mismo par; en el pabellón el access token dura 12 h.

## Antes del 10-11
### Servidor y pabellón (`fix/f1-hardening-server`)
- [x] Contraseñas aleatorias para las cuentas del paquete (`EventPackageService`).
- [x] Rechazar POINT, WARNING, ONE_HAND_WARNING y DISQUALIFICATION antes del START (`TamboMatch`, `MatchWriter`).
- [x] Refresh idempotente en el margen de gracia (`SessionService`); `ACCESS_TTL` por variable de entorno, 12 h en `start-event.ps1`.
- [x] `X-Forwarded-For` ignorado en el pabellón: sin él, un móvil del hotspot se salta el bloqueo por IP y el limitador (`server.forward-headers-strategy`).
- [x] Firewall: el 8080 solo desde `192.168.137.0/24` (`start-event.ps1`).
- [x] Primer START bloquea el evento: dos tapices no empiezan a la vez con un alumno compartido.
- [x] `GET /participants` solo CLUB (hoy también el ayudante, con nacimiento y consentimiento).
- [x] CSV: neutralizar también celdas que empiezan por tabulador o retorno.
- [x] `start-event.ps1`: avisar si el disco no tiene BitLocker; `brackety-data` solo para el usuario (`icacls`).

### App (`fix/f1-app-polish`)
- [ ] Pantalla siempre encendida en el tablero y el marcador (wakelock).
- [ ] Sondeo: el siguiente al acabar el anterior y en pausa con la app en segundo plano.
- [ ] `views.json`: no reescribir ni notificar si nada cambió.
- [ ] `android:allowBackup="false"`: la copia de Google no sube la caché con nombres.
- [ ] Marcador: diseño horizontal; sin desbordes al 200 %; reloj grande con color en los últimos 10 s; "Parar" en color fuerte; Deshacer de 48 dp junto a los +1 diciendo qué deshace; ganador destacado al finalizar; Descalificación en color de error; esquinas desactivadas antes de Iniciar.
- [ ] Tablero: contraste AA en "En curso" y "Recomendado" y que se distingan; rojo y azul en cada combate; pendientes legibles con candado y motivo.
- [ ] Ayudante: flecha del popup sin caja; categoría con 0 inscritos sin check.
- [ ] Club: chip "Falta tutor" en Inscripciones; tarjeta en revisión legible; fin estimado oculto sin pendientes; título de la revisión con tapiz y combate; confirmar "Quitar el último tapiz".

## Antes del 14-11 (Raul)
- Clave del punto de acceso larga y solo para el staff; cambiarla antes del evento.
- BitLocker en el portátil; tras la fase borrar `brackety-data*`, el `.brackety` y lo descargado en Descargas (CSV, paquete).
- Ajustes del punto de acceso: sin ahorro de energía; máximo 8 dispositivos.
- Si se usa la Pi con alumnos reales: no con `DEMO_ACCOUNTS_ENABLED=true` (cuentas públicas en Internet); mejor preparar el evento en local y exportar el paquete.

## Después de la fase
- APK firmada con keystore propio.
- `opId` único por combate, no global.
- Enlaces con token en `api.log` cuando no hay Resend.
- Límite de tamaño del paquete `.brackety`.
- Revisar CVE de dependencias (Dependabot u OSV).
- Código: nombre del competidor repetido en 3 servicios; comprobación "club o árbitro del tapiz" repetida; `MatBoardService.board` (~100 líneas), `LocalMatch.project` (~120), `StandingsService` (CSV aparte), `team_category_screen.dart` (586 líneas).
- Vista del combate: cargar solo los 2 competidores, no todo el directorio del evento.
- Tests compartidos Dart/Java de `TamboMatch` (mismo JSON) y de concurrencia en el servidor.
- "Equipo " fijo en el servidor (i18n).
- Puntuaciones: "(3)" sin explicar; ancho máximo en escritorio. Tarjetas de eventos sin separación; enlaces legales del login pequeños.

## Comprobado sin fallos
Autorización por evento en todos los endpoints (sin IDOR), XLSX y CSV, actuator solo `health`, PostgreSQL en 127.0.0.1, path traversal en la web servida, consultas sin N+1 y con índices, rendimiento con 5 árbitros (≈40 consultas/s), paridad de reglas Dart/Java, flush único y escritura atómica de la cola, rojo/azul con contraste suficiente, barra sin conexión, modo oscuro del marcador.
