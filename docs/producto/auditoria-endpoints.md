# Inventario de endpoints (2026-11-26)

Parte de `auditoria-seguridad.md`. Pregunta de Raul: ¿son demasiados para lo que lleva la app?

## Recuento
~138 endpoints (161 anotaciones menos las `@RequestMapping` de clase).
| Zona | Nº | Comentario |
|---|---|---|
| Auth pública (`/auth`) | 13 | Registro, login, Google, QR, renovación, verificación, contraseña: lo normal |
| Cuenta (`/me`) | 13 | Perfil, consentimientos, identidades, borrado, exportación RGPD |
| Superadmin (`/admin`) | 26 | 7 repiten el panel de control del club a propósito (ver abajo) |
| Evento, fases, ajustes, reglamento, paquete | 20 | |
| Grupos, equipos, tablero, control | 18 | |
| Inscritos e importación | 9 | |
| Clasificación y descargas | 16 | 7 descargas fijas que ya cubren las exportaciones a medida |
| Marcador y offline | 4 | |
| Staff, invitaciones, QR | 11 | |
| Liga, legal, info | 8 | |

Veredicto: no sobran muchos. La complejidad real está dentro (dos caminos individual/equipos, `auditoria-codigo.md` punto 1), no en el número de rutas.

## Lo que parece repetido y no lo es
- `/admin/events/{id}/control/**` y `/events/{id}/control/**`: mismo servicio, controllers finos. Van por otra cadena de seguridad (Cloudflare Access y token de superadmin) y el de admin escribe en `admin_audit`. Unirlos mezclaría las dos cadenas: se quedan.

## Propuestas (necesitan a Raul)
| Id | Qué | Ahorro | Cuándo |
|---|---|---|---|
| E1 | Quitar las 7 descargas fijas de `StandingsController` (`export/*.csv`, `.zip`, `.pdf`) y su enum en `club_repository.dart`; la app usa las hojas a medida, que ya las cubren todas. `export/full` se queda | 7 endpoints, ~300 líneas, parte del oro | Cuando Raul dé por buenas las exportaciones a medida |
| E2 | Un solo «mover combate» (`/matches/{id}/move` del árbitro y `/control/matches/{id}/mat` del club) que decida por permisos | 1 endpoint | Con L4 (panel único) |
| E3 | `rulebook/info` e `import/available` como campos de `settings` | 2 endpoints y 2 lecturas al abrir Configuración | Con el rediseño de Configuración (`eventos-ux.md`) |

## Cómo se contó
`grep` de `@(Get|Post|Put|Patch|Delete)Mapping` en `server/src/main`. El uso desde la app no se puede contar con `grep` de la ruta: los clientes la construyen por partes (`'${_path(id)}/sheets'`).
