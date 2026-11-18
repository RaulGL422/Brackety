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
- Por evento y por liga, con los puestos dentro de cada categoría (prototipo F1, `liga.md`).
- F2-4 (2026-11-17, rama `feat/f2-4-standings-config`): la liga decide si hay **clasificación global** (`league.global_standings`, apagada por defecto). Apagada, Puntuaciones y Liga no ofrecen «Todas las categorías»: una categoría cada vez, la primera de entrada. Se cambia en «Editar liga» y viaja en el paquete del pabellón.
- La categoría es solo por edad. Sexo y peso son informativos (Raul, 2026-11-17): dividir una categoría por ellos llegará cuando una modalidad lo pida.
- Descargas con nombre (Raul, 2026-11-18): liga, fase y qué es, p. ej. `liga-yoseikan-2027_fase-2_combates.csv`; los CSV por categoría añaden la categoría (`…_clasificacion_7-8.csv`) y la exportación completa es `…_exportacion-completa.zip`. Dentro del .zip completo, las hojas conservan su nombre corto (lo explica `LEEME.txt`).
- Resto (temporada, club, global de la app, visibilidad, anonimizado): pendiente.
