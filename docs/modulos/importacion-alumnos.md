# Módulo · importación masiva de alumnos (prototipo)

Pedido por Raul el 2026-11-02 para inscribir muchos alumnos a la vez en pruebas in situ. Amplía las inscripciones del prototipo (`prototipo-f1.md`); una inscripción importada es igual que una hecha a mano.

## Objetivo
El club sube fotos de una lista, un CSV, un Excel, un TXT o texto pegado; Claude lo lee; el club revisa, corrige y confirma; se inscriben todos de una vez.

## Reglas
### Subir
- Botón "Importar alumnos" en Inscripciones (solo club). Oculto si el servidor no tiene `ANTHROPIC_API_KEY`.
- Hasta 10 fotos (JPG, PNG, WebP) a la vez, o un archivo (CSV, XLSX, TXT), o texto pegado. 10 MB por archivo.
- Formato pedido (con plantilla CSV descargable): una fila por alumno con nombre, apellidos, fecha de nacimiento (dd/mm/aaaa), estatura en cm (opcional), categoría (opcional).
- Consentimiento obligatorio antes de enviar (texto versionado, ver Legal). Cubre el "el tutor está de acuerdo" de cada menor de la lista.

### Revisar (nada se guarda aún)
- Una fila por alumno: correcta (con su categoría), error (qué falla, en concreto) o aviso (Claude no lo leyó con seguridad).
- Errores: falta un dato obligatorio, fecha inválida o futura, estatura fuera de 50-250 cm, sin categoría para su edad, repetido en la lista, ya inscrito (mismo nombre, apellidos y nacimiento).
- Categoría escrita que no cuadra con la edad: error con dos botones, "Usar la indicada" o "Usar la de su edad"; al elegir deja de ser error.
- El club edita cualquier fila (mismo formulario que "Añadir"), la quita o añade otra. Cada cambio se revalida.
- "Inscribir N alumnos" solo sin errores.

### Inscribir
- Todo o nada (decidido por Raul): el servidor revalida la lista entera; si una fila falla, no se guarda ninguna y vuelve a la revisión con las filas marcadas.
- Límites: 200 alumnos por importación; 10 lecturas por hora por cuenta (coste de la API).

### Categoría elegida
- Hoy la categoría sale de la edad el día del evento. Nuevo: una inscripción puede llevar una categoría elegida; si la lleva, manda esa.
- Un único punto del código resuelve la categoría de un alumno (grupos, equipos, puntuaciones, listas).
- El formulario de inscripción tiene el mismo selector ("Automática por edad" por defecto).
- Con grupos o equipos no cambia (como la fecha de nacimiento).

### Lectura con Claude
- `claude -p` en una carpeta temporal con los archivos, solo con permiso de lectura de esa carpeta; respuesta JSON con esquema fijo; un reintento si no cumple.
- El XLSX se convierte a texto en el servidor (Claude no lee `.xlsx`).
- Claude propone, el servidor decide: todas las reglas de arriba las aplica el servidor.
- La carpeta temporal se borra siempre, también si falla. No se guarda ningún archivo ni imagen.
- Máximo 90 s. Logs sin datos personales (solo filas y tiempos).

## Legal
- Anthropic, nuevo encargado de tratamiento (`06-legal-rgpd.md`): solo lee la lista; API con condiciones comerciales (sin entrenamiento) y su DPA.
- Autenticación con `ANTHROPIC_API_KEY`, no con el token de suscripción (`claude setup-token`): las condiciones de consumidor no cubren datos de terceros.
- Texto del consentimiento (v1): "Confirmo que todos los alumnos de esta lista, y sus tutores si son menores, han aceptado inscribirse en este evento sin excepción, y que la lista se procesará con un servicio de IA externo (Anthropic) solo para leerla. Las imágenes y archivos no se guardan."
- Pendiente de Raul: aceptar el DPA de Anthropic y confirmar su plazo de conservación de datos de la API.

## Datos
- `participant` + `category_id` (nullable, FK a `event_category`): categoría elegida.
- `participant_import` (evento, cuenta, nº de alumnos, versión del consentimiento, hora). Sin nombres ni archivos.

## API
- `POST /events/{id}/participants/import/read` (club, multipart: `files[]` o `text`; `consentVersion`) → filas validadas con errores y avisos por campo.
- `POST /events/{id}/participants/import` (club, JSON: filas + `consentVersion`) → 201 con el número inscrito, o 422 con los errores por fila.
- `POST /events/{id}/participants/import/check` (club, JSON: filas) → revalida tras editar, sin Claude.
- `GET /events/{id}/participants/import/available` → si la lectura con IA está configurada.

## Pantallas
- Inscripciones: botón "Importar alumnos".
- Paso 1: elegir fotos o archivo, o pegar texto; formato y plantilla; consentimiento; "Leer lista" con progreso.
- Paso 2: revisión (lista en móvil, tabla en escritorio): estado por fila, editar, quitar, añadir, elegir categoría; "Inscribir N alumnos".
- Responsive, textos i18n.

## Offline
No aplica: necesita conexión con el servidor y con Anthropic.

## Tests
- Back: validación de filas (cada error), categoría que no cuadra y elección, duplicados en lista y con inscritos, todo o nada, consentimiento obligatorio, solo club, límite de filas y de lecturas, XLSX a texto, `ListReader` falso (los tests nunca llaman a Claude), categoría elegida en grupos y puntuaciones.
- Front: subir, revisar y editar, inscribir, en 3 tamaños. Prueba de Claude en Chrome con una lista ficticia.

## Plan (PRs en serie)
1. Back: categoría elegida, `ListReader` con `claude -p`, endpoints, validación, registro, migración, docs legales.
2. Front: importar, revisar, inscribir; selector de categoría en el formulario.
3. Despliegue: imagen del servidor con Node y `claude`, `ANTHROPIC_API_KEY` en `.env.example` y `09-despliegue.md`.

## Estado
Diseñado 2026-11-02; en curso el paso 1.
