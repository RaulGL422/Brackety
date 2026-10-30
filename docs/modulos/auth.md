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
- Una sola identidad de Google por cuenta (otra → 409 `PROVIDER_ALREADY_LINKED`; la de otra cuenta → 409 `IDENTITY_IN_USE`).
- Quitar la contraseña cierra todas las sesiones, también la actual. Ponerla de nuevo: "recuperar contraseña".

### Verificación de email
- Cuenta con contraseña: verificación obligatoria por enlace (Resend). Enlace válido 24 h, reenvío con límite de tasa.
- Sin verificar puede entrar y verificar, pero no crear nada de valor (perfiles de menores, inscripciones, eventos).
- Sin verificar a los 7 días → borrado definitivo. Recordatorio por email el día 5.
- Cuenta creada con Google: email ya verificado.
- Login con Google cuyo email coincide con una cuenta con contraseña **sin verificar**: esa cuenta se borra, se revocan sus sesiones, se crea la de Google y se muestra un aviso.
- Mismo caso con cuenta **verificada**: no se crea cuenta; se indica entrar con el método original y vincular desde ajustes (409 `ACCOUNT_EXISTS`).
- Primer login con Google: `REGISTRATION_REQUIRED` con el email (ya probado por Google); la app pide fecha, perfil y consentimientos y repite con el mismo token. La cuenta sin verificar solo se borra al completar.
- Cuenta borrada (lógica): login con Google da el 401 genérico.
- Registro con contraseña de un email que ya existe: misma respuesta que un registro nuevo; el email explica que ya hay cuenta.
- Recuperar la contraseña también verifica el email.
- Cambio de email: se verifica el nuevo antes de sustituir; se avisa al antiguo.

### Sesión
- JWT de acceso 15 min + refresh rotatorio de 30 días (se renueva en cada uso).
- Reutilizar un refresh ya usado → se revoca toda su familia (sesión) y se avisa por email. Excepción: en los 10 s siguientes a usarlo solo da 401, sin revocar ni avisar (dos pestañas o peticiones a la vez).
- El cliente hace un solo refresh a la vez.
- Web: refresh en cookie `httpOnly` + `Secure` + `SameSite`; acceso solo en memoria. Android: almacenamiento seguro.

### Seguridad
- Contraseñas con Argon2id, mínimo 10 caracteres, sin reglas de composición.
- Fallos de login en ventana de 15 min: 5 por email o 30 por IP → bloqueo 15 min (respuesta 429). La IP es pública y compartida en eventos (NAT): su umbral solo frena ataques masivos.
- Cada bloqueo tiene un id corto (`L-7K2F`) que va en el 429; el superadmin puede revocarlo desde admin (con auditoría).
- Al bloquearse un email existente: un único aviso por email con enlace para cambiar la contraseña.
- Filas de intentos (IP en claro, cuenta si existe) se purgan al pasar ventana y bloqueo.
- Limitador por IP en la app (configurable por entorno): 3000 peticiones/min en la API, 20/min en `/api/v1/auth/**` salvo refresh, 600/min en refresh → 429 `problem+json` con `Retry-After`. Primera barrera, más fina, en Cloudflare.
- La cookie de refresh solo vuelve por cookie: si el token llegó en la cookie, nunca sale en el cuerpo.
- Cliente web identificado por cabecera `X-Client: web` (refresh en cookie); sin ella, refresh en el cuerpo.
- Registro, login y recuperación responden igual exista o no la cuenta (sin enumeración).
- Avisos por email: bloqueo por fallos, identidad vinculada/desvinculada, cambio de contraseña o email, reutilización de refresh.

### Registro y perfiles
- Registro: fecha de nacimiento, perfil inicial (Club, Entidad Externa, Ayudante, Externo, Alumno) y aceptación de términos y privacidad con fecha y versión.
- Menor de 14 no se registra solo: lo da de alta su tutor (`perfiles-menores.md`).
- Perfiles adicionales desde ajustes según combinaciones de `roles/README.md`.
- Club y Entidad Externa: alta libre, pero no publican eventos hasta que el superadmin los valida.

