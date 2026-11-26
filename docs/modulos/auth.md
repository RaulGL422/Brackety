# Módulo · auth

## Objetivo
Cuentas, login y sesión compartidos entre web y Android.

## Reglas
### Métodos e identidades
- Métodos: email + contraseña y Google. Apple pospuesto (no hay iOS nativo; exige Apple Developer). El modelo de identidades ya lo admite.
- Token de Google verificado en servidor. La identidad se guarda por `sub` del proveedor, nunca por email.
- Email de la cuenta único. Una identidad vinculada a mano puede tener otro email.
- Vincular identidades solo a mano desde ajustes, con sesión iniciada. Nunca fusión automática.
- No se puede desvincular la última identidad. Quitar la contraseña exige otro método vinculado (409 `LAST_SIGN_IN_METHOD`).
- Token de Google: RS256 con las claves de Google, `iss` `accounts.google.com` (con o sin `https://`), `aud` en `GOOGLE_CLIENT_ID` (lista: web y Android), `exp` con el reloj (60 s de margen), `email_verified` true. Sin `GOOGLE_CLIENT_ID`: 503 y el resto de la API funciona.
- Cuenta sin verificar: solo vincula un Google con su mismo email (y queda verificada); con otro email, 403 `EMAIL_NOT_VERIFIED` (evita que quien se registró con un email ajeno deje su Google dentro antes de que el dueño la recupere).
- Claves de Google inaccesibles: 503 (no es un token inválido).
- Una sola identidad de Google por cuenta (otra → 409 `PROVIDER_ALREADY_LINKED`; la de otra cuenta → 409 `IDENTITY_IN_USE`).
- Quitar la contraseña cierra todas las sesiones, también la actual. Ponerla de nuevo: "recuperar contraseña".

### Verificación de email
- Cuenta con contraseña: verificación obligatoria por enlace (Resend). Enlace válido 24 h, reenvío con límite de tasa.
- Sin verificar puede entrar y verificar, pero no crear nada de valor (perfiles de menores, inscripciones, eventos).
- Sin verificar a los 7 días → borrado definitivo. Recordatorio por email el día 5.
- Cuenta creada con Google: email ya verificado. Vincular Google con el mismo email también verifica la cuenta.
- Login con Google cuyo email coincide con una cuenta con contraseña **sin verificar**: esa cuenta se borra, se revocan sus sesiones, se crea la de Google y se muestra un aviso.
- Mismo caso con cuenta **verificada**: no se crea cuenta; se indica entrar con el método original y vincular desde ajustes (409 `ACCOUNT_EXISTS`).
- Primer login con Google: `REGISTRATION_REQUIRED` con el email (ya probado por Google); la app pide fecha, perfil y consentimientos y repite con el mismo token. La cuenta sin verificar solo se borra al completar.
- Registro con contraseña de un email que ya existe: misma respuesta que un registro nuevo; el email explica que ya hay cuenta.
- Recuperar la contraseña también verifica el email.
- Cambio de email (+ reauth): enlace de 24 h al email nuevo, máx. 1 cada 60 s. Si ya es de otra cuenta, misma respuesta 202 y a ese email le llega "ya hay una cuenta". Al confirmar se recomprueba que esté libre (si no, enlace inválido), queda verificado, se cierran todas las sesiones y se avisa al antiguo (`n***@dominio`). Google no cambia. Pedir el email actual: 202 sin enviar nada.

### Sesión
- JWT de acceso 15 min (`ACCESS_TTL`; 12 h en el pabellón, `servidor-local.md`) + refresh rotatorio de 30 días (se renueva en cada uso).
- Reutilizar un refresh ya usado cuando la sesión ya avanzó → se revoca toda su familia (sesión) y se avisa por email. Excepción (respuesta perdida, GR-8): hasta 12 h, mientras el refresh que emitió no se haya usado, devuelve ese mismo refresh con un acceso nuevo; si ya se rotó en los 10 s anteriores (dos pestañas), 401 sin revocar ni avisar. Cuenta borrada, revocada o API reiniciada: 401.
- Decisión (2026-11-06): el par emitido se guarda en memoria del proceso solo durante el margen, por hash del token rotado; la BD solo tiene hashes y no permite recuperarlo. Cifrarlo en la misma memoria no añade nada; emitir otro par de la familia dejaría dos hijos vivos. Vale porque la API es una sola instancia (Pi y portátil).
- El cliente hace un solo refresh a la vez.
- Cambio de credenciales (recuperar contraseña, confirmar cambio de email, quitar contraseña) o borrado: se revocan los refresh, se borran los enlaces de email pendientes y se fija `sessions_revoked_at`. Los tokens de acceso y reauth emitidos antes (`iat` en segundos) dejan de valer: 401 y 403 `REAUTH_REQUIRED`.
- Cada petición lee la cuenta una vez: inexistente o borrada → 401.
- Web: refresh en cookie `httpOnly` + `Secure` + `SameSite`; acceso solo en memoria. Android: almacenamiento seguro.

