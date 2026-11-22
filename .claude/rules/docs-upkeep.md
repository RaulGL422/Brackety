# Reglas de documentación (ahorro de tokens)

- Mapa de qué vive dónde: `docs/README.md`.
- **Límite duro por MD de `docs/`: 150 líneas y 12.000 caracteres** (fuera `docs/historico/`). El CI falla si uno lo pasa (`tools/code_metrics.py --check`, límite 0). Antes de escribir, mira el tamaño (`wc -m`); si no cabe, divide por temas (`<doc>-<tema>.md`, enlazado desde el original) o mueve lo cerrado a `docs/historico/`. Nunca alargar las líneas.
- `docs/estado.md` es la única fuente de "qué está hecho": una línea por cosa (estado, doc y nº de PR), sin descripciones. Se actualiza al cerrar cada tarea.
- Decisión nueva o cambiada → una línea en `docs/decisiones.md` (fecha, decisión, motivo).
- Duda, prueba a mano o tarea de otra persona → `docs/pendientes.md`, en su sección. Lo hecho se borra de ahí.
- Un hecho vive en un solo MD; los demás lo enlazan. No copiar contenido entre docs.
- Los MDs de módulo siguen siempre las mismas secciones: Objetivo, Reglas, Datos, API, Pantallas, Offline, Tests, Estado.
- `docs/historico/` no se lee para trabajar ni se actualiza.
- Lenguaje de docs: español, frases cortas, listas, sin relleno ni historia (está en git).
