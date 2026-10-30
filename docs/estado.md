# Estado del proyecto

Última actualización: 2026-10-30. Fase 0 cerrada; siguiente: **auth**. Imprevisto en curso: sistema de diseño (ver abajo).

| Módulo | Doc | Estado | Rama activa |
|---|---|---|---|
| infra-deploy | modulos/infra-deploy.md | cerrado (2026-10-30) | – |
| auth | modulos/auth.md | pendiente | – |
| perfiles-menores | modulos/perfiles-menores.md | pendiente | – |
| legal-paginas | modulos/legal-paginas.md | pendiente | – |
| eventos | modulos/eventos.md | pendiente | – |
| inscripciones | modulos/inscripciones.md | pendiente | – |
| ayudantes-permisos | modulos/ayudantes-permisos.md | pendiente | – |
| puntuacion | modulos/puntuacion.md | pendiente | – |
| liga | modulos/liga.md | pendiente | – |
| liga-fases | modulos/liga-fases.md | pendiente | – |
| torneo | modulos/torneo.md | pendiente | – |
| marcador-tapiz | modulos/marcador-tapiz.md | pendiente | – |
| tiempo-real | modulos/tiempo-real.md | pendiente | – |
| offline | modulos/offline.md | pendiente | – |
| ranking | modulos/ranking.md | pendiente | – |
| notificaciones | modulos/notificaciones.md | pendiente | – |
| superadmin-reportes | modulos/superadmin-reportes.md | pendiente | – |

Estados: pendiente · en curso · en pruebas · cerrado.

## Orden de construcción propuesto
1. Repo, CI, `deploy/` y esqueletos (server, app, admin) → `infra-deploy`.
2. `auth` → `perfiles-menores` → `legal-paginas` (incluye puerta `PRIVACY_CONTACT_EMAIL`).
3. `eventos` → `inscripciones` → `ayudantes-permisos`.
4. `puntuacion` (motor) con el reglamento Yoseikan como primera plantilla.
5. `liga-fases` (es el caso real de la Liga Yoseikan) → `liga` → `torneo`.
6. `marcador-tapiz` + `tiempo-real` + `offline`.
7. `ranking`, `notificaciones`, `superadmin-reportes`.
8. Exploración de diseño (`07-diseno.md`) justo antes de la primera pantalla real de cada bloque.

## Imprevistos (fuera del orden)
| Tarea | Doc | Estado | Rama activa |
|---|---|---|---|
| sistema de diseño: tokens + página dev en admin | 07-diseno.md | en curso (2026-10-30) | chore/design-system |
- Motivo: fijar colores, tipografía, espaciado y componentes antes de la primera pantalla real (`auth`), para no repartir valores sueltos por el código.

## Bloqueos
Ver `pendientes.md`. Ninguno bloquea la fase 0.
