# 01 · Arquitectura

## Contenedores (cada uno independiente; si uno cae, los demás siguen)
| Servicio | Contenido | Notas |
|---|---|---|
| `api` | Spring Boot 4.1.x, Java 25 | REST `/api/v1` + WebSocket STOMP |
| `web` | Flutter web pública (nginx estático) | PWA, offline para ayudantes |
| `admin` | Flutter web superadmin (nginx) | Solo tras Cloudflare Access |
| `db` | PostgreSQL 18 | Volumen persistente; sin puerto público |
| `tunnel` | cloudflared | Único punto de entrada a Internet |

Sin Redis ni colas al inicio. Un único `docker-compose.yml` en `deploy/` con perfiles `pi` y `windows`. Imágenes `linux/arm64` y `linux/amd64`.

## Dominios
`<proyecto>.rgal.dev` (web), `api.<proyecto>.rgal.dev` (API), `admin.<proyecto>.rgal.dev` (superadmin, con Cloudflare Access). Dominio final pendiente de confirmar marca (`docs/pendientes.md`).

## Comunicación
- REST para todo. WebSocket solo marcador, cronómetro y llaves en directo.
- Cliente offline: base local en el dispositivo del ayudante; sincroniza al volver la red (`modulos/offline.md`).
- Email: Resend (dominio rgal.dev). Push: Firebase Cloud Messaging.

## Modelo conceptual (resumen)
`Cuenta` 1→N `Perfil` (Club, EntidadExterna, Ayudante, Alumno, Externo). `Evento` (tipo: liga | liga_fases | torneo) → `Fase` → `Grupo`/`Llave` → `Combate` → `Resultado`. `Ubicación` (tapiz, entrada…) asignada a grupos y ayudantes. `Plantilla de deporte` define modalidades, categorías y reglas de puntuación. Detalle en cada módulo.

## Capacidad (20 simultáneos)
Pool de conexiones DB pequeño (10), una instancia de API, límites de tasa en login y escritura, paginación obligatoria. WebSocket: una sala por tapiz/grupo. Si crece: alquilar nube sin cambiar el diseño.

## Fallos y recuperación
- DB en SSD (SD solo para desarrollo; requisito de lanzamiento).
- `pg_dump` diario cifrado a almacenamiento externo con restauración probada (`05-seguridad-infra.md`).
- Despliegue manual con `deploy/deploy.sh` (descarga imágenes de GitHub Container Registry, reinicia servicios).

## Decisiones técnicas clave
Ver `decisiones.md`. Versiones en `02-stack-versiones.md`.