### Seguridad, registro, superadmin y RGPD
En `auth-seguridad-rgpd.md`.

## Datos
- `account`: email, hash de contraseña, email verificado, fecha de nacimiento (nula en organizadores), idioma, estado (activa, borrada lógica) con `deleted_at`, corte de sesiones `sessions_revoked_at`, fechas.
- `identity`: cuenta, proveedor, `sub`, email del proveedor.
- `profile`: cuenta, tipo, validado por superadmin, nombre de la organización y CIF (solo organizadores).
- `consent`: cuenta, documento, versión, fecha.
- `refresh_token`: hash, familia, cuenta, caducidad, usado/revocado.
- `email_token`: hash, propósito (verificar, recuperar, cambio de email), email nuevo (solo cambio), caducidad.
- `admin_audit`: fecha, acción, objetivo (lockId o accountId).
- `login_attempt`: clave (hash de email o IP), IP en claro o cuenta si existe, fallos, último fallo, id de bloqueo, bloqueado hasta.

## API (borrador)
- `POST /auth/google` `{idToken, registration?: {birthDate, profile, acceptedTermsVersion, acceptedPrivacyVersion, locale}}` → `{status: SIGNED_IN, accessToken, expiresIn, refreshToken?, emailVerified, replacedUnverifiedAccount}` (sesión como el login) o `{status: REGISTRATION_REQUIRED, email}`.
- `GET /me/identities` → `[{method: PASSWORD}, {method: GOOGLE, email, linkedAt}]`. `POST /me/identities/google` `{idToken}`, `DELETE /me/identities/google`, `DELETE /me/password` → 204.
- `GET /me` → `{email, emailVerified, birthDate, locale, profiles: [{type, validated, organizationName?, taxId?}], signInMethods}` (`birthDate` nulo en organizadores). `PATCH /me` `{locale: es|en}`. `POST /me/profiles` `{type}`, `DELETE /me/profiles/{type}` → 204.
- `POST /me/reauth` `{password}` o `{googleIdToken}` → `{reauthToken, expiresIn}`. Con `X-Reauth`: `POST /me/email` `{newEmail}` → 202; `DELETE /me` → `{deletesOn}`; `GET /me/export` → adjunto JSON.
- `POST /auth/email/change/confirm` `{token}` → 204. `POST /auth/restore` `{restoreToken}` → sesión como el login.
- Errores 409 con `code` en el problem+json. Solo en local: `POST /auth/dev/google-token` `{subject, email}` (doc 08).
Todos bajo `/api/v1`: `POST /auth/register`, `/auth/login`, `/auth/google`, `/auth/refresh`, `/auth/logout`, `/auth/email/verify`, `/auth/email/resend`, `/auth/password/forgot`, `/auth/password/reset`, `/auth/password/reset/check` (`{token}` → 204 válido, 400 inválido; no lo gasta), `/me`, `/me/profiles`, `/me/identities`, `/me/email`, `DELETE /me`, `GET /me/export`. Superadmin: `/admin/auth/login`, `/admin/organizers/{id}/validate`, `GET /admin/auth/locks`, `DELETE /admin/auth/locks/{lockId}`.
- `POST /admin/auth/login` `{email, password}` → `{accessToken, expiresIn}`. `GET /admin/auth/locks` → `[{lockId, type: EMAIL|IP|ADMIN, lockedUntil, email, ip}]`; `DELETE /admin/auth/locks/{lockId}` → 204.
- `GET /admin/organizers?validated=true|false` (sin filtro: todos) → `[{accountId, email, profileType, organizationName, taxId, validated, createdAt}]` (`createdAt` del perfil); `POST /admin/organizers/{accountId}/validate` → 204.

