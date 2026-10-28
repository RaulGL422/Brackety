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

## Datos
`event_role`, `role_permission`, `staff_member`, `staff_location`, `permission_audit`.

## API (borrador)
`POST /events/{id}/roles`, `PUT /events/{id}/staff/{id}/permissions`, `PUT /events/{id}/staff/{id}/locations`.

## Pantallas
Gestión de roles y permisos, asignación de ubicaciones, agenda del ayudante.

## Tests
Cada permiso permitido/denegado, delegación de un nivel, cambios en directo, auditoría.

## Estado
Pendiente. Duda abierta: cuándo exactamente se pide el detalle de permisos (al empezar el módulo).
