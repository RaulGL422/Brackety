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
- Hecho (Raul, 2026-11-23): parejas [+N|−N] de dos en dos; la sumisión, botón propio con confirmación; en móvil
  (esquina baja) 🏆 cuadrado bajo la bandera; botones a alto fijo, el texto grande encoge.

## GR-2 · Sesión estable con el QR
- Pasó: casi 15 QR para 3 árbitros. Las sesiones se cerraban solas cada cierto tiempo y, al volver a entrar, el QR
  ya no servía (es de un solo uso).
- Datos de la Pi (2026-11-22): 16 QR en dos fases (`grappling2`: 6; `Fase 2`: 10). Ningún «Refresh token reused»:
  la sesión **no caducaba sola**. Las sesiones cerradas coinciden, al segundo, con otro QR escaneado en el mismo móvil.
- Causas, por diseño actual:
  1. El acceso por QR es de **una fase**: la Fase 2 no copia los de la 1, así que cada árbitro necesitó otro QR.
  2. Escanear un QR en un móvil con sesión **cierra esa sesión sin preguntar** (`qr_sign_in_screen.dart`).
  3. El código sirve una vez y no hay otra forma de volver a entrar: cada tropiezo, un QR nuevo.
  4. Crear un QR para un tapiz **le quita el tapiz al árbitro anterior** sin avisar (`TemporaryAccessService.create`).
  5. «Arbitraba y de repente salía el login» (Raul): en la Fase 2 cuatro sesiones por QR murieron sin que el servidor
     las rechazara ni recibiera su token de renovación (una a los 74 s). La app pidió renovar **sin el token**:
     el servidor dijo 401 y la app mandó al login. Sospecha principal: en la web (iPhone), la cookie `SameSite=Strict`
     no viaja tras abrir el QR desde fuera. Raul: iPhone con Safari; él lo abría desde una web lectora de QR (con una
     captura) y otro árbitro con la cámara: en los dos casos, navegación desde otro sitio. Reproducir en debug con
     `ACCESS_TTL=1m` y el iPhone de Raul antes de arreglar.
  - Hecho (PR B, sin esperar la prueba): cookie `SameSite=Lax` (solo la leen POST: CSRF igual de cerrado); el
    dispositivo recuerda el usuario `qr-…` y, si se cae la sesión, el login lo trae escrito y dice que entre con la
    contraseña del club. Si la prueba del iPhone sigue fallando: recarga completa tras entrar por QR.
- Arreglo pedido por Raul: la cuenta temporal tiene además **usuario y contraseña reales temporales** (el club los
  ve junto al QR). Si se cae la sesión, se vuelve a entrar con ellos sin un QR nuevo.
- El acceso pasa a la fase siguiente con su tapiz; un QR nuevo para un tapiz ocupado avisa de a quién sustituye;
  escanear en un móvil con sesión pregunta antes de cambiar de cuenta.
- La sesión aguanta toda la fase sin intervención. Se cierra al acabar la fase (si la siguiente se creó antes, sigue en ella) o con «Quitar acceso» (Raul, 2026-11-23).
- Hecho (PR A): usuario y contraseña, paso a la fase siguiente, aviso de tapiz ocupado, test de jornada. Preguntar antes de cambiar de cuenta ya existía. Falta (PR B): volver a entrar tras un 401 sin token y la cookie tras la prueba del iPhone.
- Test con reloj simulado: la sesión temporal aguanta una jornada entera y el paso a la fase siguiente (GR-8).

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
- El árbitro mueve con un permiso extra que le da el club (Raul, 2026-11-23).
- Hecho: «Grupos por tapiz» (desde Tapices del club y, con `MOVE_GROUPS` o `CONTROL`, desde la pantalla del
  árbitro): columnas por tapiz en tablet y escritorio, uno debajo de otro en móvil; solo grupos por acabar
  (los terminados, contados); mantener pulsado y arrastrar, o «Mover» en cada grupo. Uno en combate no se mueve.

## GR-5 · Grupos de distintos tamaños
- Decidido el 2026-11-21 (`decisiones.md`, grupos nórdicos de tamaño libre): rango por categoría, ida y vuelta
  opcional, hasta tamaño − 1 comodines.
- Hecho en el servidor: calendario de 2 a 8, vuelta con colores cambiados, desempate sumando los dos combates,
  paquete del evento y descargas. En Categorías: «De» y «A» con − / +, «Ida y vuelta» y cuántos combates salen
  (Raul, 2026-11-23). Crear grupos: con rango, chips de tamaño encima de los huecos (empieza en el mayor y se
  mantiene entre grupos; uno menor que los elegidos queda apagado); más de 4 huecos, en dos filas. Hecho.

## GR-6 · Configuración pedida que no se aplicó
- Raul (2026-11-23): grupos no solo de 4 (es GR-5) y fin a 15 puntos de diferencia.
- Los 15 puntos no son un fallo: falta poder configurar el deporte. Pasa a plantillas de deporte
  (`plantillas-deporte.md`): nada fijo en código, todo elegible al crear o escoger el deporte.

