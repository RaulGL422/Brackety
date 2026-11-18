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
- Raul (2026-11-18): enviar resultados (PDF/CSV) a una o varias direcciones desde el panel del club (`pendientes.md`).

## Propuesta a Raul (2026-11-18, sin respuesta aún)
Avisos por correo para que elija cuáles y en qué orden:
1. Fase cerrada sola o que no se pudo cerrar (hecho, #129) · club.
2. Invitación al personal y aviso de aceptada · invitado / club.
3. Resumen al terminar la fase: combates, revisiones pendientes, enlaces a PDF y CSV · club.
4. Revisión de combate pendiente más de X minutos · club y quien tenga «Revisiones».
5. Recordatorio el día antes: hora, tapiz asignado y enlace · personal y árbitros.
6. Te han asignado un tapiz o cambiado los permisos · esa persona.
7. Fase reabierta, con el motivo · club y personal.
8. Envío de resultados a direcciones que escribe el club.
9. Copia de seguridad hecha o fallida (Pi) · superadmin.
10. Organizador nuevo pendiente de validar · superadmin.

Para el 8 (lleva nombres de menores), propuesta: solo el PDF de la clasificación, sin nacimientos ni contactos, y una casilla del club confirmando que las direcciones son de la entidad organizadora.

## Datos
`notification`, `device_token`, `notification_preference`.

## Pantallas
Bandeja de avisos, preferencias.

## Tests
Plantillas ES/EN, preferencias respetadas, reintentos, tokens inválidos.

## Estado
Pendiente.
