# Módulo · entornos (producción y debug)

## Objetivo
- **Producción**: datos reales de clubes, estable, con copias de seguridad, sin nada de pruebas.
- **Debug**: copia completa para que Raul pruebe; desde el superadmin carga un escenario concreto o uno libre y prueba sobre él.

## Reglas
- Producción y debug no comparten BD, `JWT_SECRET`, cuentas ni claves de Google o Resend.
- Debug **nunca** lleva datos personales reales. Un evento real solo entra en debug anonimizado (nombres y nacimientos ficticios).
- Producción no contiene código de escenarios ni de reloj simulado: van en una imagen aparte (`api:debug`), no tras una opción que se pueda activar por error.
- Debug entero tras Cloudflare Access (web, API y admin): solo Raul y quien él invite.
- Las cuentas genéricas (`club1`, `arbitro1`…) y `DEMO_ACCOUNTS_ENABLED` solo existen en debug.
- Emails de debug: solo al log, o a una lista blanca de direcciones de Raul.

## URLs (aprobadas por Raul el 2026-11-16; un nivel de subdominio por el SSL gratuito de Cloudflare)
| Entorno | Web | API | Admin |
|---|---|---|---|
| Producción | `brackety.rgal.dev` | `brackety-api.rgal.dev` | `brackety-admin.rgal.dev` |
| Debug | `brackety-debug.rgal.dev` | `brackety-debug-api.rgal.dev` | `brackety-debug-admin.rgal.dev` |

## Despliegue
- Producción: imágenes de la release etiquetada (`vX.Y.Z`, rama `main`), tras la batería completa (`04-testing.md`).
- Debug: imágenes `dev` construidas en cada push a `development`; se actualiza solo o con `./deploy.sh debug`.
- Dónde (Raul, 2026-11-16): en la misma Pi, con otro proyecto de compose (`-p brackety-debug`), límites de CPU y memoria, y **parado los días de evento**.
- Antes de abrir producción al club (de `pendientes.md`): SSD, backups cifrados con restauración probada, `PRIVACY_CONTACT_EMAIL`, Resend, Google OAuth, túnel con rate limiting y `DEMO_ACCOUNTS_ENABLED=false`.
- Datos de la F1 (Raul, 2026-11-16): pasan **todos** a producción, en una cuenta privada de la entidad que lleva Raul. Cuando la app esté estable, se cede al club (p. ej. cambiando el email de la cuenta al del club).

## Escenarios en el superadmin de debug
- Pestaña **Escenarios** (solo en la imagen de debug):
  - Lista del catálogo de `08-ejecucion-local.md` con su descripción.
  - "Cargar": vacía la BD, aplica migraciones y carga el escenario. Pide escribir el nombre del escenario y avisa de que se pierde todo.
  - "Libre" = escenario `empty` + el superadmin: Raul crea todo a mano.
  - Fecha simulada: elegir el día (el reloj sigue corriendo desde ahí) o volver a hoy.
  - "Guardar estado" y "Restaurar estado" (copias con nombre de la BD de debug): repetir una prueba sin rehacerla.
- Mismo código de escenarios para local y debug: salen de `server/src/test` a un módulo o perfil `devdata` que solo entra en la imagen de debug.
- Cargar cierra todas las sesiones (la BD es nueva); la app lo trata como sesión caducada.

## API (solo imagen de debug; en producción 404)
- `GET /api/v1/admin/dev/scenarios` → nombre y descripción.
- `POST /api/v1/admin/dev/scenarios/{name}/load` `{today?}` → 202 y estado del arranque.
- `GET/PUT /api/v1/admin/dev/clock` `{today | null}`.
- `GET/POST /api/v1/admin/dev/snapshots`, `POST /snapshots/{name}/restore`.
- Todas con token de superadmin, Cloudflare Access y auditoría.

## Pantallas
- Admin de debug: pestaña Escenarios y una franja fija "DEBUG · escenario X · fecha simulada Y" en todas las pantallas de app y admin, para no confundir los entornos.

## Offline
No aplica.

## Tests
- La imagen de producción no tiene los endpoints `/admin/dev/**` (404) ni las clases de escenarios.
- Cargar un escenario deja la BD igual que el arranque local con ese escenario.
- Reloj simulado: cambiar la fecha cambia `GET /api/v1/info`.
- Restaurar una copia deja los datos como al guardarla.

## Estado
- 2026-11-17, fusionado (#115): escenarios en `server/src/devdata` (código de test por defecto; en el jar solo con `./mvnw -P debug package`, entrada `DebugBracketyApplication`), `GET /api/v1/admin/dev`, `GET …/scenarios`, `POST …/scenarios/{nombre}/load {confirm, today?}`, `PUT …/clock {today}`, auditados como `DEBUG_CHANGE`. La imagen de producción no los tiene (404, `ProductionHasNoDebugTest`). Dockerfile: `--build-arg MAVEN_PROFILE=debug`.
- 2026-11-17, fusionado (#117): copias con nombre (`GET/POST …/snapshots`, `POST …/snapshots/{nombre}/restore`, `DELETE …/snapshots/{nombre}`), cada una un esquema `snapshot_<nombre>` en la misma BD (sobrevive a cargar escenarios; restaurar exige la misma versión de BD). `GET /api/v1/debug` público para la franja. Admin: pestaña Escenarios solo con `--dart-define=BRACKETY_DEBUG=true`; franja "DEBUG · escenario · fecha" en app y admin cuando el servidor responde a `/api/v1/debug`.
- 2026-11-17, fusionado (#118): `deploy/docker-compose.debug.yml` (proyecto `brackety-debug`, límites, puertos 8090-8092, túnel propio), `.env.debug`, `./deploy.sh debug|debug-stop`; `images.yml` publica `api|web|admin:dev` en cada push a `development` y prueba el api de debug en cada PR. Guía: `09-despliegue.md`.
- 2026-11-17, en pruebas (rama `feat/f1-handover`): `deploy/f1-handover.sh` + `f1-handover.sql` pasan `club1` a la cuenta de la entidad y retiran las genéricas (`F1HandoverScriptTest`). Guía: `09-despliegue.md`, «Datos de la F1 a producción».
