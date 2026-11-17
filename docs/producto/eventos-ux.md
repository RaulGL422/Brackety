# Eventos: rediseño de la experiencia

Pedido de Raul (2026-11-16): la configuración del evento y gran parte de su interfaz no son intuitivas. Se rehace antes de cerrar el módulo `eventos` (`modulos/eventos.md`).

## Problemas (hipótesis a validar)
- Se mezcla **preparar** el evento con **llevarlo en directo**: ajustes, tapices, panel de control y puntuaciones conviven en el mismo sitio.
- Configuración larga y plana: todo pesa lo mismo, sin valores por defecto explicados ni "avanzado" plegado.
- Ajustes del evento y de la fase repartidos sin que se vea cuál manda.
- No hay guía de qué falta para estar listo (categorías vacías, tapices sin árbitro, reglamento, email de privacidad…).
- Funciones escondidas o confusas: F1-1 (inhabilitar tapiz).
- Nombres del prototipo y de la jerga interna ("bote", "recomendado", "en espera") sin explicar.

## Principios
1. **Tres momentos, tres espacios**: Preparar → Directo → Resultados. Cada pantalla pertenece a uno.
2. **Asistente al crear**, pantallas normales al editar. Los pasos del asistente se pueden saltar y retomar.
3. **Valores por defecto de la plantilla de deporte** (Yoseikan, judo…): el club solo cambia lo que difiere.
4. **Lista "Listo para el día"** siempre visible en Preparar, con un enlace a cada cosa que falta.
5. **Una acción, un sitio**: lo del tapiz, en el tapiz; lo de la categoría, en la categoría.
6. Lenguaje del deporte: Tapiz, Pista o Campo según la ubicación del evento.
7. Vista previa "así lo ve el árbitro" o "así lo ve el público".
8. Acciones peligrosas (vaciar, deshacer, inhabilitar) con su consecuencia escrita y deshacer cuando se pueda.

## Arquitectura propuesta
- **Resumen**: estado, fechas, avisos, lista "Listo para el día" y accesos rápidos.
- **Inscripciones**: alumnos, clubes, pagos marcados, importación.
- **Competición**: categorías y grupos o cuadros (Preparar).
- **Directo**: tapices como planta del pabellón, cola prevista, panel de control y revisión (Directo).
- **Resultados**: puntuaciones, clasificación, podios y exportar.
- **Ajustes**: datos del evento, reglas (heredadas de la plantilla), ubicaciones, staff e invitaciones, visibilidad, reglamento PDF y motivos de advertencia.
- En la liga por fases: la liga arriba (clasificación y fases) y cada fase con estas mismas secciones; la fase hereda de la liga y marca lo que cambia.

## Asistente de creación
1. Tipo: Liga, Liga por fases o Torneo (con un ejemplo de cada).
2. Datos básicos: nombre, fechas, lugar.
3. Deporte y reglas: plantilla y lo que cambia.
4. Categorías: desde una plantilla, la edición anterior o a mano.
5. Ubicaciones y staff: número de tapices e invitaciones a árbitros y ayudantes (cuentas propias, F1-5).
6. Inscripción: QR, manual o importación; plazos y coste informativo.
7. Revisar y publicar (puerta legal).
- "Duplicar evento" y "Nueva fase desde la anterior" saltan directo al paso 7 con todo copiado.

## Cómo se valida (antes de programar)
1. Maquetas con la skill `frontend-design` en 3 tamaños.
2. Prueba con Raul y una persona del club sobre 6 tareas: crear la F2 desde la F1, añadir una categoría, invitar a un árbitro, inhabilitar un tapiz, mover un combate y exportar resultados.
3. Medir por tarea: completada sin ayuda (sí o no), tiempo y dudas. Objetivo: 6 de 6 sin ayuda.
4. Programar por secciones, una PR cada una, empezando por Directo (es lo que se usa con presión).

## Estado
Propuesta (2026-11-16). Tareas en `roadmap.md`, etapa 4.
