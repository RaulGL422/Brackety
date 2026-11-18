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
- Colores de los competidores por ubicación, elegidos de la paleta común `CompetitorColor` (`07-diseno.md`).
- Visibilidad del evento y de resultados: todos, clubes, inscritos, nadie. Modificable en cualquier momento.
- Estados: borrador → publicado → en curso → finalizado (+ bloqueado por superadmin).
- Adelanto F1-7 (Raul, 2026-11-18; #129), por fase:
  - Estados: sin comenzar → en curso → finalizada. Barra con el estado arriba del panel del club, de las categorías del ayudante y del tapiz del árbitro; comenzar y finalizar: el club y quien tenga ese permiso (F1-7 C); reabrir: solo el club.
  - Sin comenzar: no se crean grupos ni se puntúa (`PHASE_NOT_STARTED`). Equipos, pesos y tapices se pueden preparar.
  - Finalizar: nunca con un combate en curso o en revisión; los pendientes quedan sin jugar (la app avisa cuántos).
  - Finalizada: nadie crea ni deshace grupos, puntúa, mueve combates, cambia equipos, pesos ni tapices (`PHASE_FINISHED`), tampoco el club. Ajustes, alumnos y descargas siguen libres. El club reabre con motivo.
  - Al día siguiente (00:05, `brackety.time-zone`), si nadie la finalizó: sin combates pendientes se finaliza sola y avisa al club por correo; con pendientes, se lo dice una vez.
  - Datos: `event.started_at`, `finished_at`, `auto_close_warned_at` y el historial `event_phase_change` (acción, cuenta, motivo, combates sin jugar). La migración da por comenzadas las fases con grupos y por finalizadas las de días pasados, sin correo.
  - API: `GET /events/{id}/phase` (staff), `POST /events/{id}/phase/start|finish|reopen {reason}` (club).
  - La puerta legal al comenzar (contacto de privacidad) llegará con el módulo: hoy no se exige.

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
