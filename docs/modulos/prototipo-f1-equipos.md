# Módulo · prototipo-f1 · categorías por equipos

Ampliación de `prototipo-f1.md` (cambio de planes de Raul, 2026-10-31). Lo que no se dice aquí sigue igual que en individual.

## Objetivo
A partir de cierta edad, la categoría compite **por equipos de 3** en lugar de individual. El grupo pasa a ser de 4 equipos (12 alumnos). Las categorías individuales no cambian.

## Reglas
### Configuración de categorías (club)
- Cada categoría del evento: nombre, edad mín./máx., **formato** (`INDIVIDUAL` | `TEAM`), **tamaño de equipo** (solo `TEAM`, 3 por defecto) y **tamaño de grupo** (unidades por grupo: alumnos o equipos; 4).
- Prototipo: tamaño de grupo solo 4 (el nórdico de 4 es el único calendario); tamaño de equipo 2-5.
- Una categoría con equipos o grupos no cambia formato ni tamaños (409).
- Demo: las 4 categorías mayores (`15-16`, `17-19`, `20-25`, `26+`) son de ejemplo por equipos; las reales sustituyen a estas sin tocar código (son datos del evento).

### Equipos (ayudante)
- Categoría por equipos → alumnos por nombre o estatura → selecciona 3 → "Crear equipo".
- Nombre automático **"Equipo N"**, numerado por evento (no se repite entre tapices; el árbitro llama por ese nombre, no por los nombres reales).
- Orden de los miembros = orden de selección.
- Alumno en un equipo: fila deshabilitada, no desaparece (como al agrupar).
- Un equipo sin grupo se puede deshacer (borrar); con grupo, no.

### Grupos de equipos (ayudante)
- Lista de equipos de la categoría sin grupo → selecciona 4 → "Crear grupo". Multigrupo igual que en individual (colores, números, mismo tapiz).
- **Equipo fantasma**: casilla en el grupo; con 3 equipos seleccionados se eligen 3 alumnos cualesquiera de la categoría (también los que ya están en equipos o grupos, salvo los de los equipos de ese grupo). Forma "Equipo N (fantasma)": combate, no puntúa.
- Grupo = 4 equipos reales, o 3 + 1 equipo fantasma. Los equipos reales son siempre de 3 reales (sin alumno fantasma dentro).
- Tapiz: mismo criterio (menor fin estimado).

### Grupo individual dentro de una categoría por equipos
- Botón "Grupo individual": por si no salen equipos y se resuelve con individuales. Mismo flujo y reglas que una categoría individual (4, o 3 + fantasma).
- Solo con alumnos que no estén en un equipo real. Un alumno es real en un único sitio: un equipo o un grupo individual.

### Árbitro y marcador
- Combate = **un marcador Tambo equipo contra equipo**: rojo = equipo A, azul = equipo B. Mismas reglas (2:00, 15, avisos, deshacer, finalizar, campana); aviso de una mano si algún miembro tiene 4-7.
- Tablero y marcador muestran "Equipo N"; los nombres de los miembros, en pequeño debajo.
- Nórdico de 4 sobre equipos (1-2, 3-4, 1-3, 2-4, 1-4, 2-3), equipo fantasma al final.
- Recomendado: mismos pasos. Un equipo está ocupado si **cualquiera** de sus alumnos combate ahora en cualquier tapiz (también como fantasma). Descanso del equipo = el de su miembro con menos descanso.

### Puntuación global
- Cada miembro de un equipo real en un grupo: +10 por asistir + **los puntos de su equipo** en cada combate (descalificado: 0 en ese combate).
- Equipo fantasma: no suma nada a sus alumnos; su rival sí.
- La clasificación sigue siendo por alumno; la fila indica su equipo.

## Protecciones
- Índice único: un alumno real en un solo equipo real; y nunca a la vez en un equipo real y como real en un grupo individual (se comprueba al crear, con la fila del evento bloqueada).
- No se borra un alumno en un equipo ni se cambia su nacimiento (cambiaría la categoría): 409.

