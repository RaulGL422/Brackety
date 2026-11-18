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
- Hecho (2026-11-16): el botón solo estaba como icono en la barra del tablero de cada tapiz. Ahora está a la vista en cada tarjeta de Tapices, el tapiz guarda su estado y «Reactivar tapiz» le devuelve su árbitro (`modulos/prototipo-f1.md`).

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
- Respuesta de Raul (2026-11-17): el árbitro, hasta "Finalizar". Después, como ya es: "Reabrir combate" con motivo, en la línea de tiempo.
- Hecho (2026-11-17): `modulos/prototipo-f1.md`.

### F1-4 · Advertencias predefinidas y "Otro"
- Necesidad: poner una advertencia en un toque, sin escribir.
- Propuesta: lista de motivos en la configuración (por plantilla de deporte, editable por evento). En el marcador, botones con los motivos más usados y "Otro" con texto libre.
- Datos: catálogo `warning_reason` (id, texto ES/EN, orden, activo); la advertencia guarda id + texto (el texto, por si el motivo cambia luego).
- Compatible con la ficha del alumno (motivo ya visible) y con "+1 al rival cada 2 advertencias".
- Hecho (2026-11-17): lista por deporte, editable por evento; sin catálogo en BD (se guarda el texto, como antes). `modulos/prototipo-f1.md`.

### F1-5 · Cuentas propias para todo el staff
- Renombrar árbitros por evento (`staffNames`) deja de servir: cada árbitro y ayudante entra con **su cuenta** y el club lo invita al evento.
- Depende de `ayudantes-permisos` (invitaciones, roles por evento) y de producción con emails reales.
- Las cuentas genéricas (`arbitro1`…) quedan solo en debug y en los escenarios.
- Hecho (2026-11-17): invitación por email a una cuenta completa (Raul). `modulos/ayudantes-permisos.md`, «Adelanto F1-5».

### F1-6 · Eventos poco intuitivos
- La configuración y gran parte de la interfaz del evento no se entienden a la primera. Plan en `eventos-ux.md`.

### F1-7 · Tapiz terminado y fase que nunca se cierra (Raul, 2026-11-18)
- Pedido: un grupo terminado deja libres su tapiz y su árbitro, y el historial guarda dónde se jugó y quién arbitró. En la F1, para quitar un tapiz con grupos terminados hubo que trasladar grupos.
- Ya cubierto por «Inhabilitar tapiz» (F1-1, v0.6.0, que en la F1 aún no existía): solo mueve los grupos con combates por jugar; los terminados se quedan donde se jugaron. Quitarlo del todo en Configuración sigue bloqueado si tuvo grupos; ahora el aviso lleva a inhabilitarlo (`MAT_HAS_GROUPS`; Raul: basta con inhabilitar).
- Pedido: **comenzar y finalizar** el evento o la fase, también desde la pantalla de crear grupos. Una semana después de la F1 aún se podían crear grupos.
- Respuestas de Raul (2026-11-18):
  - Quién: el club, o los ayudantes con ese permiso. Los árbitros también son ayudantes. En «Personal» (Configuración del evento) se elige qué puede hacer cada ayudante.
  - Finalizada: solo lectura para ayudantes y árbitros (ven grupos, resultados y fichas; no crean grupos, no puntúan, no mueven). El club puede **reabrir** con motivo, auditado.
  - Si nadie la finaliza: se cierra sola al día siguiente si no quedan combates por jugar, y **manda un correo** al club (si quedan, le avisa).
  - Cuándo: ya, antes de la etapa 3, para llegar probado a la F2.
- Idea de Raul: aprovechar mucho más el **correo** como herramienta (`modulos/notificaciones.md`).
- Plan: PR A (aviso del tapiz), PR B (comenzar, finalizar y reabrir fase, cierre automático y correo), PR C (permisos por ayudante en «Personal»; la lista de permisos se enseña a Raul antes de programar).

## Peticiones para la F2 (2026-11-16)
### F2-1 · Peso y estatura (respuestas de Raul, 2026-11-16)
- 2026-11-17: datos, formulario, importación y CSV hechos en M2c. Configuración y bloqueo en pruebas (rama `feat/f2-measures-required`): cada deporte trae su nivel (tambo: opcional), el evento puede cambiarlo en Ajustes > Peso y estatura; obligatorio bloquea grupo y equipo (el ayudante lo apunta tocando al alumno), opcional avisa "sin peso"/"sin estatura", desactivado no se pide.
- Se pesa **el mismo día**, pero queda guardado en la inscripción y en la ficha global del alumno. Igual con la estatura, relacionada con cada evento.
- Cada dato (peso, estatura…) se configura en la **plantilla del deporte** y en el **propio evento**: desactivado, opcional u obligatorio (`modulos/eventos.md`).
- Obligatorio: no se puede meter al alumno en un grupo ni en las llaves sin el dato.
- No obligatorio: al crear el grupo se avisa al lado de quién no lo ha declarado ("sin peso", "sin estatura").
- Peso en kg con un decimal; el ayudante lo apunta o corrige el día. Datos de menores: solo club y ayudantes, nunca en público.

### F2-2 · Edades mezcladas dentro de una categoría
- Una categoría puede juntar varias edades, pero cada alumno debe salir **distinguido por su edad**.
- Alcance (Raul, 2026-11-16): **la pantalla de crear grupos**. Se reorganiza para sacar esa división por edad llegado el momento (alumnos agrupados por edad, la edad bien visible).
- Encaja con la reordenación de esa pantalla de `calidad.md` y `eventos-ux.md`.
- 2026-11-17, en pruebas (rama `feat/f2-ages-in-category`): si la categoría mezcla edades, crear grupos y crear equipos separan la lista por edad («7 años · 6», la menor primero) con un interruptor «Separar por edad», y el panel del grupo muestra la edad de cada uno («Ana P. · 8»).

### F2-3 · CSV de resultados confuso
- Abierto en Excel, la entidad de la liga no entiende bien los puestos (1.º, 2.º, 3.º). Rehacer todo el CSV para que se lea claro: una hoja o bloque por categoría, columnas con nombre y sin datos mezclados en una celda.
- 2026-11-16, urgente para la entidad: **un CSV por categoría** con la clasificación de la liga (posición, medalla, alumno, club, total por fase), en un .zip desde la pestaña de liga y dentro de la exportación completa. El resto de la reforma del CSV sigue pendiente.
- 2026-11-17: la misma clasificación **en PDF** para imprimir, una categoría por página.

### F2-4 · Clasificaciones configurables
- La clasificación global debe ser una opción: en esta liga no sirve.
- Según el deporte, se clasifica por peso, sexo, categoría, edad…: criterios de la plantilla de deporte, ajustables en el evento (`modulos/ranking.md`, `modulos/puntuacion.md`).
- Respuesta de Raul (2026-11-17): en la F2 la categoría es solo por edad; sexo y peso, informativos. Hecho: la global es una opción de la liga (`modulos/ranking.md`).

## Qué mantener
- Probar in situ con el staff real antes del evento: destapó lo importante.
- Reglas cerradas por Raul con preguntas cortas y decisiones registradas.
- Web en el pabellón con cola offline: suficiente; la APK no hizo falta.

## Aprendizajes
- Las decisiones "sin estado en BD" ahorran tiempo pero esconden la función (F1-1).
- Lo que deduce algo por posición en la UI necesita tests por cada posición (F1-2).
- Lo hecho a contrarreloj necesita una pasada de limpieza antes de crecer (`calidad.md`).
