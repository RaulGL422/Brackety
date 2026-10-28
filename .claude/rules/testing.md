# Reglas de testing (detalle en docs/04-testing.md)

- Una tarea no está terminada sin tests de lo que añade. Un módulo no está cerrado sin su checklist de `docs/04-testing.md`.
- Backend: JUnit 5 + PostgreSQL 18 embebido (zonky, real, nunca H2; sin Docker). Tests de servicio para reglas de negocio y de controller para seguridad/permisos.
- Fechas en tests y escenarios siempre desde el `Clock` inyectado (fijo en tests). Ver `docs/08-ejecucion-local.md`.
- Cada módulo añade los escenarios de datos que necesite probar a mano (próximo a caducar, a punto de empezar, en curso, con muchas estadísticas…) y su run config.
- Front: widget test de cada pantalla crítica en 3 tamaños (móvil 360×800, tablet 800×1280, escritorio 1440×900).
- Motor de puntuación, sorteos y calendarios: tests deterministas con semilla fija y casos límite (grupos de 3, 4, 5, impares, 0 participantes).
- Front: unit de lógica, widget test por pantalla crítica. E2E solo en flujos críticos: login, inscripción, marcador, offline/sincronización.
- Ejecutar solo los tests afectados mientras se desarrolla; la suite completa corre en CI y antes de cerrar módulo.
- Test que falla = se arregla la causa; prohibido borrarlo o ignorarlo.
- Datos de prueba ficticios; nunca datos personales reales.
