# Exportaciones a medida

Pedido de Raul (2026-11-19): una pantalla de exportación donde se eligen los campos, su orden y cómo se ordenan las filas, para sacar los documentos con tablas totalmente personalizadas. Propuesta con las respuestas de Raul del 2026-11-19 (`../decisiones.md`).

## Hoy
- 8 descargas fijas (`ranking/`): inscritos, categorías, tapices, grupos, combates, línea de tiempo, clasificación de fase y de liga (CSV, .zip por categoría, PDF) y la exportación completa.
- Cada una con sus columnas y su orden escritos en Java (`EventSheets`, 498 líneas, 6 CSV a mano; `LeagueStandingsService`, `StandingsService`).
- Cabeceras en español fijas en el código: no hay versión en inglés.
- Lo bueno que se conserva: protección contra fórmulas en CSV (`Csv`), `;` y BOM para el Excel en español, nombres de archivo claros (`DownloadNames`), PDF por categoría.
- F2-3 sigue abierto: la entidad ve confusos los puestos "1.º" en Excel. Con columnas configurables, cada uno elige "1" o "1.º".

## La pantalla
### Pasos (en móvil, uno por pantalla; en escritorio, configuración a la izquierda y vista previa a la derecha)
1. **Qué datos**: Inscritos, Clasificación de la fase, Clasificación de la liga, Combates, Acciones del combate, Grupos, Tapices, Advertencias y descalificaciones, Pagos y asistencia.
2. **Columnas**: lista de casillas con los campos de esos datos. Se reordenan arrastrando **y** con botones subir/bajar (arrastrar no es accesible). Cada columna admite un título propio ("Club" → "Escuela").
3. **Filtros**: categoría, club, sexo, edad, peso, fase, tapiz, estado (disputado, pendiente…).
4. **Orden de las filas**: varias claves en orden de prioridad (categoría ↑, puesto ↑, puntos ↓), cada una ascendente o descendente.
5. **Separar por**: nada, o una tabla por categoría, club, tapiz o grupo (una hoja o página por valor; en CSV, un .zip). Generaliza el .zip y el PDF por categoría de hoy.
6. **Formato**: CSV (Excel en español), Excel `.xlsx`, PDF (vertical u horizontal, título, fecha, pie con la versión). Idioma de las cabeceras: español o inglés.
7. **Vista previa**: las primeras 20 filas tal y como saldrán, antes de descargar.

### Configuraciones guardadas
- **Guardar como plantilla de exportación** ("Clasificación para la web", "Lista para la mesa"): se reutiliza, duplica y edita, como las plantillas de deporte (`plantillas-deporte.md`).
- Alcance: del evento, de la liga (sirve en todas sus fases) o de la cuenta (sirve en todos sus eventos).
- **Las 8 descargas de hoy pasan a ser plantillas incluidas**, no código aparte. Un solo camino para todo.
- **No se comparten entre clubes** (Raul): cada plantilla es de su dueño. Más adelante se podrán elegir para enviar resultados por correo (`modulos/notificaciones.md`).

### Datos personales (`../06-legal-rgpd.md`)
- Cada campo lleva su sensibilidad: normal (nombre, club, puntos), personal (fecha de nacimiento, peso, estatura) o de menores o tutor.
- Los campos personales solo los ve quien tenga el **permiso propio «Descargar datos personales»** (Raul): permiso nuevo en «Personal» (`modulos/ayudantes-permisos.md`); el club lo da a quien quiera. Sin él, esos campos no aparecen. Avisan antes de descargar.
- Opción **"Para publicar"**: nombre e inicial del apellido, sin edad exacta ni peso. Pensado para la web o las redes del club.
- Cada exportación con datos personales queda en la auditoría (quién, cuándo y qué columnas), sin guardar el archivo.