## Datos
- `event_category` + `format`, `team_size`, `group_size` (migración con valores por defecto: las categorías existentes quedan `INDIVIDUAL`, 4).
- `team` (evento, categoría, número único por evento, fantasma, autor, hora) y `team_member` (equipo, alumno, orden).
- `group_member` + `team_id`: cada fila es un alumno **o** un equipo (check).
- `fight_match` + `red_team_id`, `blue_team_id`: o alumnos o equipos (check).
- La puntuación se calcula de los combates, no se guarda por alumno.

## API
- `PUT /events/{id}/categories` (club; lista completa, las que faltan se borran; sin solapes de edad; la config la devuelve `GET /settings`) · `GET /events/{id}/categories` (ayudante) añade formato, tamaño de equipo, alumnos en equipo y nº de equipos.
- `GET|POST /events/{id}/categories/{cat}/teams` · `DELETE /teams/{id}` (sin grupo).
- `POST /events/{id}/groups`: cada grupo lleva `participantIds` + `ghostId`, o `teamIds` + `ghostTeam` (ids de los alumnos del equipo fantasma).
- Tablero y combate: cada lado añade `teamId`, `teamNumber` y `members`; en equipos `participantId` es null y `name` son los miembros. Clasificación: `teamNumber`. CSV: columna Equipo y "Equipo N (miembros)".
- Código: `grouping/Team*`, `CategoryRoster` (quién está libre o agrupado), `CompetitorDirectory` (alumno o equipo → nombre y alumnos; lo usan tablero, recomendado, marcador y clasificación).

## Pantallas
- Ayudante, categoría por equipos (`grouping/ui/team_category_screen.dart`, ruta `…/categories/{cat}/teams?name=&size=`): pestañas **Alumnos** (elegir 3 libres → crear equipo) y **Equipos** (deshacer equipo sin grupo; elegir 4, o 3 + casilla de equipo fantasma que abre una hoja con los alumnos de la categoría salvo los del propio grupo); botón "Grupo individual" abre la pantalla de siempre, donde quien tiene equipo solo puede ser fantasma. Mismo borrador (`GroupDraft`) y multigrupo que en individual.
- Árbitro y club (tablero, marcador, vista del combate, línea de tiempo): "Equipo N" como nombre y miembros en pequeño debajo (`mat/ui/fighter_text.dart`, común a alumnos y equipos).
- Club (`club/ui/categories_editor.dart`): en Configuración, categorías editables (añadir, editar nombre/edades/por equipos/alumnos por equipo, quitar), cada cambio se guarda solo; 409 y 400 se explican. Grupos de 4 fijo (solo lectura). Puntuaciones con "Equipo N"; tapices en solo lectura con equipos (paso 10).

## Tests
- Back: crear y deshacer equipo, número por evento, alumno en dos equipos (409), equipo fantasma con alumnos ya en equipos, grupo de equipos 4 y 3 + fantasma, grupo individual en categoría por equipos, recomendado con equipo ocupado por un miembro, puntuación por miembro, formato bloqueado con equipos, migración sin romper los eventos actuales.
- Front: crear equipo y grupo de equipos (3 tamaños), marcador con equipos.

## Plan (tras lo empezado; no rompe la PR #22)
8. Back: categorías con formato y tamaños, equipos, grupos y combates de equipos, recomendado, puntuación, CSV, demo con 4 categorías por equipos. Solo añade campos: se puede hacer en paralelo a la PR #22 (solo front).
9. Front ayudante: pestañas Alumnos/Equipos, equipo fantasma, "Grupo individual".
10. Front árbitro: tablero y marcador con equipos.
11. **Adaptación tras fusionar la PR #22** (choca con su código): panel del club con configuración de categorías editable, columna de equipo en puntuaciones y equipos en tapices.

El paso 7 (Pi) puede ir antes o después de estos; si la Fase 1 llega antes, se despliega sin equipos.

## Estado
Diseñado 2026-10-31. Paso 8 (back) hecho 2026-11-02 (PR #26): `TeamControllerTest`; escenario `yoseikan-f1` con 15 alumnos de 15-16. Paso 9 (front ayudante) hecho 2026-11-02: tests de borrador y widget en 3 tamaños; probado contra la API local. Paso 10 (árbitro) hecho 2026-11-02: tests de tablero y marcador con equipos en 3 tamaños. Paso 11 (club) hecho 2026-11-02. Los 4 pasos probados por Claude en Chrome sin interfaz; falta la prueba manual de Raul del módulo completo.
