# Módulo · legal-paginas

## Objetivo
Páginas legales públicas y control de cumplimiento mínimo antes de publicar.

## Páginas (ES y EN)
Política de privacidad, términos de uso, política de cookies, aviso legal, contacto/reportes. Incluyen: responsable (Raul, persona física), finalidades, base jurídica, destinatarios (Cloudflare, Resend, Firebase, Apple, Google, Anthropic), retención, derechos y cómo ejercerlos, menores, no gestión de pagos, canal de reportes.
- Titular: nombre completo y `privacidad@rgal.dev`, sin NIF ni domicilio (decidido por Raul el 2026-11-04; se amplía con la revisión legal). Ambos por variables de entorno (`LEGAL_OWNER_NAME`, `PRIVACY_CONTACT_EMAIL`), nunca en el repo.
- Los textos se sirven también desde el servidor del pabellón (`servidor-local.md`): sin Internet deben seguir visibles.

## Reglas
- Textos versionados; cada aceptación guarda versión y fecha (`consent`).
- Cookies solo técnicas; sin analítica sin consentimiento.
- Si cambia un texto material, se pide nueva aceptación.
- **Puerta legal**: sin `PRIVACY_CONTACT_EMAIL`, la API rechaza publicar eventos y pasar de fase (`403` con código `LEGAL_GATE`); la UI explica el motivo.
- Enlaces a legal visibles en registro, pie de la web y ajustes.
- Claude redacta; antes del lanzamiento, revisión profesional (`pendientes.md`).

## Datos
- Textos en Markdown en `server/src/main/resources/legal/<tipo>.<idioma>.md` (tipos `privacy`, `terms`, `cookies`, `legal-notice`; `es`, `en`). Se leen al arrancar; si falta uno, el servidor no arranca.
- Versión actual de cada texto solo en el enum `LegalDocument` (`2026-11-04`). Aceptación obligatoria: `terms` y `privacy`.
- Marcadores `{{OWNER_NAME}}`, `{{PRIVACY_EMAIL}}`, `{{VERSION}}`; sin valor configurado se muestra "(pendiente de configurar)".
- `consent` guarda la versión aceptada; la declaración de organizador va con la versión de los términos.

## API
- `GET /api/v1/legal` (pública): documentos con versión y `acceptanceRequired`, y `privacyContactConfigured`.
- `GET /api/v1/legal/{tipo}?lang=es|en` (pública): `{type, version, lang, markdown}`. Idioma desconocido → `es`; tipo desconocido → 404. Caché pública de 5 min.
- Registro (contraseña y Google) con versión de términos o privacidad distinta de la actual → `409` `LEGAL_VERSION_OUTDATED`.

## Pantallas
Páginas legales, pantalla de aceptación en registro, aviso de puerta legal para organizadores.
- Licencias de software (`showLicensePage`): hoy en la pantalla Conexión de `brackety_core`; al hacer este módulo se mueve junto a los enlaces legales (ajustes / pie de la web).

## Tests
Puerta legal activa/inactiva, versión de consentimiento, páginas servidas en ambos idiomas.

## Plan (PRs en serie)
1. Back: textos versionados ES/EN, `GET /api/v1/legal/{tipo}`, validar versiones aceptadas en registro, puerta `LEGAL_GATE`, variables en `.env.example`.
2. Front: páginas públicas en la web y la app, casilla del registro con enlaces, pie, ajustes, licencias; aviso de privacidad visible en inscripción e importación (cubre el pendiente de la F1).

## Estado
Pendiente; planificado (2026-11-04).
