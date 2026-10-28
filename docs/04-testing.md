# 04 · Testing

Objetivo: calidad sin horas de QA manual. Los tests se escriben con la tarea, en su rama, y se cierran por módulo.

## Pirámide
| Nivel | Herramienta | Qué cubre |
|---|---|---|
| Unitario backend | JUnit 5 | Motor de puntuación, sorteo, calendario, permisos |
| Integración backend | Testcontainers + PostgreSQL 18 | Repos, Flyway, seguridad, endpoints |
| Unitario front | `flutter test` | Lógica de providers y repositorios |
| Widget | `flutter test` | Pantallas críticas (marcador, inscripción) |
| E2E | Solo flujos críticos | Login, inscripción por QR, marcador offline → sync |

## Checklist de cierre de módulo
- [ ] Reglas del MD del módulo cubiertas por tests (una regla = al menos un test).
- [ ] Casos límite: vacíos, impares, 1 participante, duplicados, fechas límite.
- [ ] Permisos: cada acción protegida tiene test de "permitido" y "denegado".
- [ ] Menores y privacidad (fotos nunca públicas, datos mínimos) si el módulo los toca.
- [ ] Offline: escenario sin red y sincronización, si el módulo lo exige.
- [ ] Sin N+1 en listados principales.
- [ ] CI verde y `estado.md` actualizado.

## Determinismo
Sorteos con semilla guardada: test que repite la semilla y obtiene el mismo resultado. Tiempo por reloj inyectable.

## Reglamentos
Cada reglamento (`docs/reglamentos/`) tiene una batería de tests con ejemplos de puntuación reales de sus anexos.

## Cierre de proyecto
Antes de abrir al público: pasada de seguridad, prueba de restauración de backup, prueba de carga (20 simultáneos + WebSocket), revisión legal (`06-legal-rgpd.md`).
