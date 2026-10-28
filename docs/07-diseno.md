# 07 · Diseño

No hay diseño cerrado. Se trabaja pantalla a pantalla, con una fase inicial de exploración antes de la primera pantalla real.

## Fase de exploración (antes de programar UI)
Elegir con Raul, con mockups rápidos:
1. Paleta de color (modo claro y oscuro) y contraste mínimo AA.
2. Tipografías y escala de tamaños.
3. Estilo de componentes (tarjetas, tablas, botones, estados vacíos).
4. Pantallas clave: inicio con QR, tapiz/marcador, tabla de clasificación, inscripción.

Salida: `docs/07-diseno.md` actualizado con tokens (colores, tipografía, espaciados) y se implementa un tema único en `app/lib/core/theme`.

## Público objetivo
Familias, deportistas (niños y adultos), entrenadores, árbitros y mesa. Muchos usuarios no técnicos, uso en móvil, a veces al aire libre (luz fuerte, arena).

## Principios
- Marcador/tapiz: botones grandes, legible a distancia, una mano, sin pasos innecesarios.
- Alto contraste, textos escalables, no depender solo del color.
- Textos siempre por i18n (ES/EN).
- Misma identidad en app, web y superadmin.

## Estado
Paleta, tipografías y componentes: **pendiente de explorar**.
