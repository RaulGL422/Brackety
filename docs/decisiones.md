# Decisiones

Formato: fecha · decisión · motivo. Las nuevas se añaden al final de este archivo; cuando pase de 12.000 caracteres,
lo anterior pasa a un archivo con la fecha de su primera decisión.

Anteriores:
- `decisiones-2026-10.md` y `decisiones-2026-10-b.md`: octubre (stack, arquitectura, reglas base).
- `decisiones-2026-11-01.md`: del 1 al 10 de noviembre (auth, prototipo, Pi).
- `decisiones-2026-11-11.md`: del 11 al 16 de noviembre (F1 y lo que salió de ella).
- `decisiones-2026-11-17.md`: del 17 al 24 de noviembre (modelo de datos, grappling, GR-1 a GR-5, plantillas).

- 2026-11-24 · Sesiones (GR-8): repetir una renovación cuya respuesta se perdió, hasta 12 h y mientras el par nuevo no se haya usado, devuelve el mismo token de renovación con un acceso nuevo; reusar uno cuando la sesión ya avanzó es robo (se revoca todo y se avisa) · regla de Raul: la sesión aguanta la fase con red perdida; antes, a los 10 s se cerraba. Riesgo aceptado: quien robe un token ya rotado comparte la sesión hasta que uno de los dos avance, y entonces salta el aviso.
- 2026-11-24 · CI del server en PR a `development`: solo los tests de los módulos tocados (más `ArchitectureTest` y, con un controller cambiado, la matriz de permisos); todo en PR a `main` y en push · decisión de Raul: el job tardaba ~12 min por PR; los tests completos van en la subida de versión a `main`. Riesgo aceptado: un cambio en un módulo puede romper otro que dependa de él y se ve en la release.
- 2026-11-24 · Una rama por módulo (`feat/<modulo>`) con todos sus pasos y una sola PR a `development` (borrador desde el principio, para el CI) · decisión de Raul: con una PR por paso, cada fusión dejaba las demás en conflicto. Riesgo aceptado: PRs más grandes de revisar.
- 2026-11-24 · El permiso «Participantes» también importa listas (leer, comprobar, inscribir) y ve las categorías · decisión de Raul tras la prueba de permisos sueltos (GR-8): quien inscribe gente elige su categoría y puede traerla de una hoja.
- 2026-11-25 · Exportar a medida: también quien tiene «Participantes»; las columnas personales y de menores, solo con el permiso nuevo «Descargar datos personales» (el club lo tiene siempre). «Para publicar» quita esas columnas y deja nombre e inicial del apellido en toda celda que nombre a alguien (rojo, azul, ganador, cómo acabó, miembros) · decisión de Raul (2026-11-19, permiso propio) y de Claude (quién exporta: lo mismo que ya ve en Inscritos).
- 2026-11-25 · Auditoría de descargas con datos personales: la ve el club (Configuración → Personal), no el superadmin; la vista previa no cuenta · decisión de Claude: el club da el permiso y responde de los datos de su gente; la vista previa enseña 20 filas en pantalla, no se lleva nada.
- 2026-11-25 · Puerta legal (`LEGAL_GATE`, 403) en empezar la fase y crear la siguiente; se comprueba tras el permiso, así quien no puede hacerlo no se entera de la puerta · decisión de Claude con la regla de `CLAUDE.md` («pasar de fase»): son los dos pasos que hoy ponen a trabajar los datos de la gente; «publicar evento» aún no existe.
- 2026-11-25 · Nueva aceptación de términos y privacidad: solo se pide a quien aceptó una versión anterior · decisión de Claude: las cuentas por QR (árbitros del club) nunca aceptaron; pedírsela el día de competición las dejaría paradas.
- 2026-11-25 · Actualización obligatoria en web y admin: al salir una versión, solo queda «Actualizar»; con acciones sin enviar, espera a que salgan · petición de Raul; esperar protege lo que un árbitro aún no ha enviado. Android no, hasta que haya de dónde bajar el APK.
