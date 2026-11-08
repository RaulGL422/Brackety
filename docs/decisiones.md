# Decisiones

Formato: fecha · decisión · motivo.

Las de octubre de 2026, en `decisiones-2026-10.md`.

- 2026-11-02 · Tras registrarse, la app inicia sesión con los mismos datos · el 202 neutro parecía un registro roto; no filtra nada nuevo (ya se podía probar el login tras registrarse).
- 2026-11-02 · El registro de la app solo ofrece Club y Ayudante; Alumno, Externo y Entidad Externa solo con `APP_ENV=dev` · el resto de perfiles aún no tiene módulos; decidido por Raul.
- 2026-11-02 · `POST /auth/password/reset/check` comprueba el enlace sin gastarlo · la pantalla dice "enlace inválido" al abrirlo, no tras escribir la contraseña; decidido por Raul.
- 2026-11-02 · Organizadores (Club, Entidad Externa) se registran sin fecha de nacimiento: casilla de mayor de edad y representante, nombre y CIF obligatorio validado por formato y dígito, repetible · la fecha no aporta en una organización y el CIF ayuda al superadmin a validar; tarea propia; decidido por Raul.
- 2026-10-31 · Web con URLs sin `#` (path strategy) · los enlaces de email (`/verify-email?token=…`) deben abrir la pantalla correcta; nginx ya devuelve `index.html`.
- 2026-10-31 · Categorías por equipos en el prototipo: formato, tamaño de equipo y de grupo por categoría; grupo de 4 equipos de 3; un combate Tambo equipo contra equipo; cada miembro suma los puntos de su equipo · cambio de planes de Raul para la Fase 1.
- 2026-10-31 · Equipo fantasma = 3 alumnos cualesquiera de la categoría (no un equipo ya hecho); botón "Grupo individual" en categorías por equipos para los sobrantes · decidido por Raul.
- 2026-10-31 · Equipos con nombre "Equipo N" numerado por evento · el árbitro los llama por ese nombre y no se repite entre tapices.
- 2026-11-02 · Prototipo en la Pi: web `brackety.rgal.dev`, API `brackety-api.rgal.dev`, admin `brackety-admin.rgal.dev`; imágenes de la release `v0.1.0` publicadas por el CI; equipos después del despliegue · un nivel de subdominio para el SSL gratuito de Cloudflare; compilar en la Pi es muy lento; decidido por Raul.
- 2026-11-02 · Idioma: el selector de ajustes cambia el de la app y el de la cuenta (emails); con sesión manda el de la cuenta, sin sesión el del dispositivo · una sola elección para todo; decidido por Raul.
- 2026-11-02 · Exportar datos: en Android, hoja de compartir con el JSON (`share_plus`); en web, descarga del navegador (`package:web`) · Android no tiene carpeta de descargas accesible sin permisos; decidido por Raul.
- 2026-11-02 · Ajustes de la app sin Google (ni vincular ni reauth con Google) hasta tener los client IDs: se muestra el Google ya vinculado, con desvincular y quitar contraseña · decidido por Raul.
- 2026-11-02 · Token del superadmin en la app admin solo en memoria (nunca localStorage, sessionStorage ni cookies): recargar o cerrar la pestaña = entrar otra vez; cualquier 401 de la API admin → login con "sesión caducada" · no hay refresh y es de uso esporádico; nada que robar del navegador; decidido por Raul.
- 2026-11-02 · La tarea 9 de auth incluye la pantalla de organizadores (filtro y validar, con nombre y CIF) además de login y bloqueos · sin ella la validación solo se podía hacer por API; decidido por Raul.
- 2026-11-02 · Importación masiva de alumnos (fotos, CSV, Excel, TXT) leída con `claude -p` y revisada por el club antes de inscribir; todo o nada · pruebas in situ con muchas inscripciones; decidido por Raul.
- 2026-11-02 · Claude con `ANTHROPIC_API_KEY` (condiciones comerciales y DPA), no con el token de suscripción · trata datos de menores de terceros.
- 2026-11-02 · Una inscripción puede llevar categoría elegida; si no, la de su edad · al importar, quien inscribe decide si la categoría escrita no cuadra con la edad; decidido por Raul.
- 2026-11-04 · Servidor del pabellón: portátil Windows como punto de acceso, API nativa con PostgreSQL embebido persistente y web servida por la API (sin Docker) · seguridad si falla Internet o la Pi; ligero y sin instalaciones; decidido por Raul.
- 2026-11-04 · El evento se lleva en un fichero "paquete" (configuración, staff e inscritos) que se carga al arrancar con BD vacía · arrancar en cualquier servidor sin preparar nada allí; decidido por Raul.
- 2026-11-04 · Árbitros y ayudantes con APK Android y selector de servidor (pabellón / Internet / URL) · la web por http en la red local no puede funcionar offline; decidido por Raul.
- 2026-11-04 · Offline para la F1 solo en el marcador del árbitro; el módulo completo, después · 10 días hasta la fase; decidido por Raul.
- 2026-11-04 · `legal-paginas` se adelanta a la F1; titular con nombre y `privacidad@rgal.dev`, sin NIF ni domicilio · datos reales de menores en la fase; decidido por Raul.
- 2026-11-04 · Textos legales como ficheros Markdown versionados en el servidor (no tabla `legal_document`); titular y email por variables de entorno · cambiar un texto pasa por un despliegue; también sin Internet en el servidor del pabellón.
- 2026-11-04 · Privacidad: el organizador es responsable de los datos de los alumnos que inscribe y Brackety los trata por su cuenta; Raul, responsable del resto · decidido por Raul.
- 2026-11-04 · App: `flutter_markdown_plus` 1.0.12 para los textos legales · sucesor mantenido de `flutter_markdown` (descontinuado), sin dependencias extra y con tablas desplazables.
- 2026-11-04 · App: `url_launcher` 6.3.3 · abrir fuera de la app los enlaces http(s) y mailto de los textos legales.
- 2026-11-04 · Servidor del pabellón con PostgreSQL 18 oficial (binarios portables) y el jar de producción, no el Postgres embebido de los tests · mismo código que producción y pg_dump para las copias.
- 2026-11-04 · Pabellón: el primer arranque exige `-Package` o `-Demo` (sin ninguno no arranca) · un olvido del `-Package` crearía el evento demo y obligaría a `-Reset` antes de cargar el real.
- 2026-11-04 · El paquete se carga antes de que arranque el servidor web (al crear los beans), no en `ApplicationReadyEvent` · el script da la API por lista en cuanto responde; así nunca responde con el paquete a medio cargar o rechazado.
- 2026-11-05 · APK: las URLs de "Pabellón" e "Internet" fijas en el código (excepción a "solo `API_BASE_URL`") · son las opciones del selector y la IP del punto de acceso de Windows es fija; el `API_BASE_URL` del build sigue siendo el valor por defecto.
- 2026-11-05 · APK: el servidor elegido se guarda con `flutter_secure_storage`, no `shared_preferences` · ya está para el refresh token (que es de ese servidor) y evita otra dependencia.
- 2026-11-05 · Offline F1: choque = combate "en revisión"; el club aplica o descarta las acciones del móvil · decidido por Raul.
- 2026-11-05 · Offline F1: choque si `knownEvents` no coincide con las acciones no automáticas del servidor · detecta otro dispositivo sin contar las paradas automáticas, que añade el servidor.
- 2026-11-05 · Offline F1: caché y cola en ficheros JSON, no drift · un tapiz y unas decenas de acciones; drift llega con el módulo completo.
- 2026-11-05 · Offline F1: si el servidor rechaza la sesión, la cola del árbitro se guarda para su cuenta y se envía al volver a entrar · decidido por Raul; antes se perdía sin enviarse.
- 2026-11-07 · Plugins de Claude Code `playwright` y `frontend-design` en el proyecto; `headroom` descartado · Playwright verifica la web y el admin en navegador y el diseño guía pantallas nuevas; headroom es de terceros y enruta el tráfico al modelo por un proxy.
- 2026-11-07 · Sin multigrupo en la app: un grupo cada vez; el campo `maxGroupsPerMat` sigue en servidor y paquete hasta después de la F1 · pedido por Raul; no cambiar el formato del paquete a una semana del evento.
- 2026-11-07 · Al crear grupo, tapiz Automático (menor fin estimado) o elegido a mano entre los que tienen árbitro · pedido por Raul.
- 2026-11-07 · Árbol de semántica activo en builds debug y `APP_ENV=dev` (`enableSemanticsForAutomation`) · sin él, Flutter web es un canvas y Playwright no encuentra botones ni campos; en release se mantiene apagado por rendimiento.
- 2026-11-08 · Sistema de diseño Tatami (verde igusa para la acción, oro kin para "siguiente", rojo y azul solo para esquinas) y fuentes Zen Kaku Gothic New + Saira Condensed; sustituye a Eléctrico y Barlow · pedido por Raul: la app no le resultaba intuitiva ni original, y el azul de marca se confundía con la esquina azul.
- 2026-11-08 · Marcador siempre oscuro, también en modo claro · las esquinas a todo color sobre tinta se leen mejor desde el lateral del tapiz.
- 2026-11-08 · Zen Kaku Gothic New empaquetada solo con glifos latinos (30 KB por grosor en vez de 2,3 MB) · la app no muestra japonés; la licencia OFL no reserva el nombre de esta fuente.
- 2026-11-08 · Sistema neutro multideporte (blanco, gris y tinta; color solo para competidores y estados) y Atkinson Hyperlegible Next + Saira Condensed; sustituye a Tatami · Brackety es multideporte (marca neutra, 2026-10-30) y la paleta de competidores tiene 12 colores: cualquier color de marca choca con alguno; Atkinson por legibilidad para familias y al sol. Elegido por Raul.
- 2026-11-08 · Grupos del tablero con su número en tinta, sin color · un color de grupo se confundiría con el de un competidor en otros deportes. Elegido por Raul.
