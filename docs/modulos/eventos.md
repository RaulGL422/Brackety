# Módulo · eventos

## Objetivo
Crear y configurar eventos (Liga, Liga en fases, Torneo) con sus ajustes comunes.

## Configuración común
- Título, descripción, fechas y horas, enlaces de interés, **PDF de reglamento** (visible desde el marcador).
- Plantilla de deporte (predefinida) o puntuación personalizada (`puntuacion.md`).
- Categorías (edad, género, otros) con plantillas reutilizables.
- Equipos: individuales, parejas, equipos (titulares, suplentes, entrenadores).
- Coste por alumno informativo + opción "no se inscribe sin pago" (solo marca pagado/no pagado; no cobra).
- Pesaje: desactivado / opcional / recomendado / obligatorio; peso exacto registrable antes o el día previo.
- Estatura: opcional / recomendada / obligatoria.
- Descansos mínimos entre combates de un participante.
- Ubicaciones clave (Tapiz 1, Entrada alumnos…), roles de ayudante del evento y permisos.
- Visibilidad del evento y de resultados: todos, clubes, inscritos, nadie. Modificable en cualquier momento.
- Estados: borrador → publicado → en curso → finalizado (+ bloqueado por superadmin).

## Reglas
- Publicar y empezar fase requieren puerta legal (`legal-paginas.md`).
- Reglamento por modalidad/fase/categoría se fija al publicar.
- Eventos se pueden duplicar para temporadas futuras.
- Borrado lógico.

## Datos
`event`, `event_settings`, `category`, `location`, `event_attachment`.

## Pantallas
Crear/editar evento, panel del organizador, vista pública del evento.

## Tests
Transiciones de estado, visibilidad por audiencia, puerta legal, duplicado de evento.

## Estado
Pendiente.
