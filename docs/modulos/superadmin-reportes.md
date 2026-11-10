# Módulo · superadmin-reportes

## Objetivo
Panel exclusivo de Raul (web `admin`) y sistema de reportes de usuarios.

## Acceso
Usuario único definido por variables de entorno + Cloudflare Access. Sin otro registro. Auditoría de cada acción.

## Funciones
- Métricas: usuarios, eventos, actividad, errores.
- Usuarios: listar, buscar, bloquear/desbloquear, borrado RGPD con auditoría.
- Entidades y clubes: **verificar** (insignia) para evitar suplantación.
- Eventos: listar, bloquear, modificar, borrar (borrado lógico y definitivo a los 30 días), con motivo y auditoría.
- Operaciones de evento (pedidas por Raul para la F1, 2026-11-10), con motivo obligatorio y auditoría:
  - **Reiniciar un combate**: se borran sus acciones y las del móvil guardadas para revisión; vuelve a pendiente.
  - **Deshacer un grupo**: se borran el grupo y sus combates (también los disputados); sus alumnos vuelven a estar sin grupo. Un equipo fantasma del grupo se borra con él.
  - **Vaciar la competición**: se borran todos los grupos, combates y equipos (decidido por Raul: los equipos también); se conservan configuración, tapices, árbitros e inscritos. El siguiente grupo vuelve a ser el 1.
- Rankings: recálculo.
- **Reportes**: listado con quién lo envió, tipo, estado y notas.

## Reportes
- Se puede reportar: usuario, evento, contenido, error técnico.
- Campos: tipo, motivo, descripción, autor, objeto reportado, estado (abierto / en revisión / cerrado).
- Al crear un reporte llega un email a Raul (Resend) y aparece en el panel.
- El autor ve el estado de su reporte.

## Datos
`report`, `admin_audit` (con `reason` desde las operaciones de evento), `verification`.

## API (hecho)
- Todo bajo `/api/v1/admin/**`: Cloudflare Access y token de superadmin.
- `GET /metrics`: usuarios (activos, sin verificar, altas y borrados pendientes, organizadores por validar, sesiones abiertas, bloqueos activos, por perfil), eventos (total, hoy o después, inscritos, importaciones y alumnos importados en 7 días), actividad (en 24 h: combates terminados, acciones del marcador sin las automáticas, grupos creados; ahora: en curso y en revisión) y servidor (5xx desde el arranque, de los temporizadores `http.server.requests` de Spring; se reinicia con la API). Nada se guarda aparte.
- `GET /events?page&size` (size 1-100, por defecto 20; más nuevo primero): `items` con tapices, inscritos, grupos, combates terminados y totales; `total`.
- `GET /events/{id}`: tapices con su árbitro, grupos por número con sus combates en orden (lado = nombre o número de equipo, marcador, estado, en revisión).
- `POST /matches/{id}/reset`, `POST /groups/{id}/dissolve` (204) y `POST /events/{id}/clear-competition` (`{groups, teams}`), con `{"reason"}` (1-300). Sin motivo, 400 y nada cambia. Inexistente, 404.
- Bajo el bloqueo de fila del combate (reiniciar) o del evento (deshacer y vaciar), como el marcador y crear grupo.

## Pantallas (hecho)
- Admin, portada: una tarjeta por cifra en secciones (Usuarios, Perfiles, Eventos, Actividad, Servidor), con actualizar. Sin color salvo combates en revisión (aviso) y 5xx (error), siempre con icono y texto.
- Admin, pestaña **Eventos**: lista paginada (tabla en escritorio, tarjetas en móvil) y, al abrir uno, su detalle en la misma pestaña.
- Cada operación pide el motivo; vaciar pide además escribir el nombre del evento. Al acabar recarga el detalle y la lista; un 404 recarga y avisa.

## Tests
Acceso solo con Access y credenciales, auditoría, bloqueo de usuario/evento, flujo de reportes, borrado diferido.
- Hecho: `AdminMetricsControllerTest` (cifras, todos los perfiles aunque estén a 0, marcador en la actividad sin paradas automáticas, solo superadmin); admin `dashboard_screen_test` en 3 tamaños (cifras, avisos con icono, actualizar).
- Hecho: `AdminEventControllerTest` (lista paginada y límites, detalle, reiniciar y volver a empezar, deshacer y reagrupar, vaciar conservando inscritos y numerando desde 1, motivo obligatorio, solo superadmin, 404). Admin: `events_screen_test` en 3 tamaños (lista, detalle, reiniciar, cancelar, deshacer, vaciar con nombre, 404, páginas).

## Estado
En curso: operaciones de evento (#64, 2026-11-10) y métricas (2026-11-10, rama `feat/superadmin-metrics`). Faltan usuarios, resto de eventos y reportes.
