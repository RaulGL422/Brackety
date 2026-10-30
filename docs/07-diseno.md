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
Paleta, tipografías y componentes: **en exploración** (rama `chore/design-system`). Decisiones de partida en `decisiones.md` (2026-10-30).
