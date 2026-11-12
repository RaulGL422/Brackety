# Pruebas de la Fase 1 (2026-11-12)

Pruebas de Claude antes del 14-11, centradas en el portátil, el offline y las reconexiones. Raul prueba a mano en el portátil real a la vez. Se borra tras la fase; lo que quede abierto pasa a `pendientes.md`.

## Escenario
- Carpeta del portátil (`dist/brackety-event`) + paquete exportado del escenario `yoseikan-f1` ampliado: 77 inscritos, 4 clubes, 15 sin club, 6 sin estatura, un nombre largo, un niño de 8 que compite en 9-10, 9 categorías (4 por equipos de 3), 5 tapices con árbitro.
- Arranque como el día 14: `start-event.ps1 -Package <zip>`; contraseñas aleatorias en `credentials.txt`.
- Claude usa una copia aparte en otros puertos (8092/15434) y, como Pi, el servidor local con `yoseikan-f1`.
- Pruebas por la API (scripts) y por la web del paquete en Chrome sin interfaz a 412×915 (cliente CDP: cortar la red, recargar, diálogos).

## Ronda 1: qué se probó
| Bloque | Resultado |
|---|---|
| Login de las 8 cuentas del paquete; la contraseña demo (= usuario) ya no entra | OK |
| Permisos por rol: club, ayudante y árbitro en inscritos, ajustes, categorías, exportes, liga, clasificación, tapices; sin token 401; evento ajeno 404 | OK |
| Grupos: 4 o 3 + fantasma; rechazo de 5, 2, repetidos, fantasma del grupo, otra categoría, ya agrupado, tapiz ajeno, árbitro creando grupos | OK |
| Reparto automático de tapiz (los 5 primeros grupos, uno por tapiz; luego equilibrado) | OK |
| Deshacer un grupo sin empezar y rehacerlo en el tapiz elegido | OK |
| Equipos: tamaño exacto, sin repetir; grupos de 3 equipos + equipo fantasma (sin luchadores propios) | OK |
| Marcador: permisos (solo el árbitro del tapiz escribe), `knownEvents`, no puntuar antes de iniciar, −1, avisos con motivo, una mano (solo 4-7; la 2.ª da punto al rival), deshacer, ajuste de reloj solo parado | OK |
| Fin por puntos (para el reloj), por descalificación (15-0), por tiempo; finalizar solo acabado; nada tras finalizar | OK |
| 5 pulsaciones simultáneas con el mismo `knownEvents`: cuenta una | OK |
| Un combate por tapiz; el mismo alumno (también como fantasma) no lucha en dos tapices a la vez | OK |
| Offline: hora del dispositivo, `opId` repetido cuenta una vez, choque → revisión del club, Aplicar y Descartar, reintentos con la misma respuesta | OK |
| Jornada completa simulada (96 combates, 5 tapices): el recomendador nunca se atasca | OK |
| Clasificación de la fase recalculada aparte (asistencia + puntos, fantasma y descalificado a 0, equipos) | OK tras arreglo 4 |
| Caída de la API a mitad de combate: copia de la BD, el reloj sigue, el token sirve, las acciones guardadas en el móvil entran en orden | OK tras arreglo 1 |
| Web sin red: cola, barra "Sin conexión · N pendientes", sincroniza al volver; recargar con pendientes | OK tras arreglo 2 |
| Vuelta a la Pi: exportar .zip del portátil → importar en seco, de verdad y otra vez; clasificación idéntica; fichero de otro evento 409 | OK |
| Liga en la Pi tras importar: fase 2 copia tapices y categorías, reinscribir los 77 (sin consentimiento de tutores 400), clasificación con 2 fases, CSV de liga | OK |
| Protecciones del club con grupos: nacimiento, borrar agrupado, fecha del evento, quitar tapiz con grupos, límite de puntos (409); alta tardía; menor sin tutor 400; CSV sin fórmulas | OK |
| Superadmin del portátil: desde otra IP 403 | OK; login roto (arreglo 5) |

## Fallos y arreglos
1. **La API caída no volvía sola** (`start-event.ps1`): guardaba copia y paraba. Ahora la relanza (hasta 3 veces en 10 min, sin recargar el paquete). Probado: vuelve en 8 s.
2. **Recargar la web sin red deja el dinosaurio de Chrome.** Causa: http en el pabellón, sin service worker posible. Arreglo: con acciones pendientes el navegador pregunta antes de recargar o cerrar; sin "deslizar para recargar". Probado con CDP: el diálogo sale y la acción se envía al volver la red. Sin pendientes, recargar sin red sigue sin funcionar: esperar a la wifi y recargar (no se pierde nada).
3. **Título del tablero cortado** ("Tapi…") en un móvil de 412 px. Ahora el número se encoge. Test a 360 px.
4. **Posiciones de la clasificación de la fase mezclaban categorías** (un niño 62.º en una categoría de 14). Ahora por categoría, como la liga.
5. **El superadmin del portátil no podía entrar**: desde una consola en UTF-8, Windows PowerShell manda un BOM delante de la contraseña al calcular el hash. El jar lo ignora ahora.
6. `start-event.ps1`: el puerto de la API venía fijo en el jar (ahora `SERVER_PORT`); si el puerto de PostgreSQL está ocupado lo dice.

## Abierto (para Raul)
- **Categorías con 3 inscritos** (17-19, 20-25, 26+ en el escenario) no pueden formar grupo: el fantasma debe ser un 4.º de la misma categoría. Hoy: el club cambia a alguien de categoría. ¿Basta para el 14?
- Tras recargar, la web vuelve a "Mis eventos", no al marcador (la URL no cambia al navegar). Dos toques para volver; sin pérdida.
- La barra "Sin conexión" empuja el marcador 40 px hacia abajo al aparecer.
- Bajar el reloj al mínimo con los botones deja una fracción de segundo: "Iniciar" lo acaba al momento (regla: el tiempo solo se agota corriendo).
- El límite de 20 logins por minuto y por IP solo afectaría si muchos entran desde el mismo dispositivo.

## Ronda 2
Pendiente: tras la fusión, repetir todo con la carpeta regenerada.
