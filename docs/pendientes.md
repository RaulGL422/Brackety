# Pendientes

Lo que espera a alguien, ordenado por quién tiene que actuar. Lo hecho se borra (queda en git y en `decisiones.md`).

## 1. Preguntas para Raul
### Producto
- [ ] Competición del 2026-12-20: modalidades y su puntuación, categorías, tapices y servidor (`producto/competicion-2026-12-20.md`).
- [ ] GR-2 (cuando Raul pueda; el arreglo no la espera): probar en debug con el iPhone (Safari) el QR abierto desde la cámara y desde una web lectora; volver a entrar con usuario y contraseña. Debug ya preparado (2026-11-22): `ACCESS_TTL=1m`, cuenta `club1`/`club1`, evento «Open de Grappling». Al acabar, quitar `ACCESS_TTL` de `deploy/.env.debug` en la Pi (copia en `.env.debug.bak-gr2`) y `./deploy.sh debug`.
- [ ] Puntuación de la F2 (armas) y escalas de la F3 (`reglamentos/yoseikan-2027.md`, sección de abajo).
- [ ] Correos: elegir de la lista propuesta (`modulos/notificaciones.md`, «Propuesta a Raul») y si vale enviar resultados por correo; llevan datos de menores (`06-legal-rgpd.md`).
- [ ] F1-4: revisar la lista de motivos de advertencia del tambo (reglamento, cap. 3.1). Se cambia en `Discipline` o por evento.
- [ ] F2-4: dividir una categoría por sexo o peso, cuando una modalidad lo pida (en la F2 solo edad).
- [ ] Grupo con sobrante: promedio por combate, puntos brutos o caso a caso; será opción del evento.
- [ ] Equipos en torneos: plantilla, suplentes y entrenadores. Categorías reales por equipos y si hay ranking de equipos (`modulos/prototipo-f1-equipos.md`).
- [ ] Plantillas de deporte (`producto/plantillas-deporte.md`): ¿dueño la cuenta o el club? ¿galería pública o primero por enlace? ¿moderación previa o denuncias? ¿autor visible?
- [ ] Exportar a medida: probar la pantalla, «Para publicar», un ayudante con y sin «Descargar datos personales» y la auditoría en Personal (`producto/exportaciones.md`).
- [ ] Grappling: un combate reabierto por un punto olvidado no lo admite (el tiempo acabó); solo quitar puntos o añadir tiempo y volver a empezar. ¿Se permite sumar al corregir, como en tambo?
- [ ] Grappling: una persona va a una sola categoría por evento. ¿Gi y sin gi como dos eventos, o varias categorías por persona?
- [ ] Botón de acceso en Mis eventos (Raul, 2026-11-21): hoy pone siempre «Abrir la liga». El texto depende de lo que se abre: liga, competición (evento suelto) o, para árbitros y ayudantes, la fase o competición. Un evento suelto lleva además podio de liga: ¿botón directo a su panel?
- [ ] Torneo ≠ liga (Raul, 2026-11-21, **muy importante**): un torneo (evento suelto, p. ej. grappling) hoy se ve con fases, podio de liga, puntos por asistir y demás conceptos de liga. No tiene nada que ver con una liga: cada tipo debe mostrar solo lo suyo, en Mis eventos, panel, ajustes y clasificaciones. Revisar todas las pantallas con esa diferencia.
- [ ] Configuración del evento (Raul, 2026-11-21): da pereza configurar. Jugar con tamaños, subsecciones (desplegables) y mostrar según importancia; lo secundario, oculto tras interruptores. Rediseño en `producto/eventos-ux.md`.
- [ ] Invitaciones (Raul, 2026-11-26): revisar el flujo entero; sobra la pantalla de aceptar (`/invitation`).
- [ ] Gestión del club (`producto/gestion-club.md`): ¿se amplía el alcance? Si se cobra o factura: forma jurídica, asesor y contratos.

### Técnicas y diseño
- [ ] Reglas del backend sin cumplir (`producto/auditoria-codigo.md`, punto 8): ¿borrado lógico de eventos? ¿paginación solo en listados del superadmin?
- [ ] Diseño: ¿color de acento solo para navegación y enlaces? (`producto/diseno-revision.md`).
- [ ] Organizadores sin CIF español (NIF, NIE, extranjeros): ¿se admiten?
- [ ] Registro con el email de una cuenta borrada hace más de 30 días y aún sin purgar: el aviso ofrece cancelar el borrado y ya no se puede. ¿Callar o mensaje distinto?
- [ ] ¿Textos de error también en el servidor, o solo la app traduce por `code`?
- [ ] Aviso "tu email ha cambiado": sin canal de soporte no hay recuperación si lo cambió un atacante. Definir con el email de privacidad.
- [ ] Exportación de datos sin el `sub` de Google: confirmarlo en la revisión legal.

