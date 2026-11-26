# Auditoría de seguridad, rendimiento y endpoints (2026-11-26)

Pedido de Raul: preparar la app para uso formal. Atacar la app como lo haría alguien de fuera (tumbarla, robar datos), medir el rendimiento y simplificar la API. Complementa `auditoria-codigo.md` (calidad) y su plan `plan-limpieza.md`. Rama `chore/hardening`.

## Método
- Lectura dirigida de cada superficie: cadenas de seguridad, filtros, endpoints públicos, socket en vivo, subidas de archivos, importación con `claude -p`, descargas y acceso por QR.
- IDOR: cada búsqueda de un recurso hijo por id (`groupId`, `matchId`, `matId`…) comprobada contra su evento.
- Rendimiento medido, no supuesto: `QueryBudgetTest` cuenta las sentencias SQL de cada lectura que los dispositivos repiten.

## Lo que ya estaba bien
- JWT con revocación por consulta en cada petición; tokens de reautenticación y restauración no abren la API.
- Límite de tasa por IP sobre la ruta decodificada; bloqueo de cuenta; hash señuelo contra enumeración por tiempo; registro sin revelar si el email existe.
- CORS sin comodines con credenciales; cookie de renovación `HttpOnly`, `Secure`, `SameSite=Lax`.
- IDOR: todos los recursos hijos se filtran por evento; datos personales solo con `PARTICIPANTS` y descargas personales con `PERSONAL_DATA`.
- Importación: Excel sin DTD ni entidades externas (XXE) y con tope por entrada (zip bomb); `claude -p` sin herramientas, sin ajustes, con esquema y 10 lecturas por hora.
- Descargas: CSV y Excel neutralizan fórmulas (`=`, `+`, `-`, `@`).
- QR: token de 256 bits; contraseña temporal de ~40 bits tras bloqueo y límite de tasa.
- Superadmin tras Cloudflare Access y token propio.

## Hallazgos y arreglos
| Id | Gravedad | Qué | Estado |
|---|---|---|---|
| S1 | Alta | Cuerpos `byte[]`/JSON sin límite: cualquier cuenta verificada podía mandar GB a `/import/results` u `/offline-ops/import` y agotar la memoria antes de comprobar permisos | Arreglado: `RequestSizeFilter` (2 MB; 10 MB ops offline; 60 MB resultados; 413) |
| S2 | Media | El socket en vivo no revalidaba la sesión: una cuenta suspendida, borrada o con contraseña cambiada seguía oyendo cambios hasta 12 h (portátil) | Arreglado: cada latido (25 s) vuelve a validar el token |
| S3 | Baja | Sin `Content-Security-Policy` | Mínima añadida (`frame-ancestors`, `base-uri`, `object-src`, `form-action`); la completa necesita prueba en navegador |
| S4 | Baja | Suscripciones del socket no se revisan si sacan a alguien del staff (solo oye "algo cambió", sin datos) | Pendiente; se resuelve al reconectar |
| S5 | Info | La importación offline atribuye cada acción al árbitro que diga el CSV si es del staff | Por diseño: el archivo sale del dispositivo del árbitro |

## Rendimiento (sentencias SQL por lectura)
| Lectura | Antes | Ahora | Causa |
|---|---|---|---|
| Categorías del evento | 29 (crecía con cada categoría) | 13 fijo | Releía categorías y participantes por categoría |
| Ajustes del evento | 18 (crecía con el staff) | 12 fijo | Permisos leídos uno a uno |
| Mis eventos | 8 (crecía por evento) | 9 fijo | Tapices y permisos por evento |
| Marcador de un combate | 20 | 17 | Directorio del evento leído dos veces |
| Tablero, tapices, clasificación, `me` | 15, 14, 14, 5 | igual | Correctos: cada tabla una vez |
`QueryBudgetTest` fija estos presupuestos (solo bajan) y falla si una lectura crece al añadir grupos.

## Base de datos
- Índices: todas las búsquedas tienen índice (las 26 claves foráneas desde L1; tokens, bloqueos y emails, por `unique`).
- `refresh_token` crecía sin fin (una fila por renovación, cada 15 min por dispositivo) y `email_token` igual: `ExpiredTokenPurge` diario. Las de renovación se guardan 30 días tras caducar: un token usado que reaparece es robo (GR-8) y debe seguir detectándose.
- `team`, `team_member` y `group_member` no se tocan: las sustituye M3 (`m3-entradas.md`).
- Columnas de reglas de `event` (M1): se borran en la release siguiente a que M1 llegue a producción (hoy v0.7.0, sin M1).

## Despliegue
- D1: la API arrancaba con `MaxRAMPercentage=75` sin límite en su contenedor: podía quedarse el 75 % de la Pi (16 GB) y dejar sin memoria a PostgreSQL. Arreglado: límite de 4 GB en `api`; `db` sin límite a propósito.

## Endpoints
Ver `auditoria-endpoints.md`.
