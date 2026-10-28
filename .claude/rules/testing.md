# Reglas de testing (detalle en docs/04-testing.md)

- Una tarea no está terminada sin tests de lo que añade. Un módulo no está cerrado sin su checklist de `docs/04-testing.md`.
- Backend: JUnit 5 + Testcontainers (PostgreSQL 18 real, nunca H2). Tests de servicio para reglas de negocio y de controller para seguridad/permisos.
- Motor de puntuación, sorteos y calendarios: tests deterministas con semilla fija y casos límite (grupos de 3, 4, 5, impares, 0 participantes).
- Front: unit de lógica, widget test por pantalla crítica. E2E solo en flujos críticos: login, inscripción, marcador, offline/sincronización.
- Ejecutar solo los tests afectados mientras se desarrolla; la suite completa corre en CI y antes de cerrar módulo.
- Test que falla = se arregla la causa; prohibido borrarlo o ignorarlo.
- Datos de prueba ficticios; nunca datos personales reales.
