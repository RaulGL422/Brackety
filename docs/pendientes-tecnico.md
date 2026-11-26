# Pendientes técnicos

Lo técnico que espera, sin fecha. Parte de `pendientes.md` (sección 5). Lo hecho se borra.

- [ ] Fallo (Raul, 2026-11-21): quitar un árbitro sin tapiz da «tiene un tapiz asignado» (`REFEREE_ON_MAT`, `StaffService.remove`). La comprobación mira `mats.refereeAccountId`: sospecha de un tapiz inhabilitado o quitado que guarda aún el árbitro sin mostrarlo en Ajustes.
- [ ] Producción: IP real de `CF-Connecting-IP` confiando solo en el túnel; Content-Security-Policy en nginx probada contra el despliegue real.
- [ ] Emails de auth a la cola con reintentos de `notificaciones`; enlaces con token en `api.log` cuando no hay Resend.
- [ ] Retirar `staffNames` (y `event_staff_name`, M6) ahora que el personal tiene cuenta propia.
- [ ] Reparto no reproducible: con la misma entrada, los empates del reparto (tapiz libre para el bote, combate propuesto) se deciden por el orden de `HashMap<UUID, …>` (`MatFloor`, `MatPlanner`, `CategoryRoster`), que cambia con los ids. Desempatar por número de tapiz, grupo y orden del combate; cambia comportamiento, PR aparte. Hasta entonces una semilla de `EventDaySimulationTest` no repite el mismo día.
- [ ] Mis eventos con texto al 200 % en un móvil: la barra superior desborda 45 px (la vio el test de accesibilidad de las pantallas sin sesión, 2026-11-26).
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
