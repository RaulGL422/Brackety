# Módulo · ayudantes-permisos

## Objetivo
Roles de evento, ubicaciones y permisos del staff.

## Reglas
- Roles de evento libres (árbitro, mesa, organización…). Cada rol tiene un conjunto de permisos; un ayudante puede tener permisos extra individuales.
- Ubicaciones: un ayudante puede tener 0 a N. Asignaciones antes y durante el evento.
- **Lista cerrada de permisos** (ampliable por módulo): aceptar participaciones, registrar asistencia/peso, marcar pago, asignar tapiz a grupo o alumno, crear grupos, crear llaves, manejar marcador, manejar tiempo, registrar amonestaciones, cambios, ver fotos en tapiz, importar CSV, gestionar permisos de otros.
- **Delegación de un nivel**: quien tenga "gestionar permisos" puede dar o quitar permisos a otros ayudantes, pero no puede dar ese mismo permiso.
- Toda comprobación en servidor, por permiso y por evento/ubicación.
- Registro de auditoría de cambios de permisos.
- Detalle fino de permisos: se define al construir el módulo. Ya decidido: «Descargar datos personales» para las exportaciones a medida (Raul, 2026-11-19, `../producto/exportaciones.md`).
- Los árbitros también son ayudantes: en «Personal» (Configuración del evento) se elige qué puede hacer cada uno (Raul, 2026-11-18). Permiso nuevo: comenzar y finalizar la fase (F1-7). La lista se enseña a Raul antes de la PR C.

## Datos
`event_role`, `role_permission`, `staff_member`, `staff_location`, `permission_audit`.

## API (borrador)
`POST /events/{id}/roles`, `PUT /events/{id}/staff/{id}/permissions`, `PUT /events/{id}/staff/{id}/locations`.

## Pantallas
Gestión de roles y permisos, asignación de ubicaciones, agenda del ayudante.

## Tests
Cada permiso permitido/denegado, delegación de un nivel, cambios en directo, auditoría.

## Adelanto F1-5: invitaciones (2026-11-17, rama `feat/f1-5-staff-invites`)
- El club invita por email como **ayudante** (`GROUPER`) o **árbitro** (`REFEREE`), en Configuración → Personal.
- Llega un enlace `/invitation?token=…` de un solo uso. Caduca en 14 días. Solo se guarda su hash. Reenviar: como pronto al minuto, y anula el anterior. Máximo 50 pendientes por evento.
- Se acepta con una cuenta completa del **mismo email** (verificado). Otra cuenta ve para quién es y puede cambiar de cuenta. Sin sesión, el inicio de sesión vuelve al enlace.
- El club ve las pendientes (y las caducadas), las anula y quita a cada persona por rol. Un árbitro con tapiz no se quita: antes se le saca del tapiz.
- Datos: `staff_invitation` (email, rol, hash, enviada, caduca, aceptada por). API: `GET/POST /events/{id}/invitations`, `DELETE /events/{id}/invitations/{id}`, `DELETE /events/{id}/staff/{cuenta}?role=`, `POST /invitations/view|accept {token}`.
- El nombre por evento (`staffNames`) sigue hasta que las cuentas tengan nombre (`perfiles-menores`/M6): hoy es lo único que pone nombre a un email en los tapices.
- Tests: `StaffInvitationTest`; app: Configuración y pantalla de la invitación en 3 tamaños.

