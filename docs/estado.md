# Estado del proyecto

Última actualización: 2026-11-02. Fase 0 cerrada; en curso: **auth**.

| Módulo | Doc | Estado | Rama activa |
|---|---|---|---|
| infra-deploy | modulos/infra-deploy.md | cerrado (2026-10-30) | – |
| auth | modulos/auth.md | en curso: tareas 1-6/9 hechas (registro, login, sesión, bloqueo, limitador; verificación, recuperación, purga, avisos por email; login Google, sustitución de cuenta sin verificar, vincular y desvincular; `/me`, perfiles, reauth, cambio de email, borrado lógico con restaurar y purga, exportación; corte de tokens al cerrar sesiones, bloqueo de borrado a dueños de eventos; superadmin por entorno tras Cloudflare Access verificado en la API, bloqueos y validación de organizadores con auditoría; app: login con bloqueo y restaurar cuenta, registro, verificación pendiente, verificar email, recuperar y cambiar contraseña, sesión con refresh seguro en Android y sin red; entrar tras registrarse, perfiles Club y Ayudante) (2026-11-02) | feat/auth-screens-login |
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
| sistema de diseño: tokens + página dev en admin | 07-diseno.md | cerrado (2026-10-30) | chore/design-system |
| prototipo Fase 1 Yoseikan (uso real ≈ 2026-11-14) | modulos/prototipo-f1.md | en curso: back completo (pasos 1-3/7); front pasos 4-6/7 (login de `auth`, mis eventos, crear grupos; tablero del tapiz y marcador con campana; panel del club con puntuaciones, tapices, inscripciones, configuración y CSV). Probado a mano en Chrome (ayudante, árbitro y club). Paso 7 en curso: release `v0.1.0` y despliegue en la Pi (`brackety.rgal.dev`); después, categorías por equipos (2026-11-02) | docs/proto-f1-deploy |
| prototipo F1: categorías por equipos | modulos/prototipo-f1-equipos.md | en curso: paso 8 (back) hecho: categorías con formato y tamaños, equipos, grupos de equipos, equipo fantasma, grupo individual, recomendado, marcador, puntuación por miembro, CSV, demo con 4 categorías por equipos. Falta: pasos 9-11 (front) (2026-11-02) | feat/proto-f1-teams-back |
- Motivo prototipo: Raul necesita usar la app en la Fase 1 real en 15 días; adelanta versiones mínimas de eventos, inscripciones, grupos, marcador y ranking.
- Motivo sistema de diseño: fijar colores, tipografía, espaciado y componentes antes de la primera pantalla real (`auth`), para no repartir valores sueltos por el código.

## Bloqueos
Ver `pendientes.md`. Ninguno bloquea la fase 0.
