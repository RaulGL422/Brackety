# 07 · Diseño

No hay diseño cerrado. Se trabaja pantalla a pantalla, con una fase inicial de exploración antes de la primera pantalla real.

## Fase de exploración (antes de programar UI)
Elegir con Raul, con mockups rápidos:
1. Paleta de color (modo claro y oscuro) y contraste mínimo AA.
2. Tipografías y escala de tamaños.
3. Estilo de componentes (tarjetas, tablas, botones, estados vacíos).
4. Pantallas clave: inicio con QR, tapiz/marcador, tabla de clasificación, inscripción.

Salida: `docs/07-diseno.md` actualizado con tokens (colores, tipografía, espaciados) y un tema único en `packages/brackety_core/lib/src/theme` (lo comparten app y admin).

Validación visual: página **Diseño** del admin, solo en debug (`./run-app.ps1 -Target web -App admin`). Muestra colores con su contraste, tipografía, espaciados, radios, componentes y ejemplos (marcador, clasificación), en claro/oscuro y con texto hasta 200 %. Revisarla al cambiar el tema.

## Tokens (en `packages/brackety_core/lib/src/theme`)
Sistema **neutro multideporte**: el color es de quien compite. La app se queda en blanco, gris y tinta, y cada evento elige los colores de sus competidores sin que choquen con ningún botón. Maquetas: canvas de diseño de Raul (2026-11-08).
- Color: `ColorScheme` fijo, claro y oscuro (no generado por semilla), sin tinte.
  | Papel | Claro | Oscuro |
  |---|---|---|
  | Tinta y acción (`primary`, `onSurface`) | `#1A1A1A` | `#EDEDED` |
  | Fondo (`surface`) | `#F2F2F2` | `#141414` |
  | Tarjeta (`surfaceContainerLow`) | `#FFFFFF` | `#1F1F1F` |
  | Secundario (`onSurfaceVariant`) | `#555555` | `#A8A8A8` |
  | Banda de cabecera (`BracketyColors.band`) | `#1A1A1A` | `#000000` |
- "Siguiente combate" se marca con marco grueso de tinta, icono y palabra; "En curso", con banda de tinta. Nunca con un color que pueda llevar un competidor.
- Estados con color propio y siempre con icono y palabra: error ladrillo (`#8A3A12`), aviso ámbar, correcto verde. No se usan en el marcador.
- Estados: `BracketyColors` (`ThemeExtension`): success, warning (+ containers) y `band`/`onBand`.
- Competidores: `CompetitorColor` (12 colores fijos en claro y oscuro, cada uno con su color de texto AA). En artes marciales, siempre rojo `#C62B2B` y azul `#1F57B8`.
- Tipografía: Atkinson Hyperlegible Next (texto: distingue I, l, 1 y O, 0 con poca vista o al sol) y Saira Condensed (display, headline, reloj, puntos, número de ubicación), empaquetadas en assets sin modificar (offline), licencia OFL.
- Espaciado `AppSpacing` 4·8·12·16·24·32·48. Radios `AppRadius` 4·6·8·full: rectángulos con esquina corta, nunca cápsulas. Táctil `AppSizes` 48 (general) y 72 (marcador); iconos del marcador 40. Anchos: formulario 480, lectura 720, columna de tabla en móvil 200 (la tabla se desplaza en horizontal).
- Marcador: siempre con el tema oscuro, también en modo claro.
- Componentes: estilo vía `ThemeData` (botones, tarjetas, campos, chips, diálogos, barras). Widgets propios solo al repetirse.
- Regla: ningún widget de producto usa colores, tamaños o espaciados fijos; todo sale del tema o de los tokens (la página Diseño fija anchos solo para maquetar la muestra).
- Test `theme_test.dart`: contraste AA de todos los pares de color en claro y oscuro.

## Reglas de pantalla
- Cada pantalla abre con lo que toca hacer ahora: el siguiente combate, el grupo a medias.
- El estado se dice con palabra e icono, nunca solo con color.
- Datos en columnas con su etiqueta, no en frases unidas por puntos medios.

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
Neutro multideporte (2026-11-08) sustituye a Tatami (el mismo día, demasiado ligado a artes marciales) y a Eléctrico + Barlow (2026-10-30). Aplicado al tema y a las pantallas de la F1 (tablero del árbitro, marcador, crear grupo); el resto, en `pendientes.md`.