### Superadmin y RGPD
- Superadmin: usuario único por entorno, credenciales iniciales por variables de entorno, endpoint separado, solo tras Cloudflare Access.
- Borrado de cuenta y exportación de datos (`06-legal-rgpd.md`): borrado lógico, definitivo a los 30 días, resultados anonimizados.

## Datos
- `account`: email, hash de contraseña, email verificado, fecha de nacimiento, idioma, estado (activa, borrada lógica), fechas.
- `identity`: cuenta, proveedor, `sub`, email del proveedor.
- `profile`: cuenta, tipo, validado por superadmin (solo organizadores).
- `consent`: cuenta, documento, versión, fecha.
- `refresh_token`: hash, familia, cuenta, caducidad, usado/revocado.
- `email_token`: hash, propósito (verificar, recuperar, cambio de email), caducidad, usado.
- `login_attempt`: clave (hash de email o IP), IP en claro o cuenta si existe, fallos, último fallo, id de bloqueo, bloqueado hasta.

## API (borrador)
- `POST /auth/google` `{idToken, registration?: {birthDate, profile, acceptedTermsVersion, acceptedPrivacyVersion, locale}}` → `{status: SIGNED_IN, accessToken, expiresIn, refreshToken?, emailVerified, replacedUnverifiedAccount}` (sesión como el login) o `{status: REGISTRATION_REQUIRED, email}`.
- `GET /me/identities` → `[{method: PASSWORD}, {method: GOOGLE, email, linkedAt}]`. `POST /me/identities/google` `{idToken}`, `DELETE /me/identities/google`, `DELETE /me/password` → 204.
- Errores 409 con `code` en el problem+json. Solo en local: `POST /auth/dev/google-token` `{subject, email}` (doc 08).
Todos bajo `/api/v1`: `POST /auth/register`, `/auth/login`, `/auth/google`, `/auth/refresh`, `/auth/logout`, `/auth/email/verify`, `/auth/email/resend`, `/auth/password/forgot`, `/auth/password/reset`, `/me`, `/me/profiles`, `/me/identities`, `/me/email`, `DELETE /me`, `GET /me/export`. Superadmin: `/admin/auth/login`, `/admin/organizers/{id}/validate`, `GET /admin/auth/locks`, `DELETE /admin/auth/locks/{lockId}`.

## Pantallas
Inicio de sesión, registro con selector de perfil, verificación pendiente, recuperar contraseña, ajustes de cuenta (identidades, perfiles, email, idioma, exportar/borrar). Admin: login de superadmin, bloqueos activos con revocación.

## Offline
- La sesión sigue válida sin red mientras el refresh no caduque. El acceso caducado se renueva al volver la red.
- Login, registro y ajustes de cuenta requieren conexión.

## Tests
Login por cada método, refresh/reutilización, límites de tasa, bloqueo con ventana y umbrales, revocación desde admin, sin enumeración, verificación y purga a 7 días, cuenta sin verificar sustituida por Google, vinculación y desvinculación, borrado y anonimizado.

## Estado
En curso. Tareas (una rama cada una, en este orden):
1. `feat/auth-register-login` · migración, registro con perfil y consentimiento, login email, JWT + refresh rotatorio, cookie web, logout, bloqueo con ventana e id, limitador general.
2. `feat/auth-email` · verificación, recuperación, purga y recordatorio, avisos de seguridad incluido bloqueo (Resend).
3. `feat/auth-google` · login Google, sustitución de cuenta sin verificar, vincular y desvincular.
4. `feat/auth-me` · `/me`, perfiles adicionales, cambio de email, borrado y exportación.
5. `feat/auth-superadmin` · superadmin por entorno, validación de organizadores, listar y revocar bloqueos con auditoría.
6. `feat/auth-screens-login` · app: login, registro, verificación pendiente, recuperar; cliente HTTP con refresh (uno a la vez) y 429 con `lockId`.
7. `feat/auth-screens-settings` · app: ajustes de cuenta.
8. `feat/auth-admin-login` · admin: login de superadmin y pantalla de bloqueos.
