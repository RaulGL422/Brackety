# Plantillas de deporte y de arbitraje

Idea de Raul (2026-11-18), apuntada para diseñarla con `modulos/puntuacion.md`. Todavía no es una decisión: las dudas están en `pendientes.md`.

## Objetivo
Que cualquier modalidad y su forma de arbitrar se creen **desde la propia app**, sin programar, y queden como plantillas reutilizables, duplicables y editables. Más adelante, un modo público donde la gente comparte sus configuraciones y sus deportes inventados con sus normas.

## Qué lleva una plantilla
### Deporte (modalidad)
- Nombre, descripción, idioma y nombre de la ubicación (Tapiz, Pista, Campo).
- Formato: individual, equipos (tamaño), o los dos.
- Cómo se gana: por puntos, por tiempo, por decisión de jueces, por nota (expresión técnica) o combinación.
- Acciones que puntúan: nombre, valor (+1, +2, −1…), límites (una vez por técnica, máximo por combate) y si dan la victoria directa.
- Tiempo: duración, prórroga, fuera de tiempo, descanso mínimo, cambio entre combates.
- Disciplina: motivos de advertencia, "cada N advertencias, +1 al rival", descalificación.
- Desempates y cómo se clasifica (por categoría, sexo, peso, edad; global sí o no).
- Datos que pide: peso, estatura (no / opcional / obligatorio).
- Categorías sugeridas (edades, sexo, peso) y reglas que cambian por categoría.
- Reglamento PDF opcional.

### Arbitraje
- Papeles por ubicación: árbitro central, jueces (cuántos), mesa o cronometrador.
- Cómo se decide: árbitro único, mayoría de jueces, media de notas quitando la más alta y la más baja…
- Qué marca cada papel en su dispositivo y qué permisos lleva (enlaza con los permisos por persona de `modulos/ayudantes-permisos.md`).
- Rotación: si el árbitro cambia por grupo, por combate o se queda todo el evento.

## Cómo se usa
- **Crear** desde cero con un asistente, o **duplicar** una existente (la de Yoseikan tambo, la de un amigo, una pública) y cambiar lo que difiere.
- **Probar** antes de usarla: un marcador de prueba con la plantilla, sin guardar resultados.
- **Usar** en un evento: el evento guarda la **versión** que usó. Editar la plantilla crea una versión nueva y no cambia resultados ya jugados.
- **Ajustar en el evento**: el evento puede cambiar alguna regla sin tocar la plantilla (como hoy los motivos de advertencia).

## Visibilidad
| Nivel | Quién la ve |
|---|---|
| Privada | Solo su dueño (cuenta o club) |
| Compartida por enlace | Quien tenga el enlace puede verla y duplicarla |
| Pública | En la galería: buscar por deporte, idioma, popularidad; duplicar con atribución ("basada en…") |
| Oficial | Revisada por el superadmin (Yoseikan, judo, karate…), marcada como tal |

Lo público necesita: denunciar, ocultar desde el superadmin, nombre del autor (o anónimo) y aceptar unas condiciones al publicar. Sin datos personales dentro de una plantilla.

## Qué implica en el código
- Es la fase L7 de `plan-limpieza.md`: el **motor de reglas por datos**. Hoy cada deporte está escrito en código (`Discipline`, `TamboMatch` en Java y Dart); una plantilla creada en la app necesita un motor que la interprete.
- Datos (propuesta): `sport_template` (dueño, visibilidad, origen si es un duplicado) y `sport_template_version` (inmutable, JSON con `schemaVersion`). La `modality` del evento apunta a una versión y guarda solo lo que el evento cambia.
- El JSON se valida en el servidor con un esquema; la app usa el mismo esquema para el editor. Sin lenguaje propio ni fórmulas libres (decisión de `puntuacion.md`): solo piezas fijas que se combinan.
- Offline: el paquete del pabellón y la caché de la app llevan la versión entera.
- Todo lo que hoy es "si es tambo…" pasa a "lo que diga la plantilla".

## Orden propuesto
1. Motor por datos con tambo como primera plantilla (sin editor): mismos resultados que hoy, comprobación de oro.
2. Plantillas de la F2 (armas) y F3 (expresión técnica) como datos.
3. Editor en la app: duplicar y editar privadas; probar en marcador de prueba.
4. Arbitraje configurable (papeles, jueces, decisión).
5. Compartir por enlace.
6. Galería pública con moderación.

## Estado
Idea apuntada (2026-11-18). Preguntas abiertas en `pendientes.md` (Producto).