## Cómo se hace por dentro
- **Servidor, un registro de datos**: cada conjunto (Inscritos, Combates…) declara sus campos una sola vez: clave, título ES/EN, tipo (texto, número, fecha, duración, puesto), sensibilidad y cómo se obtiene. Las 6 funciones de CSV a mano se convierten en estas declaraciones.
- **Un endpoint**: `POST /api/v1/events/{id}/exports` con la configuración (`sheet`, `columns`, `titles`, `filters`, `sort`, `splitBy`, `locale`, `format`: `csv`, `xlsx` o `pdf`; en PDF, `title` y `landscape`). Filtro: uno de varios valores (`anyOf`, el texto tal y como sale) y, en columnas de número, `min`/`max`. Con `splitBy`, un .zip con un CSV por valor o, en `.xlsx` y PDF, una hoja o página por valor en el mismo archivo. El servidor valida todo contra el registro: hoja o columna desconocida o repetida, o rango en una columna de texto → 400 con `code` (`EXPORT_UNKNOWN_SHEET`, `EXPORT_UNKNOWN_COLUMN`, `EXPORT_REPEATED_COLUMN`, `EXPORT_FILTER_NOT_A_NUMBER`).
- `GET .../exports/sheets?locale=es|en` devuelve cada hoja con sus campos (título, tipo, sensibilidad); la pantalla se construye con eso, sin listas repetidas en la app.
- Vista previa: `POST .../exports/preview`, la misma configuración sin separar; JSON con 20 filas y el total.
- Formatos: `Csv` y `StandingsPdf` de hoy, generalizados, y `.xlsx` con `fastexcel` 0.20.3 (Apache 2.0, solo escribe): números y fechas como tales, títulos en negrita y fijos, un texto nunca es fórmula.
- Plantillas guardadas: tabla `export_preset` (dueño, alcance, nombre, configuración en JSON con `schemaVersion`).
- Funciona igual en el portátil del pabellón (todo ocurre en el servidor) y la configuración viaja en el paquete.
- Tests: la **comprobación de oro** de `plan-limpieza.md` (L0) exige que las 8 plantillas incluidas saquen exactamente los mismos archivos que hoy; tests de permisos (campo personal sin permiso → 403) y de la protección contra fórmulas.

## Encaje con el plan de limpieza
- Es la forma natural de partir `EventSheets` y los CSV de `LeagueStandingsService` (L5): se borra código en vez de moverlo.
- Pide antes la comprobación de oro (L0, paso 5) y los errores con `code` (L3).

## Orden propuesto
1. Registro de datos y endpoint; las 8 descargas de hoy como plantillas incluidas, mismos archivos (sin cambio visible).
2. Pantalla: datos, columnas y orden de columnas, orden de filas, vista previa, CSV y PDF.
3. Filtros, separar por, `.xlsx`, idioma de cabeceras y "Para publicar".
4. Plantillas guardadas (evento, liga, cuenta) y su paso por el paquete del pabellón.
5. Usar las plantillas en los correos de resultados.

## Estado
Aprobada en lo básico (2026-11-19): permiso propio para datos personales, `.xlsx` sí, plantillas sin compartir entre clubes.
- Paso 1a hecho: registro (`ranking/*Sheet`, `ExportField`, `Exports`) con las hojas de la exportación completa (inscritos, categorías, tapices, grupos, combates, línea de tiempo); salen igual que antes (comprobación de oro). Fuera `EventSheets`. Ordenar por varias columnas, nombres en orden español, vacíos al final.
- Paso 1b hecho: clasificación de la fase y de la liga como hojas (`StandingsSheet`, `LeagueSheet`); la de la liga, con tres columnas por fase. Victorias y puntos de clasificación, en la hoja fija solo si el evento los tiene (grappling).
- Paso 3, parte del servidor (rama `feat/exportaciones`): filtros, «Separar por» y título propio por columna. El .zip de la liga por categoría ya es una hoja fija (la liga separada por categoría, con columna «Fase N»). `.xlsx` y PDF de cualquier hoja hechos (PDF: título propio o el de la hoja, evento y fecha, pie con fecha y versión; apaisado solo si se pide o con más de 6 columnas; estilo compartido en `PdfStyle`). Falta «Para publicar»: los nombres completos salen también en columnas compuestas (rojo, azul, ganador, cómo acabó); decidir con Raul junto con la pantalla.
- Hoy solo el club exporta y ve todo: el permiso «Descargar datos personales» llega con la pantalla (paso 2).