## GR-7 · Ambiente de la app: menos datos, más arrastrar
- Raul (2026-11-22): hoy da sensación de «muchísimos datos, opciones descontroladas y poco sentido».
- Criterio para todo lo que se toque desde ya: arrastrar en vez de menús y diálogos cuando se mueve algo; enseñar
  primero lo que se usa en el momento y esconder lo secundario; menos texto y menos cifras a la vista.
- Rediseño pantalla a pantalla: después, con Raul, cuando GR-1 a GR-6 estén bien.

## GR-8 · Batería del servidor endurecida
- Reglas en `04-testing.md`, «Batería del servidor».
- Matriz de permisos hecha (`PermissionMatrixTest`, `permission-matrix.txt`): 134 endpoints × 7 papeles con ids
  reales y cuerpos válidos; cambiarla: `-Dmatrix.update=true` y revisar el diff. Los de `/me` que piden
  reautenticación salen cerrados para todos (no se prueba ese paso). Cada permiso suelto, dado solo a un
  ayudante, abre lo de `permission-grants.txt` (revisado contra `ayudantes-permisos.md`).
- Concurrencia hecha (`ConcurrencyTest`): mismo combate desde dos dispositivos (en línea y cola), mismo `opId` a la
  vez, alumno en dos grupos, grupo movido a dos tapices, movido mientras se deshace o empieza su combate, dos
  renovaciones con un token. Encontró un fallo: un QR escaneado dos veces a la vez abría dos sesiones.
- Ataques por endpoint hechos (`PermissionMatrixTest`): el club de otro evento con su `eventId` y los ids de este
  (rechazado, nada cambia) y entradas rotas (ids no válidos, JSON roto, textos de 5.000, números fuera de rango):
  ningún 500.
- Tokens falsificados hechos (`AccessTokenAttacksTest`): sin firma (`alg none`), otra clave, otro algoritmo, `sub`
  cambiado, caducado y de otro propósito: 401. Una cuenta QR no alcanza nada del evento de otro club.
- Sesiones hecho (`PhaseSessionsTest`): normal y por QR, 10 h con respuestas perdidas y 3 h sin red. Encontró un
  fallo: un reintento pasados 10 s cerraba la sesión como robo; ahora vale 12 h mientras el par nuevo no se use.
- Día completo de torneo hecho (`TournamentDayTest`), tambo y grappling: inscripción, grupos de 3 a 5 (uno con
  vuelta), tapiz inhabilitado y de vuelta, árbitro QR que vuelve a entrar con usuario y contraseña, revisión,
  combate reabierto, fase cerrada, reabierta y cerrada. Faltan liga de varias fases y equipos.
- Carrera encontrada (`PhaseRaceTest`): empezar o reabrir un combate mientras el club cerraba la fase lo dejaba en
  curso con la fase cerrada; ahora se vuelve a leer la fase con el evento bloqueado.
- Migración hecha (`MigrationFromReleaseTest`): datos de v0.8.2 con `yoseikan-f1` en uso migrados a hoy; no se pierde
  ninguna fila y el día sigue. Una migración que borre filas lo hace fallar.
- Liga de dos fases hecha (`TournamentDayTest`): la fase 2 se abre desde la 1, entra la misma gente y vive otro día
  completo con incidentes; la clasificación de liga suma las dos fases, igual que su CSV y el historial de cada uno.
- Día con equipos hecho (`TournamentDayTest`): equipos de 3 hechos por el club, grupos de 3 a 5 equipos al bote y los
  mismos incidentes; cada miembro cuenta los combates de su equipo en la clasificación.

## GR-9 · Accesibilidad y organización en lo que ya existe
- Reglas duras en `07-diseno.md`. Se aplican a cada pantalla al tocarla (GR-1, GR-4) y en el repaso de Raul (GR-7).
- Una ayuda de test en `brackety_core` que pase las guías de Flutter a 3 tamaños y texto al 200 %.

## GR-10 · PDF del reglamento
- En el iPhone (Safari) elegirlo no hacía nada (Raul, 2026-11-23): el selector no estaba en la página. Ahora
  sí, y todo fallo avisa; en Android avisa de que es solo web. Hecho (#171); falta la prueba de Raul.

## GR-11 · Ajustes con botón Guardar
- Un tapiz añadido no seguía al salir y entrar, sin mensaje: el guardado automático se saltaba todo si un
  campo no era válido. Ahora botón Guardar, campo nombrado y aviso al salir. Hecho.
- Puntuaciones desborda en móvil con texto al 200 % (GR-9).

## GR-12 · Asistente al crear un evento
- Al crear un evento, además del deporte, configurarlo paso a paso. Pantalla nueva: los pasos, con Raul.

## Orden (Raul, 2026-11-23)
1. Primero lo interno que falla: GR-11, GR-10, GR-2, GR-6, GR-5, GR-4.
2. Pantallas con Raul, una a una, aprobadas al 100 %: GR-1 (árbitro) la primera, GR-12, GR-7. Claude avisa
   cuando toca una.
4. Competición del 20-12: 3 modalidades seguidas con los mismos grupos (esperando sus reglas).

## Estado
Apuntado; nada empezado.
