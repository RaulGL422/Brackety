# Estado del proyecto

Última actualización: 2026-11-12. Fase 0 cerrada; en curso: **auth** (pruebas) y la preparación de la Fase 1 (ver "Hasta la Fase 1").

| Módulo | Doc | Estado | Rama activa |
|---|---|---|---|
| infra-deploy | modulos/infra-deploy.md | cerrado (2026-10-30) | – |
| auth | modulos/auth.md | en pruebas: tareas 1-9/9 hechas; falta la prueba manual del módulo completo de Raul (registro, login, sesión, bloqueo, limitador; verificación, recuperación, purga, avisos por email; login Google, sustitución de cuenta sin verificar, vincular y desvincular; `/me`, perfiles, reauth, cambio de email, borrado lógico con restaurar y purga, exportación; corte de tokens al cerrar sesiones, bloqueo de borrado a dueños de eventos; superadmin por entorno tras Cloudflare Access verificado en la API, bloqueos y validación de organizadores con auditoría; app: login con bloqueo y restaurar cuenta, registro, verificación pendiente, verificar email, recuperar y cambiar contraseña, sesión con refresh seguro en Android y sin red; entrar tras registrarse, perfiles Club y Ayudante; registro de organizadores con CIF; ajustes de cuenta: idioma de app y emails, perfiles, cambio de email, exportar, borrar, Google ya vinculado; admin: login de superadmin con token en memoria, bloqueos con revocar, organizadores con filtro y validar) (2026-11-02) | feat/auth-admin-login |
| perfiles-menores | modulos/perfiles-menores.md | pendiente | – |
| legal-paginas | modulos/legal-paginas.md | en pruebas: pasos 1-2 hechos (back: textos ES/EN en ficheros, `GET /api/v1/legal` y `/{tipo}`, versiones validadas en registro; app: páginas `/legal/<tipo>`, casilla del registro con enlaces y versiones del servidor, pie, ajustes, licencias, aviso en alumno e importación); falta prueba manual de Raul y la puerta `LEGAL_GATE` cuando existan publicar eventos y pasar de fase (2026-11-04) | feat/legal-front |
| eventos | modulos/eventos.md | pendiente | – |
| inscripciones | modulos/inscripciones.md | pendiente | – |
| ayudantes-permisos | modulos/ayudantes-permisos.md | pendiente | – |
| puntuacion | modulos/puntuacion.md | pendiente | – |
| liga | modulos/liga.md | pendiente | – |
| liga-fases | modulos/liga-fases.md | en pruebas: servidor (#75) y pantallas: mis eventos por liga, selector de fase, pestaña Liga (fases, nueva fase, clasificación acumulada con medallas, podios) y reinscripción de otras fases (#81); puntos por asistir en Configuración; falta la prueba a mano (2026-11-12) | feat/league-phases-attendance |
| torneo | modulos/torneo.md | pendiente | – |
| marcador-tapiz | modulos/marcador-tapiz.md | pendiente | – |
| tiempo-real | modulos/tiempo-real.md | en pruebas: WebSocket de avisos "esto cambió" (marcador, tablero, Tapices, Puntuaciones) con sondeo de respaldo (2026-11-11) | feat/realtime-offline-web |
| offline | modulos/offline.md | pendiente | – |
| ranking | modulos/ranking.md | pendiente | – |
| notificaciones | modulos/notificaciones.md | pendiente | – |
| superadmin-reportes | modulos/superadmin-reportes.md | en curso: operaciones de evento (#64, en la Pi con la v0.3.1), métricas (#67) y usuarios (buscar, suspender, borrar) en pruebas; faltan reportes y el resto de eventos (2026-11-10) | feat/superadmin-users |

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
| rediseño neutro multideporte (pedido de Raul) | 07-diseno.md | en pruebas: tema neutro claro y oscuro (fijable en Ajustes), Atkinson Hyperlegible Next + Saira Condensed, tablero del árbitro (grupos en tinta), marcador y crear grupo con huecos (#57); resto de pantallas en `pendientes.md` (2026-11-08) | feat/design-neutral-groups |
| prototipo Fase 1 Yoseikan (uso real ≈ 2026-11-14) | modulos/prototipo-f1.md | en curso: back completo (pasos 1-3/7); front pasos 4-6/7 (login de `auth`, mis eventos, crear grupos; tablero del tapiz y marcador con campana; panel del club con puntuaciones, tapices, inscripciones, configuración y CSV). Probado a mano en Chrome (ayudante, árbitro y club). Paso 7 en curso: release `v0.1.0` fusionada y etiquetada (#36, 2026-11-04); release `v0.3.0` (#61) desplegada en la Pi el 2026-11-10 (`brackety.rgal.dev`, en la SD); falta el ensayo con varios dispositivos | – |
| prototipo F1: categorías por equipos | modulos/prototipo-f1-equipos.md | en pruebas: pasos 8-11 hechos (back, ayudante, árbitro, club con categorías editables). Falta: prueba manual de Raul (2026-11-02) | feat/proto-f1-teams-club |
| prototipo F1: importación masiva de alumnos | modulos/importacion-alumnos.md | en pruebas: pasos 1-3 hechos; `ANTHROPIC_API_KEY` puesta en la Pi y botón visible (2026-11-10). Falta: confirmar el DPA, una lectura real en la Pi y la prueba manual de Raul | – |
| servidor del pabellón (portátil Windows) y paquete del evento | modulos/servidor-local.md | en curso: pasos 1-3/4 hechos (APK con selector de servidor; 2026-11-05). Endurecido tras la revisión (`revision-f1.md`, servidor y pabellón): contraseñas aleatorias del paquete, sin puntuar antes de iniciar, refresh idempotente, acceso de 12 h, sin `X-Forwarded-For`, firewall solo del punto de acceso, bloqueo de evento al primer inicio, inscritos solo para el club, CSV, BitLocker e `icacls` (2026-11-06) | fix/f1-hardening-server |
| offline: adelanto F1 (marcador del árbitro) | modulos/offline.md | en pruebas: servidor (`opId`, `at`, `knownEvents`, revisión del club con `/review`) y app (cola y caché en el APK, tablero sin red, indicador, Aplicar/Descartar del club) hechos; falta la prueba manual de Raul y el escenario con un combate en revisión (2026-11-05) | feat/offline-f1-scoreboard |
| herramientas: plugins `playwright` y `frontend-design` + semántica para navegador automatizado | 08-ejecucion-local.md | cerrado: plugins del proyecto y `enableSemanticsForAutomation` en app y admin (#54). Revisión de F1 con Playwright en 3 tamaños: flujos de club, ayudante y árbitro sin fallos; arreglados etiquetas por esquina del marcador para lector de pantalla y plural de Tapices; el resto de diseño, en `pendientes.md` (2026-11-07) | – |
| prototipo F1: crear grupos (pedido de Raul) | modulos/prototipo-f1.md | en pruebas: sin multigrupo (Configuración y borrador), casilla en lugar del círculo con número, desplegable de tapiz Automático o a mano junto a "Crear grupo" (`matId` en la API), vuelta "Grupo por equipos" desde el grupo individual; falta prueba manual de Raul (2026-11-07) | feat/proto-f1-group-mat |
| F1: superadmin en el portátil, export .zip, resultados a la Pi y clubes (pedido de Raul, 2026-11-11) | modulos/servidor-local.md | en pruebas: superadmin solo en el portátil, todo el evento en .zip con CSV legibles, importar resultados en la Pi, clubes participantes; servidor de liga, fases y podios hecho, sus pantallas después de la F1; falta la prueba a mano (2026-11-11) | feat/league-phases |
| marcador F1: reglas y mesa (pedido de Raul, 2026-11-11) | modulos/prototipo-f1.md | en pruebas: descalificación 15-0, −1, ajuste de reloj, deshacer más claro, campana de ring y aviso de 10 s en la web, duración y límite en Configuración (F1 3:00), tablero con recomendado/en espera, deshacer grupo y simulaciones del recomendador; falta la prueba a mano (2026-11-11) | feat/scoreboard-f1-rules |
| F1 solo web en el pabellón (pedido de Raul, 2026-11-11) | modulos/offline.md | en pruebas: la web usa la cola offline (guardada en el navegador, sobrevive a recargas), sesión que aguanta recargas en http del pabellón, rescate de acciones por CSV (exportar en el dispositivo, importar en el club), paquete sin APK por defecto; falta la prueba a mano en portátil y Pi (2026-11-11) | feat/realtime-offline-web |
| marcador web: doble pulsación (pedido de Raul) | modulos/offline.md | cerrado: `knownEvents` obligatorio, 409 `MATCH_STALE` en la web, envío de una en una; probado a mano por Raul con dos pestañas (#59, 2026-11-09) | – |

## Hasta la Fase 1 (14-11)
Orden acordado con Raul el 2026-11-04 (una PR abierta cada vez):
1. Release `v0.1.0` y despliegue en la Pi.
2. `legal-paginas` pasos 1-2 (adelantado: datos reales de menores en la fase).
3. `servidor-local` pasos 1-3.
4. Offline: adelanto F1.
5. Ensayo general (`servidor-local` paso 4).
- Motivo prototipo: Raul necesita usar la app en la Fase 1 real en 15 días; adelanta versiones mínimas de eventos, inscripciones, grupos, marcador y ranking.
- Motivo sistema de diseño: fijar colores, tipografía, espaciado y componentes antes de la primera pantalla real (`auth`), para no repartir valores sueltos por el código.

## Bloqueos
Ver `pendientes.md`. Ninguno bloquea la fase 0.
