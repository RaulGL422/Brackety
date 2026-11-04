# Módulo · puntuacion

## Objetivo
Motor de puntuación configurable por plantilla de deporte, modalidad, fase y categoría.

## Conceptos
- **Plantilla de deporte**: modalidades, categorías y reglas. Predefinidas (Yoseikan primero; luego judo, karate, taekwondo, fútbol…) o personalizadas.
- **Regla de puntuación**: acciones que suman o restan (p. ej. suelo: 1,2,3,4,4,15) con límites (máx. por combate, una vez por técnica).
- **Puntos de asistencia** por fase (Yoseikan: 10, configurable).
- **Agregación**: suma por modalidades y fases hacia el total.
- Reglas por **modalidad + fase + categoría**; cada combinación puede tener su variante (tambo de 4-7 años distinto).
- Configuración en JSON versionado, con editor simple en la UI (sin lenguaje propio).
- Resultado de combate puede ser puntos por participante, ganador/empate o ambos.

## Grupos incompletos o con sobrante
- Falta 1: un alumno de otro grupo completa; sus puntos de ese grupo **no cuentan** en la tabla de ese grupo, pero sí en su propio grupo.
- Sobra 1: grupo mayor; opciones configurables en el evento: promedio por combate, puntos brutos o decidir caso a caso. **Pendiente de respuesta final.**

## Ranking
Ver `ranking.md`. Empates comparten posición; sin desempate automático por ahora.

## Datos
`sport_template`, `scoring_rule`, `match_result`, `score_entry`, `phase_attendance_points`.

## Tests
Casos reales de `reglamentos/yoseikan-2027.md`: cada rama de A.1 a A.5, límites (15, 30), técnica repetida, sumisión por tramo de edad, simultáneo anulado.

## Estado
Pendiente. Faltan: escalas de expresión técnica y tiempo de suelo (`pendientes.md`).