## Pantallas
Inicio de sesión, registro con selector de perfil, verificación pendiente, recuperar contraseña, ajustes de cuenta (identidades, perfiles, email, idioma, exportar/borrar). Admin: login de superadmin, bloqueos activos con revocación, organizadores con validación.
- Admin (`admin/lib/features/auth|locks|organizers/`): token solo en memoria (recargar = entrar otra vez); cualquier 401 → login con "sesión caducada". Sin sesión solo abren Conexión y Diseño (debug). Bloqueos: tipo, quién, tiempo restante, revocar con confirmación. Organizadores: filtro Pendientes/Validados/Todos, nombre y CIF ("Sin datos" si faltan), validar con confirmación. Tabla en escritorio, tarjetas en móvil y tablet.
- Pantallas sin sesión (`AuthFormPage`, 2026-11-25): sin barra superior; arriba el nombre BRACKETY (atrás si hay adónde, Conexión solo en debug), título como encabezado y línea de qué pide; etiquetas siempre sobre el campo; al pie, textos legales agrupados (2×2 en móvil, una fila en tableta, franja en escritorio) y aparte versión y licencias. Entrar: «¿Has olvidado…?» bajo la contraseña y «Crear una cuenta» como botón propio.
- Registro, contraseña y QR (2026-11-26): tipo de cuenta en desplegable con su explicación; bloques «Tu club» (o entidad), «Tus datos» y «Tu cuenta»; requisitos de contraseña que se marcan al escribir; si falla, aviso arriba con cuántas cosas faltan y salto a la primera; «Revisa tu email» con el email y reenvío; recuperar con aviso para cuentas por QR y «Probar con otro email»; enlace caducado explicado; QR con sesión abierta dice qué pasa y deja seguir con la cuenta.
- Código en `app/lib/features/auth/`. Verificación pendiente: aviso no bloqueante encima de toda la app (con reenvío).
- Enlaces de email (`/verify-email`, `/reset-password`, `/forgot-password`, `/confirm-email-change`) abren en cualquier estado de sesión; web con URLs sin `#`.
- Menú de la cuenta (Mis eventos): quién está dentro, «Mi cuenta» y «Ajustes de la app» por separado (Raul, 2026-11-26). Mi cuenta (`/settings`): Acceso (email, métodos de acceso), Quién eres (perfiles), Privacidad y datos (exportar —Android: compartir; web: descarga—, textos legales, borrar) y cerrar sesión. Ajustes de la app (`/app-settings`): idioma, apariencia, preferencias del dispositivo (`07-diseno.md`) y Acerca de (novedades en debug, licencias, versión, Conexión para soporte). Acciones delicadas: diálogo de contraseña, token de reauth en memoria hasta caducar. Sin Google hasta tener los client IDs.

## Offline
- La sesión sigue válida sin red mientras el refresh no caduque. El acceso caducado se renueva al volver la red.
- Login, registro y ajustes de cuenta requieren conexión.

## Tests
Login por cada método, refresh/reutilización, límites de tasa, bloqueo con ventana y umbrales, revocación desde admin, sin enumeración, verificación y purga a 7 días, cuenta sin verificar sustituida por Google, vinculación y desvinculación, borrado y anonimizado.

## Estado
Tareas 1-9 hechas; en pruebas: falta la prueba manual del módulo completo de Raul. Tareas (una rama cada una, en este orden):
1. `feat/auth-register-login` · migración, registro con perfil y consentimiento, login email, JWT + refresh rotatorio, cookie web, logout, bloqueo con ventana e id, limitador general.
2. `feat/auth-email` · verificación, recuperación, purga y recordatorio, avisos de seguridad incluido bloqueo (Resend).
3. `feat/auth-google` · login Google, sustitución de cuenta sin verificar, vincular y desvincular.
4. `feat/auth-me` · `/me`, perfiles adicionales, cambio de email, borrado y exportación.
5. `feat/auth-superadmin` · superadmin por entorno, validación de organizadores, listar y revocar bloqueos con auditoría. Hecha (2026-10-31).
6. `feat/auth-screens-login` · app: login, registro, verificación pendiente, recuperar; cliente HTTP con refresh (uno a la vez) y 429 con `lockId`. Hecha (2026-10-31).
7. `feat/auth-organizer-signup` · registro de Club y Entidad Externa sin fecha de nacimiento: casilla "soy mayor de edad y represento a la organización", nombre y CIF obligatorios (formato y dígito de control, repetible entre cuentas); el superadmin los ve al validar. Hecha (2026-11-02).
8. `feat/auth-screens-settings` · app: ajustes de cuenta. Hecha (2026-11-02).
9. `feat/auth-admin-login` · admin: login de superadmin y pantalla de bloqueos y organizadores. Hecha (2026-11-02).
