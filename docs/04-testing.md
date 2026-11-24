# 04 · Testing

Objetivo: calidad sin horas de QA manual. Los tests se escriben con la tarea, en su rama, y se cierran por módulo.

## Pirámide
| Nivel | Herramienta | Qué cubre |
|---|---|---|
| Unitario backend | JUnit 5 | Motor de puntuación, sorteo, calendario, permisos |
| Integración backend | PostgreSQL 18 embebido (zonky) | Repos, Flyway, seguridad, endpoints |
| Unitario front | `flutter test` | Lógica de providers y repositorios |
| Widget | `flutter test` | Pantallas críticas (marcador, inscripción) |
| E2E | Solo flujos críticos | Login, inscripción por QR, marcador offline → sync |

## Cuándo se ejecuta qué (Raul, 2026-11-16)
| Momento | Qué |
|---|---|
| Desarrollo | Tests del módulo tocado |
| PR a `development` | Componentes tocados (app, admin, core); del server, solo los módulos tocados + docs |
| Release a `main` | Batería completa: todo, E2E, despliegue y restauración |
| Cierre de módulo | Suite del componente + checklist de abajo |
- CI (`ci.yml`): una PR a `development` solo prueba los componentes que toca; a `main`, todo. El check que se pide es `ci-ok` (`producto/calidad.md`).
- Server en PR a `development`: tests de los paquetes tocados, `ArchitectureTest` y, si cambia un controller, la matriz de permisos (`tools/server_tests.py`). Fuera de los paquetes (pom, recursos, migraciones, `spec/`): todo.

## Checklist de cierre de módulo
- [ ] Reglas del MD del módulo cubiertas por tests (una regla = al menos un test).
- [ ] Casos límite: vacíos, impares, 1 participante, duplicados, fechas límite.
- [ ] Permisos: cada acción protegida tiene test de "permitido" y "denegado".
- [ ] Menores y privacidad (fotos nunca públicas, datos mínimos) si el módulo los toca.
- [ ] Offline: escenario sin red y sincronización, si el módulo lo exige.
- [ ] Sin N+1 en listados principales.
- [ ] Pantallas probadas en móvil, tablet y escritorio (widget tests a 3 tamaños).
- [ ] Escenarios de datos del módulo en `08-ejecucion-local.md` con su run config.
- [ ] CI verde y `estado.md` actualizado.

## Batería del servidor (reglas duras, Raul 2026-11-22)
Obligatoria en cada release y cierre de módulo; cada punto, con su test en `server/src/test` (lo que falte, en `producto/feedback-grappling.md`, GR-8).
- **Día completo por formato** (liga por fases, torneo suelto, grappling, equipos), al menos 5 semillas: de inscribir a descargas, con incidentes a mitad (tapiz inhabilitado, árbitro sin sesión, combate reabierto, revisión, fase reabierta). Al final: todos los combates disputados, clasificación y descargas de oro coherentes.
  Torneo, liga de dos fases y día con equipos: `TournamentDayTest`, una semilla en cada PR y 5 en las de release (`-Dbattery.seeds=5`).
- **Concurrencia**: dos dispositivos a la vez sobre el mismo combate, grupo o alumno; renovaciones de sesión simultáneas. Nunca dos estados ni datos perdidos.
- **Sesiones**: con reloj simulado, una sesión (normal y temporal por QR) aguanta la fase entera con red perdida y reintentos fuera de tiempo; solo se cierra por fin de fase, «Quitar acceso» o robo real.
- **Matriz de permisos**: cada endpoint × cada rol y permiso (club, ayudante, árbitro, temporal, ajeno al evento, sin sesión). Un endpoint sin fila en la matriz hace fallar el test.
- **Ataques**: ids de otro evento (IDOR), cuenta temporal fuera de su evento, entradas límite y mal formadas, tokens caducados o reutilizados, límites de peticiones.
- **Paquete del pabellón**: ida y vuelta completa (Pi → portátil → Pi) sin perder ni duplicar nada.
- **Migraciones**: Flyway desde cero y desde el esquema de la última release con el escenario `yoseikan-f1`.
  `MigrationFromReleaseTest`: carga los datos de la release (`test/resources/migration/release/`), migra y sigue
  el día (marcador, tablero, clasificación, descargas, cerrar fase). Desde cero: todos los demás tests.
  Tras etiquetar una release, en la PR `chore/sync-main`: servidor de esa etiqueta con `yoseikan-f1` en 8093/15434
  y `java -cp postgresql.jar tools/MigrationSnapshot.java http://localhost:8093`
  `jdbc:postgresql://localhost:15434/postgres server/src/test/resources/migration/release vX.Y.Z`.

## Determinismo
Sorteos con semilla guardada: test que repite la semilla y obtiene el mismo resultado. Tiempo por reloj inyectable.

## Reglamentos
Cada reglamento (`docs/reglamentos/`) tiene una batería de tests con ejemplos de puntuación reales de sus anexos.

## Cierre de proyecto
Antes de abrir al público: pasada de seguridad, prueba de restauración de backup, prueba de carga (20 simultáneos + WebSocket), revisión legal (`06-legal-rgpd.md`).
