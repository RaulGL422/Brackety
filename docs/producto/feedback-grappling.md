# Arreglos tras el grappling del 2026-11-21

Lo que falló o faltó en el grappling (Raul, 2026-11-22). Todo debe estar hecho y probado con el staff para la
competición del 2026-12-20 (`competicion-2026-12-20.md`); objetivo de prueba in situ: 2026-12-13.

## GR-1 · Marcador del árbitro: rehacer la pantalla
- Hoy (`scoreboard/ui/corner_buttons.dart`): los «+» están a la vista, pero los «−», la sumisión y las acciones de
  victoria van dentro del menú de la bandera. No es intuitivo.
- Regla nueva: **la bandera es solo para avisos, advertencias y descalificación**.
- Cada «+N» con su «−N» al lado, a la vista. Sumisión (y cualquier acción de victoria) como botón propio.
- Las demás pantallas: Raul las revisará una a una cuando esté todo lo de aquí (GR-7).
- Probar en móvil 360 px (el «Deshacer» ya cortaba el tiempo, `pendientes.md` §5).

## GR-2 · Sesión estable con el QR
- Pasó: casi 15 QR para 3 árbitros. Las sesiones se cerraban solas cada cierto tiempo y, al volver a entrar, el QR
  ya no servía (es de un solo uso).
- Sospecha: el refresco de sesión. El access token dura 15 min; si el móvil refresca, pierde la respuesta (wifi del
  pabellón, pantalla apagada) y lo repite pasados 10 s, el servidor lo toma por robo y cierra la sesión
  (`SessionService.refresh`, «Refresh token reused»). Confirmar en los registros del servidor del día.
- Arreglo pedido por Raul: la cuenta temporal tiene además **usuario y contraseña reales temporales** (el club los
  ve junto al QR). Si se cae la sesión, se vuelve a entrar con ellos sin un QR nuevo.
- La sesión debe aguantar toda la fase sin intervención. Sigue cerrándose al finalizar la fase o con «Quitar acceso».

## GR-3 · Tapiz sin árbitro admite grupos
- Pasó: con la fase empezada y sin árbitros (aún no tenía los móviles), al crear grupos salía «Algún alumno ya está
  en un grupo o el tapiz se ha quedado sin árbitro». El mensaje mezclaba dos causas; la real era el árbitro.
- Regla nueva: **un tapiz sin árbitro sí recibe grupos**. Lo único que impide añadir grupos a un tapiz es
  **inhabilitarlo**.
- Hoy «sin árbitro» hace de «fuera de uso» en varios sitios: `GroupService.chosenMat`, `MatchControlService`
  (inhabilitar, mover), `MatPlanner`, `MatFloor`, `MatSchedule`. Pasan a mirar si está inhabilitado.
- Mensajes separados: alumno ya en un grupo / tapiz inhabilitado.

## GR-4 · Grupos más visibles y fáciles de mover
- Ver de un vistazo qué grupos hay en cada tapiz con **el nombre de cada integrante**.
- Mover un grupo entero a otro tapiz de forma mucho más fácil desde el panel del club y también desde el árbitro.
- Forma: **arrastrar** el grupo de un tapiz a otro (Raul, 2026-11-22). Sigue el criterio de GR-7.
- Por concretar: si el árbitro mueve con su permiso actual o con «Panel de control».

## GR-5 · Grupos de distintos tamaños
- Decidido el 2026-11-21 (`decisiones.md`, grupos nórdicos de tamaño libre) y sin hacer: rango por categoría, ida y
  vuelta opcional, hasta tamaño − 1 comodines.

## GR-6 · Configuración pedida que no se aplicó
- Raul: «alguna configuración que te pedí». Por concretar cuál.

## GR-7 · Ambiente de la app: menos datos, más arrastrar
- Raul (2026-11-22): hoy da sensación de «muchísimos datos, opciones descontroladas y poco sentido».
- Criterio para todo lo que se toque desde ya: arrastrar en vez de menús y diálogos cuando se mueve algo; enseñar
  primero lo que se usa en el momento y esconder lo secundario; menos texto y menos cifras a la vista.
- Rediseño pantalla a pantalla: después, con Raul, cuando GR-1 a GR-6 estén bien.

## Orden propuesto
1. GR-3 (pequeño, solo servidor y mensaje) y GR-2 (sin sesión estable no se puede arbitrar).
2. GR-1 marcador.
3. GR-5 grupos de tamaño libre y GR-4 grupos visibles.
4. Competición del 20-12: 3 modalidades seguidas con los mismos grupos (esperando sus reglas).

## Estado
Apuntado; nada empezado.
