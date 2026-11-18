# Revisión de diseño: pulido, accesibilidad y pantallas más ligeras

Pedido de Raul (2026-11-18): todo mucho más pulido, accesible e intuitivo (paleta, letras, posiciones), con **más pantallas en vez de pantallas sobrecargadas**, responsive y profesional. Es la tarea 4 de la etapa 3 (`calidad.md`). Tokens y reglas base: `../07-diseno.md` (no se repiten aquí).

## Diagnóstico (desde el código y las revisiones con Playwright)
- **La base es buena**: tokens respetados, tipografía legible (Atkinson + Saira), contraste AA probado en `theme_test.dart`, táctil de 48/72, diálogos desplazables.
- **El problema es de estructura, no de estilo**: pantallas que hacen 3-5 cosas a la vez. `settings_tab` (545 líneas, un formulario de 7 temas), `team_category_screen` (992, hace equipos, grupos y comodines), `mat_board_screen` (915, combate destacado, cola, grupos y avisos).
- Escritorio desaprovechado: pantallas del club a todo el ancho, sin lista + detalle (`pendientes.md`, Diseño tras la F1).
- Textos con punto medio ("6 años · 132 cm") en vez de columnas con etiqueta.
- Lector de pantalla: 7 `Semantics` en toda la app; listas que se leen como un bloque; el marcador no anuncia los cambios de puntos.
- Pestañas que no son rutas: recargar pierde dónde estabas (`auditoria-codigo.md`, punto 7).
- "Tapiz" fijo en los textos aunque el deporte diga Pista o Campo.

## Principios nuevos (se añaden a `07-diseno.md` cuando Raul los apruebe)
1. **Una pantalla, una tarea.** Si una pantalla responde a dos preguntas ("¿quién compite ahora?" y "¿cómo configuro los tapices?"), son dos pantallas.
2. **Una acción principal por pantalla**, botón relleno y siempre en el mismo sitio (abajo a la derecha en escritorio, barra inferior en móvil). El resto, secundarias o en menú.
3. **Lo avanzado, plegado o en otra pantalla.** Los valores por defecto vienen de la plantilla del deporte y se explican en una línea.
4. **Lista y detalle**: en compacta, dos pantallas; en expandida, las dos a la vez. Mismo código.
5. **Estados completos**: cada pantalla con vacío (qué hacer para llenarla), cargando (esqueleto, no spinner a pantalla completa), error (qué pasó y botón de reintentar) y sin red.
6. **Datos en columnas con etiqueta**, nunca unidos por puntos medios.
7. **Vocabulario del deporte**: el nombre de la ubicación sale del evento (Tapiz, Pista, Campo).

## Pantallas que se dividen
| Hoy | Propuesta |
|---|---|
| Configuración del evento (un formulario) | Ajustes con secciones, cada una su pantalla: Datos, Reglas (heredadas de la plantilla), Ubicaciones, Personal, Medidas, Advertencias, Reglamento. Lista a la izquierda en escritorio |
| Categoría por equipos | Tres pasos con su pantalla: Hacer equipos → Formar grupos → Comodines, con indicador de paso |
| Tablero del árbitro | "Ahora" (combate en curso y siguiente, grande) y "Cola del tapiz" (lista); en escritorio, lado a lado |
| Panel del club (4 pestañas) | Preparar · Directo · Resultados (`eventos-ux.md`), con rutas propias |
| Crear grupo | Alumnos disponibles y grupo en construcción; en móvil, el grupo como hoja inferior |
| Importar alumnos | Subir → Revisar → Confirmar, una pantalla por paso |

## Componentes que faltan (en `brackety_core`)
- `SectionCard`: título, descripción corta y contenido; base de Ajustes.
- `LabeledValues`: pares etiqueta-valor en columnas; sustituye los puntos medios.
- `StatusTag`: estado con icono y palabra (En curso, Siguiente, Inhabilitado, Finalizada).
- `EmptyState`, `ErrorState` y `LoadingSkeleton` comunes.
- `ListDetailLayout`: lista + detalle adaptable a la clase de ventana.
- `StepFlow`: pasos numerados para los asistentes (crear evento, equipos, importar).

## Paleta y tipografía
- La paleta neutra se mantiene (el color es del competidor, decisión del 2026-11-08).
- Pregunta a Raul (`pendientes.md`): un acento de marca **solo para navegación y enlaces**, fuera de los 12 colores de competidor, para que la app no se vea gris plana. Sin respuesta, se sigue sin acento.
- Escala de texto con papel fijo, para que todas las pantallas se lean igual:
  | Papel | Uso |
  |---|---|
  | `displayLarge` (Saira) | Reloj y puntos del marcador |
  | `headlineMedium` (Saira) | Título de pantalla en escritorio, número de tapiz |
  | `titleLarge` | Título de pantalla en móvil, cabecera de sección |
  | `titleMedium` | Título de tarjeta o fila importante |
  | `bodyLarge` / `bodyMedium` | Texto y datos |
  | `labelLarge` | Botones y etiquetas de columna |
- Un test que recorra las pantallas y falle si un `Text` usa un `TextStyle` sin papel del tema.

## Accesibilidad (objetivo WCAG 2.2 AA)
- Tests de Flutter con `meetsGuideline` en cada pantalla crítica: `textContrastGuideline`, `androidTapTargetGuideline`, `iOSTapTargetGuideline` y `labeledTapTargetGuideline`, en los 3 tamaños y en claro y oscuro.
- Texto al 200 % sin cortes en cada pantalla crítica (test con `textScaler` 2.0).
- Una fila de lista = un nodo del lector (`MergeSemantics`): "Ana López, 3.º, 42 puntos".
- Marcador: anuncia "Rojo +1, 4 a 2" (`SemanticsService.announce`) y el fin del tiempo.
- Web y admin: orden de foco lógico, atajos de teclado en el marcador (ya hay 4 usos de foco), foco visible.
- Respeta "reducir movimiento" del sistema en animaciones.
- Errores de formulario junto al campo, no solo en un aviso.

## Cómo se hace
1. **Capturas de todo** (app y admin) en 360×800, 800×1280 y 1440×900, claro y oscuro, con Playwright (`08-ejecucion-local.md`). Se guardan fuera del repo como "antes".
2. Lista priorizada por pantalla con la skill `frontend-design`: qué sobra, qué falta, qué se divide.
3. Maquetas de las pantallas divididas; Raul elige antes de programar.
4. Componentes de `brackety_core` primero (página Diseño del admin los muestra).
5. Una PR por sección, empezando por Directo (se usa con presión), luego Ajustes y Crear grupo. Cada PR con capturas antes/después y los tests de accesibilidad.
6. Va después de L2-L3 de `plan-limpieza.md`: con los ciclos rotos y las pestañas como rutas, dividir pantallas es mucho más sencillo.

## Estado
Propuesta (2026-11-18), pendiente de Raul.
