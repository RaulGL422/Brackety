# Reglas de testing (detalle en docs/04-testing.md)

- Una tarea no está terminada sin tests de lo que añade. Un módulo no está cerrado sin su checklist de `docs/04-testing.md`.
- Backend: JUnit 5 + PostgreSQL 18 embebido (zonky, real, nunca H2; sin Docker). Tests de servicio para reglas de negocio y de controller para seguridad/permisos.
- Fechas en tests y escenarios siempre desde el `Clock` inyectado (fijo en tests). Ver `docs/08-ejecucion-local.md`.
- Cada módulo añade los escenarios de datos que necesite probar a mano (próximo a caducar, a punto de empezar, en curso, con muchas estadísticas…) y su run config.
- Front: widget test de cada pantalla crítica en 3 tamaños (móvil 360×800, tablet 800×1280, escritorio 1440×900).
- Motor de puntuación, sorteos y calendarios: tests deterministas con semilla fija y casos límite (grupos de 3, 4, 5, impares, 0 participantes).
- Front: unit de lógica, widget test por pantalla crítica. E2E solo en flujos críticos: login, inscripción, marcador, offline/sincronización.
- En desarrollo y en las PR, solo los tests de los módulos tocados. Batería completa (todos los tests, E2E, despliegue y restauración) antes de cada release a `main` y al cerrar módulo. Tabla en `docs/04-testing.md`.
- **Batería completa del servidor endurecida** (`docs/04-testing.md`, «Batería del servidor»): simulación del día completo por formato con varias semillas e incidentes, concurrencia, sesiones durante toda una fase, matriz de permisos de todos los endpoints y ataques de acceso. Una release no sale si falta alguna o falla.
- Cada fallo visto en un evento real o por Raul empieza por un test que lo reproduce (rojo) y después el arreglo.
- Un test de servidor nuevo comprueba el resultado completo (filas en BD, respuesta y lo que ven los demás roles), no solo el código HTTP.
- Test que falla = se arregla la causa; prohibido borrarlo o ignorarlo.
- Datos de prueba ficticios; nunca datos personales reales.