## Adelanto F1-7 C: permisos por persona (2026-11-18, #130 y rama `feat/staff-panel-access`)
- Lista aprobada por Raul: ver grupos, tapices y combates sin cambiar nada (`VIEW`, añadido en la C2), crear y deshacer grupos (`GROUPS`), formar equipos (`TEAMS`), pesos y estaturas (`MEASURES`), arbitrar su tapiz (`OWN_MAT`), comenzar y finalizar la fase (`PHASE`), panel de control (`CONTROL`: mover, reordenar, saltar descanso, inhabilitar tapices), resolver revisiones (`REVIEWS`), importar CSV de un dispositivo (`DEVICE_IMPORT`), alumnos (`PARTICIPANTS`), mover grupos entre tapices sin el resto del panel (`MOVE_GROUPS`, GR-4: para un árbitro de confianza).
- El club lo puede todo. Reabrir una fase y gestionar el personal y sus permisos: solo el club.
- Por defecto: ayudante = grupos, equipos y medidas; árbitro = su tapiz (lo de antes). Con los dos roles, la suma.
- El club los marca por persona en Configuración → Personal (icono junto a cada una). Al quitar a alguien del todo, vuelve a los de su rol. Una fase nueva copia los de la anterior.
- Datos: `event_staff_permissions` (evento, cuenta, lista); sin fila = los del rol. API: `PUT /events/{id}/staff/{cuenta}/permissions {permissions}` (club); `permissions` en «mis eventos» y en el personal de Configuración.
- Personal configurable del todo (Raul, 2026-11-18): el rol solo da los permisos iniciales. Cualquier combinación vale: solo mirar, solo arbitrar, solo grupos, árbitro que además hace grupos…
- Cualquiera con «Arbitrar su tapiz» se puede asignar a un tapiz, no solo quien entró como árbitro. El club nunca.
- App: «Crear grupos» con grupos, equipos, medidas o ver; «Tapiz N» con su tapiz; «Panel del evento» (C2) con ver, panel de control, revisiones, alumnos o CSV.
- Panel del ayudante: pestaña Tapices (ver, control o revisiones) y Alumnos (alumnos); clasificación y configuración, solo el club. Con una sola pestaña, sin barra de navegación.
- Cada acción según su permiso: inhabilitar y mover (control), aplicar o descartar una revisión (revisiones), crear y deshacer grupos (grupos), formar y borrar equipos (equipos), medir (medidas). Sin nada que cambiar, aviso «Solo puedes mirar».
- Alumnos para el ayudante: alta, edición, ficha y categorías (la configuración le llega sin el personal ni sus emails). Inscribir desde otras fases y leer listas, solo el club.
- Portátil del pabellón (rama `feat/package-staff-permissions`): el paquete lleva lo elegido (`staffPermissions`, opcional); allí cada persona tiene lo mismo que en el servidor del club y un ayudante con «Arbitrar su tapiz» puede ir en un tapiz. Paquetes anteriores: los del rol.
- Tests: `StaffPermissionsTest`, `EventPackageServiceTest`; app: Personal, barra de fase, panel del ayudante, tapices y grupos en solo lectura.

## Adelanto: acceso por QR (Raul, 2026-11-20)
- Para quien ayuda sin cuenta (o la usará una sola vez): el club escribe su nombre y le enseña un QR. Al escanearlo entra en una **cuenta temporal** de ese evento, sin registrarse.
- Dónde: Configuración → Tapices (icono QR junto a cada tapiz: árbitro de ese tapiz) y «Acceso por QR» (ayudante para grupos). Avisa de tapices sin árbitro y de que nadie más que el club hace grupos.
- Permisos: los del rol (árbitro = su tapiz; ayudante = grupos, equipos y medidas), cambiables en «Personal» como los demás. Solo dentro del evento: no crea eventos ni ligas, no acepta invitaciones ni toca ajustes de cuenta (403).
- Una sesión a la vez: el código sirve **una vez** y entrar cierra cualquier otra sesión de esa cuenta. Si se cae la sesión, se vuelve a entrar con **usuario y contraseña temporales** (`qr-…` y 8 caracteres sin letras parecidas), que el club ve junto al QR (la contraseña solo al crearlo o renovarlo). «Nuevo QR» da otro código y otra contraseña y saca al dispositivo anterior. «Quitar acceso» la cierra en todas las fases.
- Fases (Raul, 2026-11-23): vive mientras dure la fase. Una fase creada antes de terminarla se queda el acceso con su tapiz; al terminar una fase, la cuenta sigue si tiene acceso en otra abierta. Un QR para un tapiz con árbitro avisa de quién lo deja.
- Confirmación: el diálogo del QR espera y avisa «X ha entrado» sin cerrarse (para apuntar la contraseña); la lista dice a qué hora entró y su usuario.
- Dura lo que la fase: al finalizarla se cierran todas (suspendidas, sin sesión); con la fase finalizada no se crean ni renuevan. Una fase nueva no las copia (ni a sus tapices) y el paquete del portátil no las lleva.
- Datos: `temporary_access` (evento, cuenta, nombre, rol, hash del código, entrada, fin; una fila por fase y cuenta) y `account.temporary` (con contraseña). Entrar a mano: login normal con el usuario `qr-…`. Inicio de sesión: `POST /api/v1/auth/temporary {token}`. Club: `GET/POST /events/{id}/temporary-access`, `POST …/{id}/renew`, `POST …/{id}/end`. Enlace: `/qr?code=…`.
- Tests: `TemporaryAccessTest`; app: `qr_access_test`, `qr_sign_in_screen_test`.

## Estado
Adelantos F1-5 y F1-7 C en pruebas. Pendiente: roles libres, ubicaciones, delegación y auditoría.
