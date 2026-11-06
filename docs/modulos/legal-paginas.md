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
En `app/lib/features/legal/`:
- Página legal `/legal/<tipo>`, con o sin sesión, en el idioma de la app. Columna de lectura (720), cargando / error con reintentar, tablas con scroll horizontal en móvil, enlaces a los otros 3 documentos. Tipo desconocido → "no existe". Enlaces del Markdown: fuera de la app solo http(s) y mailto.
- Registro: la casilla enlaza "términos de uso" y "política de privacidad" (se abren encima, sin perder el formulario). Las versiones salen de `GET /api/v1/legal` al abrir (sin caché del navegador). Con `409 LEGAL_VERSION_OUTDATED`: recarga versiones, desmarca la casilla y pide aceptar de nuevo.
- Pie en las pantallas sin sesión (todas las de `AuthFormPage`): Privacidad · Términos · Cookies · Aviso legal · Licencias.
- Ajustes: sección "Legal" con los 4 documentos y las licencias.
- Aviso "los datos del alumno se tratan según la política de privacidad" (enlazada) en el formulario de alumno del club y en el paso de consentimiento de la importación.
- Licencias de software (`showLicensePage`): siguen en la pantalla Conexión de `brackety_core` (la usa el admin) y se añaden al pie y a los ajustes de la app.
- Pendiente: aviso de puerta legal para organizadores (cuando exista publicar eventos).

## Tests
Puerta legal activa/inactiva, versión de consentimiento, páginas servidas en ambos idiomas.

## Plan (PRs en serie)
1. Back: textos versionados ES/EN, `GET /api/v1/legal/{tipo}`, validar versiones aceptadas en registro, puerta `LEGAL_GATE`, variables en `.env.example`.
2. Front: páginas públicas en la web y la app, casilla del registro con enlaces, pie, ajustes, licencias; aviso de privacidad visible en inscripción e importación (cubre el pendiente de la F1).

## Estado
En pruebas: pasos 1-2 hechos (back y front de la app). Falta la prueba manual de Raul y la puerta `LEGAL_GATE` cuando existan publicar eventos y pasar de fase (2026-11-04).