## 2. Pruebas a mano (Raul)
Todo está fusionado; falta comprobarlo en debug o en la Pi.
- [ ] GR-10: subir el PDF del reglamento desde el iPhone (Safari) y abrirlo (#171).
- [ ] GR-11: Ajustes con Guardar; añadir un tapiz, salir y volver (#170).
- [ ] `auth` completo: registro, login y bloqueo, verificación, recuperación, Google, perfiles, cambio de email, borrado y restaurar, exportación; admin con superadmin (`modulos/auth.md`).
- [ ] `legal-paginas`: páginas, casilla del registro, pie y ajustes.
- [ ] Grappling (G1-G5): escenario `grappling`; marcador, prórroga, puntos de clasificación y «Nuevo evento» (`producto/grappling.md`).
- [ ] Liga y fases: liga primero, podios de un toque, reinscripción, puntos por asistir (#81, #86, #89).
- [ ] Tiempo real: el marcador, el tablero, Tapices y Puntuaciones se actualizan solos.
- [ ] Offline: marcador sin red en APK y web, revisión del club (Aplicar o Descartar) con un combate en revisión, rescate por CSV.
- [ ] Pabellón: superadmin del portátil, .zip del evento, importar resultados en la Pi, permisos de «Personal» en el paquete (#133).
- [ ] Importación de alumnos: una lectura real en la Pi.
- [ ] Prototipo y F1: crear grupos con tapiz, marcador con reglas y mesa, comodines (#104, F1-2), feedback in situ, inhabilitar tapiz (#97, #105), propuestas estables (#100), advertencias en la ficha (#99), diálogos en móvil (#98).
- [ ] Datos tras la F1: M1 reglas (#107), alumno único (#109), club único (#111), sexo y peso (#112), peso obligatorio (#113), edades mezcladas (#114).
- [ ] Antes de desplegar #109 en la Pi: `select person_id from participant group by person_id having count(distinct birth_date) > 1;` vacío. Revisar los comodines de la F1 y su clasificación.
- [ ] Descargas: CSV por categoría (#108), PDF (#110), nombres de archivo (#132).
- [ ] Fase: comenzar, finalizar con pendientes, reabrir con motivo y correo del día siguiente (#129).
- [ ] Personal: dar y quitar permisos; ayudante solo de mirar, otro solo de alumnos, árbitro que hace grupos (#130, #131). Invitar a un email real con Resend (#122).
- [ ] Debug: cargar `yoseikan-f1` en una fecha simulada, copia, cambio y restaurar (#115, #117); `./deploy.sh debug` y `debug-stop` sin tocar producción.
- [ ] Banner de arranque del servidor (#128) y rediseño neutro en las pantallas de la F1.
- [ ] Campana del marcador con un iPhone en silencio.

## 3. Raul fuera del código (cuentas y servicios)
- [ ] Cloudflare: túnel y hostnames `brackety`, `brackety-api` y `brackety-admin` (con Access); rate limiting de `/api/v1/auth/*`; comprobar desde datos móviles (`09-despliegue.md`, paso 8).
- [ ] **Urgente, antes de desplegar la puerta legal**: `privacidad@rgal.dev` (Email Routing) y `PRIVACY_CONTACT_EMAIL` en `deploy/.env` y `deploy/.env.debug` de la Pi. Sin él no se puede empezar ni crear una fase (`LEGAL_GATE`).
- [ ] Resend: API key y remitente verificado en `rgal.dev`.
- [ ] Android: canal para descargar el APK; entonces la actualización obligatoria enlaza a él (`01-arquitectura.md`).
- [ ] Google Cloud: OAuth client IDs (web y Android, SHA-1 de debug y release) en `GOOGLE_CLIENT_ID`.
- [ ] Debug en la Pi: segundo túnel, Access, variables `DEBUG_*` en GitHub y `.env.debug` (`09-despliegue.md`).
- [ ] SSD para la BD (hoy en la SD) y clave age de backups guardada fuera de la Pi; copia en la nube (proveedor barato, `rclone`).
- [ ] Datos de la F1 a producción (`09-despliegue.md`) cuando estén SSD, backups y Cloudflare; elegir el email de la cuenta de la entidad.
- [ ] Anthropic: aceptar el DPA y confirmar el plazo de conservación (`modulos/importacion-alumnos.md`).
- [ ] Keystore propio para la APK (hoy firma con la clave debug).
- [ ] Antes del lanzamiento: revisión legal profesional, Google Play (12 testers × 14 días), marca "Brackety" en OEPM.
- [ ] Móvil de pruebas: autorizar la depuración USB.

## 4. Antes de cada jornada en el pabellón
- [ ] Categorías reales cargadas y `DEMO_ACCOUNTS_ENABLED=false` con datos reales.
- [ ] Portátil con BitLocker; punto de acceso con clave larga solo para el staff, sin ahorro de energía (máx. 8 dispositivos). El portátil usa el punto de acceso del iPhone y lo comparte (`modulos/servidor-local.md`).
- [ ] Móviles del staff: Android con la APK instalada; los iPhone usan la web (sin offline completo).
- [ ] Tras la jornada: borrar `brackety-data*`, el `.brackety` y las descargas del portátil.
- [ ] Sin probar aún: punto de acceso desde `start-event.ps1`, aviso UAC del firewall, arranque en un portátil limpio; reglas "java" del firewall del portátil de Raul (mantener o borrar).

## 5. Técnico, más adelante
- [ ] Fallo (Raul, 2026-11-21): quitar un árbitro sin tapiz da «tiene un tapiz asignado» (`REFEREE_ON_MAT`, `StaffService.remove`). La comprobación mira `mats.refereeAccountId`: sospecha de un tapiz inhabilitado o quitado que guarda aún el árbitro sin mostrarlo en Ajustes.
- [ ] Producción: IP real de `CF-Connecting-IP` confiando solo en el túnel; Content-Security-Policy en nginx probada contra el despliegue real.
- [ ] Emails de auth a la cola con reintentos de `notificaciones`; enlaces con token en `api.log` cuando no hay Resend.
- [ ] Retirar `staffNames` (y `event_staff_name`, M6) ahora que el personal tiene cuenta propia.
- [ ] Reparto no reproducible: con la misma entrada, los empates del reparto (tapiz libre para el bote, combate propuesto) se deciden por el orden de `HashMap<UUID, …>` (`MatFloor`, `MatPlanner`, `CategoryRoster`), que cambia con los ids. Desempatar por número de tapiz, grupo y orden del combate; cambia comportamiento, PR aparte. Hasta entonces una semilla de `EventDaySimulationTest` no repite el mismo día.
- [ ] Tapiz: al acabar un descanso la lista no se refresca sola; hay que salir y volver a entrar.
- [ ] Marcador en móvil (360 px): el texto de «Deshacer» corta el tiempo («+1 Rojo · 0…»).
- [ ] Refresh idempotente: caché en memoria, supone una sola instancia de la API.
- [ ] Register y forgot: pequeña diferencia de tiempo según exista la cuenta (aceptado por ahora).
- [ ] `opId` único por combate, no global; límite de tamaño del paquete `.brackety`; revisar CVE (Dependabot u OSV).
- [ ] Ceder o borrar un evento (módulo `eventos`): hasta entonces un dueño de eventos no puede borrar su cuenta (`OWNS_EVENTS`).
- [ ] Quitar un perfil lo borra (sin `deleted_at`): revisar cuando eventos o inscripciones lo referencien. Organizadores antiguos sin nombre ni CIF.
- [ ] Más adelante: 2FA, sesiones activas con "cerrar en todos", contraseñas filtradas, login con Apple, botón de Google en la app.
- [ ] Backup en Windows si el portátil llega a ser servidor fijo.
- [ ] Web sin conexión completa por https (la app guardada en el navegador); en http del pabellón no es posible.
- [ ] Antes de borrar `docs/` (repositorio público): pasar lo imprescindible a `CLAUDE.md` o a un README.

## 6. Reglamento Yoseikan (`reglamentos/yoseikan-2027.md`)
- [ ] Tiempo de la ronda de suelo (Raul consultando).
- [ ] Escala de cada prueba de Expresión Técnica (kata, derribos al muñeco, saco, arco).
- [ ] Puntos de asistencia por fase: 10 por ahora.
- [ ] Amonestaciones del tambo por modalidad, fase y categoría.
- [ ] Confirmar el orden de fases: F1 suelo, F2 armas, F3 expresión técnica, F4 derribos.

## 7. Por investigar
- Sambo: confirmar con su reglamento oficial qué cabe ya en `ScoringRules` (escalera de amonestaciones, victoria total, último en puntuar) y qué falta (inmovilizaciones con cronómetro). Las hojas imprimen «Sumisión» para cualquier acción de victoria.
- [ ] Otras plantillas de deporte (judo, karate, taekwondo, fútbol) al llegar a `puntuacion`.
- [ ] Doble eliminación y repesca al llegar a `torneo`.
- [ ] Previsión del día por tapiz (disputado, en curso, por disputar): duración media por categoría y hora estimada de fin de cada grupo.
- [ ] Registro de tratamientos y plantilla de registro de brechas (RGPD).
