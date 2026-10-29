---
paths: ["server/**"]
---
# Reglas backend (Java 25, Spring Boot 4.1.x, Maven, PostgreSQL 18)

## Estructura
`server/src/main/java/dev/rgal/brackety/<feature>/` con: `<Feature>Controller`, `<Feature>Service`, `<Feature>Repository`, `<Feature>` (entidad), `dto/` (records). Features: auth, profiles, events, registrations, staff, league, phasedleague, tournament, scoring, scoreboard, offline, ranking, notifications, admin, legal, common.
- Un controller delgado: valida, llama al service, devuelve DTO. Lógica solo en service.
- DTOs como `record`. Nunca devolver entidades JPA.
- Dependencias entre features solo por service público; prohibidos ciclos.

## Base de datos
- Migraciones Flyway con fecha: `V<AAAAMMDD>_<HHMM>__<descripcion>.sql` (p. ej. `V20261029_1200__create_events.sql`), para que dos ramas no choquen por número. Si al fusionar `development` llega una migración posterior a la tuya, renombra la tuya a una fecha más nueva. Nunca editar una migración ya fusionada en `development`.
- Postgres 18. UUID como id público. Auditoría (`created_at`, `updated_at`, `created_by`) en tablas de negocio.
- Borrado lógico (`deleted_at`) en eventos, perfiles y resultados.

## API
- REST bajo `/api/v1`. Errores en formato `application/problem+json`.
- Documentación con springdoc; el contrato es la fuente de verdad para el front.
- WebSocket (STOMP) solo para marcador, llaves y cronómetro en directo (`docs/modulos/tiempo-real.md`).
- Paginación obligatoria en listados. Sin N+1: revisar consultas en tests.

## Seguridad
- JWT de acceso corto + refresh. Autorización por permiso de evento (`docs/modulos/ayudantes-permisos.md`), nunca solo por rol de cuenta.
- Validar en servidor siempre (Bean Validation). Nada de confiar en el cliente.
- Logs sin datos personales (sin nombres, emails ni fecha de nacimiento).

## Estilo
- Java moderno: records, `var` donde aclare, switch expressions. Sin Lombok.
- Métodos cortos; si un método supera ~30 líneas, dividir.
- Tests junto al feature en `src/test/java/...` con el mismo paquete.
