# Módulo · inscripciones

## Objetivo
Apuntar participantes (alumnos, equipos) y ayudantes a un evento.

## Vías
1. **QR**: todo Alumno y Ayudante tiene su QR en el inicio; un ayudante con permiso lo escanea.
2. **Manual**: nombre, apellidos, nacimiento, estatura aproximada y género. Menor sin cuenta: casilla "el tutor está de acuerdo".
3. **Invitación** por email o app (alumno, club o ayudante). Aceptar/rechazar.
4. **Club**: inscribe a sus alumnos en eventos ajenos; el organizador decide si la invitación va vía club o directa.
5. **Reinscripción**: en Liga en fases, el organizador puede importar participantes de fases anteriores.

## Reglas
- Ayudantes solo por QR o invitación aceptada.
- Estados: solicitada → aceptada → confirmada (asistencia) → retirada. Aceptar requiere permiso.
- **Asistencia y peso exacto**: un ayudante con permiso marca asistencia y registra peso antes del evento o el día previo (pesaje).
- Pago: marca pagado / no pagado (historial de quién y cuándo). Si no ha pagado, avisos al comenzar; opcionalmente bloquea inscripción.
- Un inscrito participa siempre (`liga.md` para grupos incompletos).
- Categoría asignada por edad a una fecha de corte del evento.
- Retirada tras comenzar: se registra, no se borra.

## Datos
`registration`, `payment_mark` (historial), `weigh_in`, `invitation`.

## API (borrador)
`POST /events/{id}/registrations`, `POST /events/{id}/registrations/qr`, `POST /invitations/{id}/accept`, `PATCH /registrations/{id}/payment`, `PATCH /registrations/{id}/attendance`, `PUT /registrations/{id}/weight`.

## Pantallas
Lista de inscritos con filtros, escáner de QR, ficha de inscripción, bandeja de invitaciones.

## Tests
Cada vía de inscripción, estados, historial de pagos, categoría por fecha de corte, menores pendientes.

## Estado
Pendiente.
