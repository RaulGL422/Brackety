---
paths: ["app/**", "admin/**"]
---
# Reglas front (Flutter 3.47.x / Dart 3.13, Android + web)

## Estructura
`app/lib/features/<feature>/` con `data/` (repositorio, DTO), `state/` (providers) y `ui/` (pantallas y widgets). Código común en `app/lib/core/` (red, tema, i18n, offline, errores). `admin/` reutiliza `core` mediante un paquete local `packages/brackety_core` cuando haya código compartido real; no duplicar.

## Convenciones
- Estado: Riverpod. Navegación: go_router. HTTP: dio. Persistencia local/offline: drift (SQLite; en web, IndexedDB/WASM). Versiones exactas se fijan al crear el proyecto, no de memoria.
- Widgets pequeños y `const` siempre que se pueda; evitar árboles anidados de más de ~4 niveles: extraer widget.
- Nada de lógica de negocio en widgets: va en providers/repositorios.
- Cero strings fijos: todo por i18n (`es`, `en`). Fechas y números con `intl`.
- Listas largas con `ListView.builder`. Imágenes con tamaño y caché. Evitar rebuilds amplios (`select` en Riverpod).
- Peso del bundle web: sin paquetes que no se usen; revisar tamaño en cada release.

## Rendimiento (motivo de elegir esto sobre la experiencia previa)
- Medir antes de optimizar, pero prohibido: setState global, providers que reconstruyen pantallas enteras, listas sin builder.
- Pantallas de marcador y tapiz: tamaño táctil grande, cero animaciones pesadas, funcionar sin red.

## Accesibilidad y diseño
Seguir `docs/07-diseno.md`. Contraste suficiente, textos escalables, uso con una mano en el tapiz.

## Tests
Widget tests por pantalla crítica y unit tests de lógica; golden tests solo si el diseño está cerrado.
