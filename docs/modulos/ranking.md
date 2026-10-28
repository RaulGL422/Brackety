# Módulo · ranking

## Objetivo
Clasificaciones por entidad, temporada y categoría, y global.

## Reglas
- Varias vistas: por **evento**, **temporada**, **categoría**, **entidad/club** y **global** de la app.
- Un ranking suma puntos de combates y de asistencia según la plantilla de deporte.
- Empates comparten posición; no hay desempate automático por ahora. En la tabla de una liga, aviso de empate en el podio con propuesta de combate o mini torneo.
- Visibilidad según el evento (todos, clubes, inscritos, nadie). Se puede cambiar.
- Menores: en vistas públicas, solo nombre y apellidos según lo que el evento permita; nunca foto.
- Al borrar una cuenta, los resultados quedan anonimizados en el ranking.
- Recalculado incremental al cerrar combates; recálculo completo disponible para el superadmin.

## Datos
`ranking_snapshot` (vista materializada o tabla), `season`.

## API (borrador)
`GET /rankings?scope=event|season|category|club|global&id=…`.

## Pantallas
Tablas con filtros, mi posición, histórico por temporada.

## Tests
Cada ámbito, empates, anonimizado, recálculo, categorías por fecha de corte.

## Estado
Pendiente.
