# Módulo · legal-paginas

## Objetivo
Páginas legales públicas y control de cumplimiento mínimo antes de publicar.

## Páginas (ES y EN)
Política de privacidad, términos de uso, política de cookies, aviso legal, contacto/reportes. Incluyen: responsable (Raul, persona física), finalidades, base jurídica, destinatarios (Cloudflare, Resend, Firebase, Apple, Google), retención, derechos y cómo ejercerlos, menores, no gestión de pagos, canal de reportes.

## Reglas
- Textos versionados; cada aceptación guarda versión y fecha (`consent`).
- Cookies solo técnicas; sin analítica sin consentimiento.
- Si cambia un texto material, se pide nueva aceptación.
- **Puerta legal**: sin `PRIVACY_CONTACT_EMAIL`, la API rechaza publicar eventos y pasar de fase (`403` con código `LEGAL_GATE`); la UI explica el motivo.
- Enlaces a legal visibles en registro, pie de la web y ajustes.
- Claude redacta; antes del lanzamiento, revisión profesional (`pendientes.md`).

## Datos
`legal_document` (tipo, idioma, versión, contenido), `consent`.

## Pantallas
Páginas legales, pantalla de aceptación en registro, aviso de puerta legal para organizadores.

## Tests
Puerta legal activa/inactiva, versión de consentimiento, páginas servidas en ambos idiomas.

## Estado
Pendiente.
