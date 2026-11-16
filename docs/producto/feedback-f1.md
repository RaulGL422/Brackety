# Fase 1 · Retrospectiva (evento del 2026-11-14)

Fuente: Raul, 2026-11-16. Las tareas salen de aquí hacia `roadmap.md`.

## Resultado
- Éxito: puntuaciones correctas, la app respondió bien y casi sin fallos.
- Validado en uso real: marcador con reglas por formato, bote de equipos, descanso mínimo, panel de control, offline en la web, liga por categoría y reglamento PDF.
- El club ya pide **una cuenta propia en producción** para guardar sus datos con seguridad.

## Fallos (arreglar antes de la Fase 2)
### F1-1 · "Inhabilitar tapiz" no aparecía
- Raul no lo encontró; no sabe si quedó en "desasignar árbitro".
- Causa probable: la decisión del 2026-11-14 lo hizo sin estado en BD (inhabilitar = quitar árbitro). El tapiz no se ve "inhabilitado" y la acción queda escondida o se confunde con quitar al árbitro.
- Propuesta: estado visible del tapiz (Activo / Inhabilitado), acción "Inhabilitar tapiz" en el menú del propio tapiz y "Reactivar". El tablero lo enseña atenuado con su motivo.
- Aceptación: desde el tablero del club, en móvil y escritorio, se inhabilita un tapiz en 2 toques o menos, sus grupos se reparten y el tapiz sale marcado como inhabilitado.

### F1-2 · Comodín elegido antes que un equipo normal se guardaba como normal
- Gravedad **crítica**: cambia quién puntúa. Hubo que apañarlo in situ.
- Causa a investigar: el formulario de crear grupo de equipos deduce el rol por el orden o el índice del hueco, no por un dato explícito.
- Propuesta: cada hueco lleva su tipo (`real` / `comodín`) explícito de punta a punta (UI → API → BD). Test de regresión con el comodín elegido primero y en cada posición.
- Revisar los datos de la F1 en la Pi tras el apaño: que la clasificación de la liga no arrastre puntos de más o de menos.

## Peticiones nuevas
### F1-3 · Puntos fuera de tiempo
- Necesidad: dar un punto de la última acción cuando el reloj ya llegó a 0:00.
- Propuesta: tras 0:00 el marcador sigue aceptando +1 y −1 hasta "Finalizar". La acción se guarda marcada `fuera de tiempo` (se ve en el historial, la ficha y el CSV).
- Después de "Finalizar": corrección solo del club o del superadmin, con motivo y auditoría.
- Preguntas en `pendientes.md`: ¿también tras finalizar?, ¿quién puede?

### F1-4 · Advertencias predefinidas y "Otro"
- Necesidad: poner una advertencia en un toque, sin escribir.
- Propuesta: lista de motivos en la configuración (por plantilla de deporte, editable por evento). En el marcador, botones con los motivos más usados y "Otro" con texto libre.
- Datos: catálogo `warning_reason` (id, texto ES/EN, orden, activo); la advertencia guarda id + texto (el texto, por si el motivo cambia luego).
- Compatible con la ficha del alumno (motivo ya visible) y con "+1 al rival cada 2 advertencias".

### F1-5 · Cuentas propias para todo el staff
- Renombrar árbitros por evento (`staffNames`) deja de servir: cada árbitro y ayudante entra con **su cuenta** y el club lo invita al evento.
- Depende de `ayudantes-permisos` (invitaciones, roles por evento) y de producción con emails reales.
- Las cuentas genéricas (`arbitro1`…) quedan solo en debug y en los escenarios.

### F1-6 · Eventos poco intuitivos
- La configuración y gran parte de la interfaz del evento no se entienden a la primera. Plan en `eventos-ux.md`.

## Peticiones para la F2 (2026-11-16)
### F2-1 · Peso
- Registrar el peso de cada alumno en la F2.
- Ya previsto en `modulos/eventos.md` (pesaje desactivado / opcional / recomendado / obligatorio): se adelanta la versión mínima.
- Propuesta: modo de pesaje en la fase; peso en kg con un decimal en inscripción, importación y ficha; el ayudante lo apunta o corrige el día del evento. Se ve al crear grupos.
- Datos de menores: solo lo ven el club y los ayudantes, nunca en público ni en el CSV público.

### F2-2 · Edades mezcladas dentro de una categoría
- Una categoría puede juntar varias edades, pero cada alumno debe salir **distinguido por su edad**.
- Propuesta: al crear grupos, alumnos ordenados y agrupados por edad, con la edad bien visible (columna o chip). Edad también en el tablero, el marcador y la clasificación.
- Opcional: tramos de edad dentro de la categoría que solo ordenan y sugieren grupos, sin partir la clasificación.

## Qué mantener
- Probar in situ con el staff real antes del evento: destapó lo importante.
- Reglas cerradas por Raul con preguntas cortas y decisiones registradas.
- Web en el pabellón con cola offline: suficiente; la APK no hizo falta.

## Aprendizajes
- Las decisiones "sin estado en BD" ahorran tiempo pero esconden la función (F1-1).
- Lo que deduce algo por posición en la UI necesita tests por cada posición (F1-2).
- Lo hecho a contrarreloj necesita una pasada de limpieza antes de crecer (`calidad.md`).
