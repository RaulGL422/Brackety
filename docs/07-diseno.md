# 07 · Diseño

No hay diseño cerrado. Se trabaja pantalla a pantalla, con una fase inicial de exploración antes de la primera pantalla real.

## Fase de exploración (antes de programar UI)
Elegir con Raul, con mockups rápidos:
1. Paleta de color (modo claro y oscuro) y contraste mínimo AA.
2. Tipografías y escala de tamaños.
3. Estilo de componentes (tarjetas, tablas, botones, estados vacíos).
4. Pantallas clave: inicio con QR, tapiz/marcador, tabla de clasificación, inscripción.

Salida: `docs/07-diseno.md` actualizado con tokens (colores, tipografía, espaciados) y un tema único en `packages/brackety_core/lib/src/theme` (lo comparten app y admin).

Validación visual: página **Sistema de diseño** del admin, solo en debug (`./run-app.ps1 -Target web -App admin`). Muestra colores con su contraste, tipografía, espaciados, radios, componentes y ejemplos (marcador, clasificación).

## Tokens (en `brackety_core`, rama `chore/design-system`)
- Color: `ColorScheme` Material 3 (variante *fidelity*) desde `brandPalette` (primario + acento en `tertiary`). Candidatas: Eléctrico `#2F5BFF`/`#FF6B00` (por defecto), Fuego `#E63B12`/`#00A6A6`, Noche `#6C2BD9`/`#C6FF00`.
- Estados: `BracketyColors` (`ThemeExtension`): success, warning (+ containers). Error usa el de Material.
- Competidores: `CompetitorColor` (12 colores fijos en claro y oscuro, cada uno con su color de texto AA).
- Tipografía: Barlow (texto) y Barlow Condensed (display, headline, números del marcador), empaquetadas en assets (offline), licencia OFL.
- Espaciado `AppSpacing` 4·8·12·16·24·32·48. Radios `AppRadius` 8·12·20·full. Táctil `AppSizes` 48 (general) y 72 (marcador).
- Componentes: estilo vía `ThemeData` (botones, tarjetas, campos, chips, diálogos). Widgets propios solo al repetirse.
- Regla: ningún widget usa colores, tamaños o espaciados fijos; todo sale del tema o de los tokens.
- Test `theme_test.dart`: contraste AA de todos los pares de color en claro y oscuro.

## Público objetivo
Familias, deportistas (niños y adultos), entrenadores, árbitros y mesa. Muchos usuarios no técnicos, uso en móvil, a veces al aire libre (luz fuerte, arena).

## Principios
- Marcador/tapiz: botones grandes, legible a distancia, una mano, sin pasos innecesarios.
- Alto contraste, textos escalables, no depender solo del color.
- Textos siempre por i18n (ES/EN).
- Misma identidad en app, web y superadmin.

## Responsive (obligatorio en app, web y admin)
Cada pantalla se diseña y prueba en móvil, tablet y escritorio. Clases de ventana (Material 3), en `core/layout`:
| Clase | Ancho | Navegación | Contenido |
|---|---|---|---|
| compacta | < 600 | barra inferior | una columna |
| media | 600–839 | rail lateral | una o dos columnas |
| expandida | ≥ 840 | rail o menú lateral fijo | lista + detalle; ancho máximo de lectura ~1200 |
- Decidir por ancho disponible (`MediaQuery.sizeOf`/`LayoutBuilder`), nunca por plataforma.
- Vertical y horizontal; texto escalado hasta 200 % sin cortes; tablas anchas con scroll propio, nunca de página.
- Marcador/tapiz: en horizontal aprovecha el ancho; en tablet, los botones siguen al alcance de una mano.

## Estado
Tokens implementados; **pendiente de validación visual de Raul** (elegir paleta candidata en la página Sistema de diseño). Decisiones de partida en `decisiones.md` (2026-10-30).
