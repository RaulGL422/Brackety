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
- Detalle fino de permisos: se define al construir el módulo.
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

## Adelanto F1-7 C: permisos por persona (2026-11-18, rama `feat/event-staff-permissions`)
- Lista aprobada por Raul: crear y deshacer grupos (`GROUPS`), formar equipos (`TEAMS`), pesos y estaturas (`MEASURES`), arbitrar su tapiz (`OWN_MAT`), comenzar y finalizar la fase (`PHASE`), panel de control (`CONTROL`: mover, reordenar, saltar descanso, inhabilitar tapices), resolver revisiones (`REVIEWS`), importar CSV de un dispositivo (`DEVICE_IMPORT`), alumnos (`PARTICIPANTS`).
- El club lo puede todo. Reabrir una fase y gestionar el personal y sus permisos: solo el club.
- Por defecto: ayudante = grupos, equipos y medidas; árbitro = su tapiz (lo de antes). Con los dos roles, la suma.
- El club los marca por persona en Configuración → Personal (icono junto a cada una). Al quitar a alguien del todo, vuelve a los de su rol. Una fase nueva copia los de la anterior.
- Datos: `event_staff_permissions` (evento, cuenta, lista); sin fila = los del rol. API: `PUT /events/{id}/staff/{cuenta}/permissions {permissions}` (club); `permissions` en «mis eventos» y en el personal de Configuración.
- La app enseña «Hacer grupos», «Mi tapiz» y los botones de la fase según los permisos. Pendiente C2: que el ayudante con panel, revisiones, CSV o alumnos entre al panel (`pendientes.md`).
- Tests: `StaffPermissionsTest`; app: Personal y barra de fase.

## Estado
Adelantos F1-5 y F1-7 C en pruebas. Pendiente: roles libres, ubicaciones, delegación y auditoría.
