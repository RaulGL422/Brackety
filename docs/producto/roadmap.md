# Hoja de ruta tras la Fase 1

Fecha: 2026-11-16. Tras la F1, pausa para organizarse (corta por el calendario); después se sigue por etapas. Una PR abierta por línea de trabajo (`03-git-workflow.md`).

Documentos: `feedback-f1.md` (qué pasó y peticiones para la F2), `competicion-2026-12-20.md`, `../modulos/entornos.md`, `calidad.md`, `eventos-ux.md`, `gestion-club.md`.

## Calendario
| Fecha | Hito |
|---|---|
| 2026-12-20 | Competición aparte de la liga: grupos de 4 individuales en 3 modalidades seguidas |
| 2027-01-24 | Fase 2 de la liga (armas) |
- La pausa es corta: **antes del 20-12**, la etapa 1, F1-1 y F1-2 de la etapa 2 y la competición (lista hacia el 13-12 para probarla in situ).
- **Antes del 24-01**, el resto de la etapa 2 (con peso y edades) y la plantilla de la F2 en `puntuacion`.
- La etapa 3 empieza después del 24-01, salvo los filtros del CI, que se pueden hacer antes.

## Ahora · Etapa 0: organizarse (pausa)
- [x] Retrospectiva y hoja de ruta (este documento).
- [ ] Raul responde las preguntas de `pendientes.md` (Tras la Fase 1).
- [x] Fechas: competición el 2026-12-20 y F2 el 2027-01-24.
- [ ] Detalles de la competición del 20-12 (`competicion-2026-12-20.md`).

## Después · Etapa 1: producción de verdad (el club ya la pide)
Línea de infraestructura; puede ir en paralelo con la etapa 2 (otro worktree).
1. SSD en la Pi y traslado de la BD (`09-despliegue.md`).
2. Backups cifrados con copia fuera de la Pi y restauración probada.
3. Cloudflare: túnel, hostnames, Access para admin y rate limiting de auth.
4. Emails reales (Resend), `privacidad@rgal.dev` y `PRIVACY_CONTACT_EMAIL`.
5. Google OAuth (web y Android) y keystore propio para la APK.
6. Entorno **debug** en la Pi, con su URL y escenarios en el superadmin (`modulos/entornos.md`).
7. `DEMO_ACCOUNTS_ENABLED=false` y fuera las cuentas genéricas en producción.
8. Todos los datos de la F1 a producción, en una cuenta privada de la entidad que lleva Raul y que cederá al club cuando la app esté estable.
9. Release `vX.Y.Z` con la batería completa.

## Después · Etapa 2: arreglos de la F1 (antes de la F2)
1. F1-2 Comodín guardado como normal (crítico) + revisión de los datos de la F1.
2. F1-1 Inhabilitar tapiz visible y con estado.
3. F1-3 Puntos fuera de tiempo.
4. F1-4 Motivos de advertencia predefinidos y "Otro".
5. F1-5 Cuentas propias: invitaciones del club a árbitros y ayudantes (adelanto de `ayudantes-permisos`); retirar `staffNames`.
6. F2-1 Peso de los alumnos.
7. F2-2 Edades mezcladas dentro de una categoría, ordenadas y distinguidas.

## Después · Etapa 2b: competición del 2026-12-20 (`competicion-2026-12-20.md`)
- Torneo con grupos de 4 y 3 modalidades seguidas. Diseño en cuanto lleguen los detalles; prueba in situ hacia el 13-12.

## Después · Etapa 3: calidad (`calidad.md`)
1. CI por componentes con `ci-ok` y batería completa en releases.
2. Inventario del código con números.
3. Refactor por módulo con tests de caracterización, empezando por marcador, grupos y tablero.
4. Revisión de diseño completa con `frontend-design` y lista priorizada.

## Más tarde · Etapa 4: eventos y módulos pendientes
- Rediseño de eventos (`eventos-ux.md`): maquetas, prueba con 6 tareas y, después, por secciones.
- Cerrar los módulos que el prototipo adelantó: `eventos`, `inscripciones`, `ayudantes-permisos`, `puntuacion`, `liga-fases`, `marcador-tapiz`, `offline`.
- Módulos por empezar: `perfiles-menores`, `liga`, `torneo`, `ranking`, `notificaciones`, `superadmin-reportes` (resto).
- **Ojo con el calendario de la liga**: F2 (armas) y sobre todo F3 (expresión técnica, puntuada por jueces con escala aún sin definir) necesitan su plantilla en `puntuacion` antes de su fecha (`reglamentos/yoseikan-2027.md`).

## Más tarde · Etapa 5: gestión del club (`gestion-club.md`)
- Solo tras las etapas 1-4 y un descubrimiento con clubes reales.
- Si se confirma: Alumnos, Asistencia y Cuotas (control) primero; cobro online, facturas y redes después y con condiciones.

## Riesgos
| Riesgo | Mitigación |
|---|---|
| Datos reales en la SD de la Pi | SSD y backup antes de abrir producción |
| 20-12 y 24-01 llegan antes que las etapas 1-2 | Prioridades del calendario; recortar alcance, no retrasar |
| Refactor que rompe lo que funcionó | Tests de caracterización y PRs sin cambio de comportamiento |
| Alcance sin fin (gestión del club) | Descubrimiento y MVP acotado; decisión explícita de Raul |
| Un solo desarrollador | Etapas cortas, una PR cada vez, CI que proteja |
