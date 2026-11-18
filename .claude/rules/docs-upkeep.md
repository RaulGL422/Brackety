# Reglas de documentación (ahorro de tokens)

- Mapa de qué vive dónde: `docs/README.md`.
- Cada MD de `docs/` ≤ 150 líneas (lo comprueba el CI) y ≤ 12.000 caracteres (lo vigila `tools/code_metrics.py`: el número de docs que lo pasan solo puede bajar). Si crece, dividir en dos o mover lo cerrado a `docs/historico/`, nunca alargar las líneas.
- `docs/estado.md` es la única fuente de "qué está hecho": una línea por cosa (estado, doc y nº de PR), sin descripciones. Se actualiza al cerrar cada tarea.
- Decisión nueva o cambiada → una línea en `docs/decisiones.md` (fecha, decisión, motivo).
- Duda, prueba a mano o tarea de otra persona → `docs/pendientes.md`, en su sección. Lo hecho se borra de ahí.
- Un hecho vive en un solo MD; los demás lo enlazan. No copiar contenido entre docs.
- Los MDs de módulo siguen siempre las mismas secciones: Objetivo, Reglas, Datos, API, Pantallas, Offline, Tests, Estado.
- `docs/historico/` no se lee para trabajar ni se actualiza.
- Lenguaje de docs: español, frases cortas, listas, sin relleno ni historia (está en git).
