# Módulo · notificaciones

## Objetivo
Avisos por email (Resend) y push (Firebase).

## Reglas
- Eventos: invitación, aceptación/rechazo, cambio de fase, grupo asignado, tapiz y hora, resultado publicado, recordatorio de pesaje, invitación a tutor, reportes (a Raul).
- Preferencias por usuario (canal y tipo). Los de seguridad y legales no se pueden desactivar.
- Email en ES/EN según idioma del usuario; remitente de `rgal.dev`. Enlace de baja donde aplique.
- Push con tokens por dispositivo; web push opcional. Sin datos sensibles en el texto del push.
- Cola simple en base de datos con reintentos; sin broker.
- Sin envío masivo a menores sin cuenta: solo a tutores.
- Fase cerrada sola al día siguiente, o que no se pudo cerrar por combates pendientes: correo al club (F1-7).
- Raul (2026-11-18): aprovechar mucho el correo como herramienta. Proponerle una lista de avisos útiles y que elija.

## Datos
`notification`, `device_token`, `notification_preference`.

## Pantallas
Bandeja de avisos, preferencias.

## Tests
Plantillas ES/EN, preferencias respetadas, reintentos, tokens inválidos.

## Estado
Pendiente.
