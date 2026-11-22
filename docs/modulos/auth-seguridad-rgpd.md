# auth · seguridad, registro y RGPD

Parte de `auth.md`, que sigue siendo el doc del módulo.

## Seguridad
- Contraseñas con Argon2id, mínimo 10 caracteres, sin reglas de composición.
- Fallos de login en ventana de 15 min: 5 por email o 30 por IP → bloqueo 15 min (respuesta 429). La IP es pública y compartida en eventos (NAT): su umbral solo frena ataques masivos.
- Cada bloqueo tiene un id corto (`L-7K2F`) que va en el 429; el superadmin puede revocarlo desde admin (con auditoría).
- Al bloquearse un email existente: un único aviso por email con enlace para cambiar la contraseña.
- Filas de intentos (IP en claro, cuenta si existe) se purgan al pasar ventana y bloqueo.
- Limitador por IP en la app (configurable por entorno): 3000 peticiones/min en la API, 20/min en `/api/v1/auth/**` salvo refresh, 600/min en refresh → 429 `problem+json` con `Retry-After` (expuesta por CORS para la web). El 429 lleva las cabeceras CORS si el origen está permitido. Los preflight `OPTIONS` solo cuentan en el límite general. Primera barrera, más fina, en Cloudflare.
- La cookie de refresh solo vuelve por cookie: si el token llegó en la cookie, nunca sale en el cuerpo.
- Cliente web identificado por cabecera `X-Client: web` (refresh en cookie); sin ella, refresh en el cuerpo.
- Registro, login y recuperación responden igual exista o no la cuenta (sin enumeración).
- Avisos por email: bloqueo por fallos, identidad vinculada/desvinculada, cambio de contraseña o email, reutilización de refresh.

## Registro y perfiles
- Registro: perfil inicial (Club, Entidad Externa, Ayudante, Externo, Alumno) y aceptación de términos y privacidad con fecha y versión.
- Personas (Ayudante, Externo, Alumno): fecha de nacimiento obligatoria (mínimo 14 años).
- Organizadores (Club, Entidad Externa): sin fecha de nacimiento. Casilla "soy mayor de edad y represento a esta organización" (se guarda como consentimiento `ORGANIZER_DECLARATION`), nombre y CIF obligatorios. CIF normalizado y validado por formato y dígito de control (400 `INVALID_TAX_ID`); puede repetirse entre cuentas. Mandar un dato del otro tipo: 400.
- App: solo ofrece Club y Ayudante; el resto solo con `APP_ENV=dev` (entorno local) hasta que sus módulos existan.
- App: tras el 202 del registro inicia sesión con los mismos datos. Cuenta nueva → dentro con el aviso de verificar; si no → "revisa tu email" (no revela más que el propio login).
- Hasta `legal-paginas`, la app envía la versión provisional `2026-11-draft` en términos y privacidad, con una única casilla sin enlaces.
- Menor de 14 no se registra solo: lo da de alta su tutor (`perfiles-menores.md`). La app lo bloquea también antes de enviar.
- Perfiles adicionales desde ajustes (exige email verificado): un perfil cualquiera, o Alumno + Ayudante, o Externo + Ayudante; lo demás 409 `PROFILE_COMBINATION_NOT_ALLOWED`. El último no se quita (409 `LAST_PROFILE`). Organizador nuevo, sin validar.
- Club y Entidad Externa: alta libre, pero no publican eventos hasta que el superadmin los valida.
- App, ajustes: ofrecen añadir los perfiles del registro que dejan una combinación permitida, nunca organizadores (piden nombre y CIF). El último perfil no muestra "quitar".
- Idioma: con sesión, la app usa el de la cuenta (`/me`), que también es el de los emails; el selector de ajustes cambia los dos (`PATCH /me`). Sin sesión, el del dispositivo. es y en.

## Superadmin y RGPD
- Superadmin: usuario único por entorno (`SUPERADMIN_EMAIL` + `SUPERADMIN_PASSWORD_HASH` Argon2id); sin ellas, login 503. Cambiar la contraseña = cambiar la variable y reiniciar.
- Todo `/api/v1/admin/**` (login incluido) exige la cabecera `Cf-Access-Jwt-Assertion`: RS256 con las claves del equipo, `iss` `https://<CF_ACCESS_TEAM_DOMAIN>`, `aud` con `CF_ACCESS_AUD`, `exp` con el reloj (60 s de margen). Falta o inválida: 403; claves inaccesibles o variables vacías: 503. En local la pone un Cloudflare simulado (`08-ejecucion-local.md`). La app admin llama a la API por su propio host (proxy nginx, `09-despliegue.md`).
- Sesión de superadmin: JWT de 1 h con `purpose` `ADMIN`, sin refresh. La API de usuarios no lo acepta (401) y la de superadmin solo acepta ese (401).
- Login de superadmin: 401 genérico; contador propio (5 fallos en 15 min → 15 min, tipo `ADMIN` en el listado) más el de IP compartido con el login normal, y el mismo limitador; siempre se comprueba el hash. Los fallos del login público con su email no le afectan, ni al revés.
- Bloqueos activos: se listan (email de la cuenta si existe, IP si es de IP) y se revocan; revocar borra los fallos y el usuario puede reintentar. Caducado o desconocido: 404.
- Validar organizador (Club, Entidad Externa de cuenta activa): idempotente; la primera vez avisa por email en su idioma. Sin perfil organizador, inexistente o borrada: 404.
- Auditoría (`admin_audit`): login, bloqueo revocado y organizador validado, en la misma transacción. Sin IP ni emails; objetivo en texto, sin FK.
- Acciones delicadas (borrar cuenta, cambiar email, exportar, quitar contraseña, desvincular Google) exigen reauth: `POST /me/reauth` con contraseña o Google → token de 5 min en la cabecera `X-Reauth`. Sin él: 403 `REAUTH_REQUIRED`; prueba incorrecta (también token de Google inválido o caducado): 403 `REAUTH_FAILED`; Google no disponible: 503. La contraseña fallida cuenta para el bloqueo por email e IP.
- Borrado de cuenta (`06-legal-rgpd.md`): lógico, cierra todas las sesiones y avisa por email con la fecha; definitivo a los 30 días (tarea diaria, cascade, cuenta a cuenta: la que falla se registra por id y no frena a las demás; ahí se anonimizarán resultados cuando existan). Dueño de eventos: 409 `OWNS_EVENTS`; antes cede o borra el evento.
- Suspensión (superadmin, `superadmin-reportes.md`): `account.suspended_at`. Cierra todas las sesiones y, mientras dure, ningún inicio de sesión empieza (contraseña, Google, restaurar: 403 `ACCOUNT_SUSPENDED`, comprobado en `SessionService.start`) y ningún token se acepta, aunque sea del mismo segundo. Los datos se conservan. La app lo explica en el login.
- En esos 30 días: login con contraseña correcta o Google → 403 `ACCOUNT_PENDING_DELETION` con `deletesOn` y `restoreToken` (5 min); `POST /auth/restore` la reactiva y da sesión. Credenciales malas: 401 genérico. Registro con ese email: 202 y aviso al dueño (1 cada 60 s). Google con ese email sin identidad: 409 `ACCOUNT_EXISTS`.
- Pasados los 30 días, aunque la purga no haya corrido, es como si no existiera: login 401 genérico, `POST /auth/restore` 401, registro con ese email 202 sin aviso a nadie.
- Exportación: JSON descargable con cuenta (sin hash), perfiles, identidades (sin `sub`) y consentimientos.
