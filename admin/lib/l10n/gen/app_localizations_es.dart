// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get eventReset => 'Reiniciar el evento desde el paquete';

  @override
  String get eventResetTitle => '¿Reiniciar el evento?';

  @override
  String eventResetBody(String package, String word) {
    return 'Se borra todo lo hecho (grupos, equipos, combates, puntuaciones, cambios de configuración e inscritos añadidos) y se vuelve a cargar $package. Las cuentas y contraseñas se mantienen. Todos tendrán que recargar la página. No se puede deshacer: escribe $word para confirmar.';
  }

  @override
  String get eventResetDone => 'Evento reiniciado desde el paquete.';

  @override
  String get controlSave => 'Guardar';

  @override
  String get controlMenu => 'Cambiar';

  @override
  String get controlDone => 'Hecho';

  @override
  String get controlMatchInProgress =>
      'Hay un combate de este grupo en curso: espera a que acabe.';

  @override
  String get controlMatchNotPending =>
      'Ese combate ya ha empezado: no se puede cambiar.';

  @override
  String get controlMatWithoutReferee => 'Ese tapiz no tiene árbitro.';

  @override
  String get controlOrderChanged =>
      'Los combates han cambiado mientras tanto: recarga y vuelve a ordenarlos.';

  @override
  String get controlTeamSize => 'Los equipos tienen que quedar de 2 o 3.';

  @override
  String get controlGroupStarted =>
      'El grupo de esos equipos ya ha empezado: sus equipos ya no cambian.';

  @override
  String get controlSameFighter =>
      'Esa persona ya lucha en el grupo del otro equipo (como comodín).';

  @override
  String get controlMatInReview =>
      'Un combate de este tapiz espera revisión: resuélvela antes.';

  @override
  String get controlDisableMat => 'Inhabilitar tapiz';

  @override
  String controlDisableMatTitle(int number) {
    return '¿Inhabilitar el tapiz $number?';
  }

  @override
  String get controlDisableMatBody =>
      'Elige a qué tapiz va cada grupo con combates pendientes (Automático: el que acabe antes). Los combates de equipos se reparten entre los demás tapices. Se queda sin árbitro: para volver a usarlo, el club le asigna uno en Configuración.';

  @override
  String get controlMatAutomatic => 'Automático';

  @override
  String get controlPickMat => '¿A qué tapiz?';

  @override
  String get controlNoOtherMat => 'No hay otro tapiz con árbitro.';

  @override
  String controlMatOption(int number, String referee, int pending) {
    String _temp0 = intl.Intl.pluralLogic(
      pending,
      locale: localeName,
      other: '$pending pendientes',
      one: '1 pendiente',
      zero: 'sin combates pendientes',
    );
    return 'Tapiz $number · $referee · $_temp0';
  }

  @override
  String get controlMoveMatch => 'Mover este combate a otro tapiz';

  @override
  String get controlWaiveRest => 'Dejar empezar sin esperar el descanso';

  @override
  String get controlWaiveRestTitle => '¿Empezar sin el descanso mínimo?';

  @override
  String controlWaiveRestBody(String red, String blue) {
    return '$red contra $blue podrá empezar aunque alguien no haya descansado. Queda registrado.';
  }

  @override
  String get controlConfirm => 'Sí, permitir';

  @override
  String get controlMoveGroup => 'Mover el grupo a otro tapiz';

  @override
  String get controlReorder => 'Cambiar el orden';

  @override
  String get controlReorderHint =>
      'Arrastra para ordenar los combates pendientes. Los jugados no cambian.';

  @override
  String get controlTeams => 'Equipos';

  @override
  String controlTeamTitle(int number, String category) {
    return 'Equipo $number · $category';
  }

  @override
  String controlTeamInGroup(int number) {
    return 'en el grupo $number, sin empezar';
  }

  @override
  String controlTeamGroupStarted(int number) {
    return 'grupo $number empezado: ya no cambia';
  }

  @override
  String get controlMoveMember => 'Mover un alumno a otro equipo';

  @override
  String get controlMoveMemberWho => '¿Quién se cambia?';

  @override
  String get controlMoveMemberTo => '¿A qué equipo?';

  @override
  String get appTitle => 'Brackety Admin';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navConnection => 'Conexión';

  @override
  String get dashboardTitle => 'Panel de superadmin';

  @override
  String get navDesignSystem => 'Diseño';

  @override
  String get dsTitle => 'Sistema de diseño';

  @override
  String get dsIntro =>
      'Solo en builds debug. Todo lo de abajo usa el tema real en el modo elegido.';

  @override
  String get dsModeLight => 'Claro';

  @override
  String get dsModeDark => 'Oscuro';

  @override
  String dsTextScale(int percent) {
    return 'Texto al $percent %';
  }

  @override
  String get dsColors => 'Colores';

  @override
  String get dsStatusColors => 'Estados';

  @override
  String get dsCompetitorColors => 'Colores de competidor';

  @override
  String get dsContrastHint =>
      'AA: texto normal (≥ 4,5). AA grande: solo texto grande (≥ 3). ✗: no usar para texto.';

  @override
  String get dsContrastLarge => 'AA grande';

  @override
  String get dsTypography => 'Tipografía';

  @override
  String get dsTypeSample => 'Liga de ejemplo 2027 · 0123456789';

  @override
  String get dsSpacing => 'Espaciado';

  @override
  String get dsRadius => 'Radios';

  @override
  String get dsComponents => 'Componentes';

  @override
  String get dsSave => 'Guardar';

  @override
  String get dsTonal => 'Inscribirse';

  @override
  String get dsCancel => 'Cancelar';

  @override
  String get dsMore => 'Ver más';

  @override
  String get dsDisabled => 'Desactivado';

  @override
  String get dsFieldLabel => 'Nombre del club';

  @override
  String get dsFieldHint => 'Club Deportivo Ejemplo';

  @override
  String get dsFieldError => 'Campo obligatorio';

  @override
  String get dsNotifications => 'Notificaciones';

  @override
  String get dsCategoryKids => 'Infantil';

  @override
  String get dsCategoryCadet => 'Cadete';

  @override
  String get dsCategorySenior => 'Sénior';

  @override
  String get dsCardTitle => 'Liga de ejemplo 2027';

  @override
  String get dsCardSubtitle => '3 fases · 120 inscritos';

  @override
  String get dsPaid => 'Pagado';

  @override
  String get dsPending => 'Pendiente';

  @override
  String get dsRejected => 'Rechazado';

  @override
  String get dsSamples => 'Ejemplos';

  @override
  String get dsScoreboard => 'Marcador';

  @override
  String get dsColorA => 'Color A';

  @override
  String get dsColorB => 'Color B';

  @override
  String dsPenalties(int count) {
    return 'Amonestaciones: $count';
  }

  @override
  String get dsStandings => 'Clasificación';

  @override
  String get dsPosition => 'Pos.';

  @override
  String get dsCompetitor => 'Competidor';

  @override
  String get dsWins => 'V';

  @override
  String get dsLosses => 'D';

  @override
  String get dsPoints => 'Pts';

  @override
  String get navLocks => 'Bloqueos';

  @override
  String get navOrganizers => 'Organizadores';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get cancel => 'Cancelar';

  @override
  String get retry => 'Reintentar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get loadError => 'No se han podido cargar los datos.';

  @override
  String get noServer => 'No se puede conectar con el servidor.';

  @override
  String get unexpectedError => 'Algo ha fallado. Inténtalo de nuevo.';

  @override
  String get adminNotConfigured =>
      'El acceso de superadmin no está configurado en este servidor.';

  @override
  String get adminAccessDenied =>
      'Acceso denegado: la administración solo funciona desde su dominio protegido (Cloudflare Access).';

  @override
  String tooManyRequests(int seconds) {
    return 'Demasiadas peticiones. Espera $seconds s y vuelve a intentarlo.';
  }

  @override
  String get tooManyRequestsWait =>
      'Demasiadas peticiones. Espera un momento y vuelve a intentarlo.';

  @override
  String get loginTitle => 'Acceso de superadmin';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get fieldRequired => 'Campo obligatorio';

  @override
  String get loginSubmit => 'Entrar';

  @override
  String get loginInvalid => 'Email o contraseña incorrectos.';

  @override
  String loginLocked(String lockId) {
    return 'Demasiados intentos fallidos: acceso bloqueado 15 minutos (bloqueo $lockId).';
  }

  @override
  String get sessionExpired => 'Tu sesión ha caducado. Vuelve a entrar.';

  @override
  String get locksTitle => 'Bloqueos activos';

  @override
  String get locksEmpty => 'No hay bloqueos activos.';

  @override
  String get lockColumnId => 'Bloqueo';

  @override
  String get lockColumnType => 'Tipo';

  @override
  String get lockColumnWho => 'Quién';

  @override
  String get lockColumnTimeLeft => 'Tiempo restante';

  @override
  String get lockTypeEmail => 'Email';

  @override
  String get lockTypeIp => 'IP';

  @override
  String get lockTypeAdmin => 'Superadmin';

  @override
  String get lockUnknownEmail => 'Email sin cuenta';

  @override
  String lockMinutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Quedan $minutes min',
      one: 'Queda 1 min',
    );
    return '$_temp0';
  }

  @override
  String lockUntil(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'hasta las $timeString';
  }

  @override
  String get lockExpired => 'Caducado';

  @override
  String get lockRevoke => 'Revocar';

  @override
  String lockRevokeTitle(String lockId) {
    return '¿Revocar el bloqueo $lockId?';
  }

  @override
  String get lockRevokeBody =>
      'Se borran sus intentos fallidos y se podrá volver a entrar al momento.';

  @override
  String lockRevoked(String lockId) {
    return 'Bloqueo $lockId revocado.';
  }

  @override
  String get lockAlreadyExpired =>
      'Ese bloqueo ya había caducado. Lista actualizada.';

  @override
  String get organizersTitle => 'Organizadores';

  @override
  String get organizerFilterPending => 'Pendientes';

  @override
  String get organizerFilterValidated => 'Validados';

  @override
  String get organizerFilterAll => 'Todos';

  @override
  String get organizersEmptyPending =>
      'No hay organizadores pendientes de validar.';

  @override
  String get organizersEmpty => 'No hay organizadores.';

  @override
  String get organizerColumnName => 'Organización';

  @override
  String get organizerColumnTaxId => 'CIF';

  @override
  String get organizerColumnType => 'Tipo';

  @override
  String get organizerColumnEmail => 'Email';

  @override
  String get organizerColumnCreated => 'Alta';

  @override
  String get organizerColumnState => 'Estado';

  @override
  String get organizerNoData => 'Sin datos';

  @override
  String get organizerNoTaxId => '—';

  @override
  String organizerTaxId(String taxId) {
    return 'CIF: $taxId';
  }

  @override
  String organizerDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String organizerCreated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Alta: $dateString';
  }

  @override
  String get organizerClub => 'Club';

  @override
  String get organizerExternalEntity => 'Entidad externa';

  @override
  String get organizerPending => 'Pendiente';

  @override
  String get organizerValidated => 'Validado';

  @override
  String get organizerValidate => 'Validar';

  @override
  String organizerValidateTitle(String name) {
    return '¿Validar $name?';
  }

  @override
  String get organizerValidateBody =>
      'Podrá publicar eventos. Si es la primera vez que se valida, recibirá un email avisándole.';

  @override
  String organizerValidatedDone(String name) {
    return '$name validado.';
  }

  @override
  String get organizerNotFound =>
      'Ese organizador ya no existe o ya no es organizador. Lista actualizada.';

  @override
  String get navEvents => 'Eventos';

  @override
  String get eventsTitle => 'Eventos';

  @override
  String get eventsEmpty => 'Todavía no hay eventos.';

  @override
  String get eventColumnName => 'Evento';

  @override
  String get eventColumnDate => 'Fecha';

  @override
  String get eventColumnOwner => 'Organizador';

  @override
  String get eventColumnMats => 'Tapices';

  @override
  String get eventColumnEntries => 'Inscritos';

  @override
  String get eventColumnGroups => 'Grupos';

  @override
  String get eventColumnMatches => 'Combates disputados';

  @override
  String eventDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String eventMatchesProgress(int finished, int total) {
    return '$finished de $total';
  }

  @override
  String eventCounts(int entries, int groups, int finished, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      entries,
      locale: localeName,
      other: '$entries inscritos',
      one: '1 inscrito',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups grupos',
      one: '1 grupo',
    );
    return '$_temp0, $_temp1, $finished de $total combates disputados';
  }

  @override
  String eventsPageOf(int page, int pages) {
    return 'Página $page de $pages';
  }

  @override
  String get eventsPrevious => 'Anterior';

  @override
  String get eventsNext => 'Siguiente';

  @override
  String get eventBack => 'Volver a los eventos';

  @override
  String eventEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inscritos',
      one: '1 inscrito',
    );
    return '$_temp0';
  }

  @override
  String get eventMats => 'Tapices';

  @override
  String eventMatNoReferee(int number) {
    return 'Tapiz $number: sin árbitro';
  }

  @override
  String eventMatReferee(int number, String referee) {
    return 'Tapiz $number: $referee';
  }

  @override
  String get eventGroups => 'Grupos';

  @override
  String get eventNoGroups => 'Todavía no hay grupos.';

  @override
  String groupTitle(int number, String category) {
    return 'Grupo $number, $category';
  }

  @override
  String groupMat(int number) {
    return 'Tapiz $number';
  }

  @override
  String get groupPool => 'Equipos: tapices libres';

  @override
  String matchTeam(int number) {
    return 'Equipo $number';
  }

  @override
  String get matchPending => 'Pendiente';

  @override
  String get matchInProgress => 'En curso';

  @override
  String get matchFinished => 'Terminado';

  @override
  String get matchInReview => 'En revisión';

  @override
  String get matchReset => 'Reiniciar';

  @override
  String matchResetTitle(int order) {
    return '¿Reiniciar el combate $order?';
  }

  @override
  String get matchResetBody =>
      'Se borran todas sus acciones y vuelve a estar pendiente, como si no hubiera empezado. El árbitro lo verá al actualizarse su tablero.';

  @override
  String get matchResetDone => 'Combate reiniciado.';

  @override
  String get groupDissolve => 'Deshacer grupo';

  @override
  String groupDissolveTitle(int number) {
    return '¿Deshacer el grupo $number?';
  }

  @override
  String get groupDissolveBody =>
      'Se borran el grupo y sus combates, también los ya disputados. Sus alumnos vuelven a estar sin grupo y el ayudante puede agruparlos otra vez.';

  @override
  String groupDissolved(int number) {
    return 'Grupo $number deshecho.';
  }

  @override
  String get competitionClear => 'Vaciar la competición';

  @override
  String competitionClearTitle(String name) {
    return '¿Vaciar la competición de $name?';
  }

  @override
  String get competitionClearBody =>
      'Se borran todos los grupos, combates, puntuaciones y equipos. Se conservan la configuración, los tapices, los árbitros y los inscritos. No se puede deshacer.';

  @override
  String competitionCleared(int groups, int teams) {
    String _temp0 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups grupos',
      one: '1 grupo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      teams,
      locale: localeName,
      other: '$teams equipos',
      one: '1 equipo',
    );
    return 'Competición vaciada: $_temp0 y $_temp1 borrados.';
  }

  @override
  String get reasonLabel => 'Motivo';

  @override
  String get reasonHelper => 'Queda guardado en la auditoría.';

  @override
  String typeToConfirm(String name) {
    return 'Escribe «$name» para confirmar';
  }

  @override
  String get eventChanged =>
      'El evento ha cambiado mientras tanto; se ha recargado.';

  @override
  String metricsAt(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Datos de las $timeString';
  }

  @override
  String get metricsUsers => 'Usuarios';

  @override
  String get metricsActiveAccounts => 'Cuentas activas';

  @override
  String get metricsNewLast7Days => 'Altas en 7 días';

  @override
  String get metricsUnverified => 'Sin verificar el email';

  @override
  String get metricsPendingDeletion => 'Pendientes de borrado';

  @override
  String get metricsOrganizersPending => 'Organizadores por validar';

  @override
  String get metricsActiveSessions => 'Sesiones abiertas';

  @override
  String get metricsActiveLocks => 'Bloqueos activos';

  @override
  String get metricsProfiles => 'Perfiles';

  @override
  String get metricsClubs => 'Clubes';

  @override
  String get metricsEntities => 'Entidades externas';

  @override
  String get metricsHelpers => 'Ayudantes';

  @override
  String get metricsStudents => 'Alumnos';

  @override
  String get metricsExternals => 'Externos';

  @override
  String get metricsEvents => 'Eventos';

  @override
  String get metricsEventsTotal => 'Eventos';

  @override
  String get metricsUpcoming => 'Hoy o más adelante';

  @override
  String get metricsEntries => 'Inscritos';

  @override
  String get metricsImports => 'Importaciones en 7 días';

  @override
  String get metricsImported => 'Importados en 7 días';

  @override
  String get metricsActivity => 'Actividad';

  @override
  String get metricsMatchesFinished => 'Combates terminados en 24 h';

  @override
  String get metricsScoreboardActions => 'Acciones del marcador en 24 h';

  @override
  String get metricsGroupsCreated => 'Grupos creados en 24 h';

  @override
  String get metricsInProgress => 'Combates en curso ahora';

  @override
  String get metricsInReview => 'Combates en revisión';

  @override
  String get metricsInReviewNote => 'El club tiene que revisarlos';

  @override
  String get metricsServer => 'Servidor';

  @override
  String get metricsServerErrors => 'Errores 5xx de la API';

  @override
  String metricsSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Desde el arranque: $dateString';
  }

  @override
  String get metricsServerErrorsNote => 'Mira los logs de la API';

  @override
  String get navUsers => 'Usuarios';

  @override
  String get usersTitle => 'Usuarios';

  @override
  String get usersSearch => 'Buscar por email u organización';

  @override
  String get usersEmpty => 'Ninguna cuenta coincide.';

  @override
  String get userColumnEmail => 'Email';

  @override
  String get userColumnOrganization => 'Organización';

  @override
  String get userColumnProfiles => 'Perfiles';

  @override
  String get userColumnCreated => 'Alta';

  @override
  String get userColumnState => 'Estado';

  @override
  String get userProfileClub => 'Club';

  @override
  String get userProfileEntity => 'Entidad externa';

  @override
  String get userProfileHelper => 'Ayudante';

  @override
  String get userProfileStudent => 'Alumno';

  @override
  String get userProfileExternal => 'Externo';

  @override
  String get userStateActive => 'Activa';

  @override
  String get userStateUnverified => 'Sin verificar el email';

  @override
  String get userStateSuspended => 'Suspendida';

  @override
  String get userStateDeleted => 'Borrada, pendiente de purga';

  @override
  String userDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get userBack => 'Volver a los usuarios';

  @override
  String get userSignInMethods => 'Acceso';

  @override
  String get userPassword => 'Contraseña';

  @override
  String get userLastSignIn => 'Última sesión';

  @override
  String get userNever => 'Nunca';

  @override
  String get userOwnedEvents => 'Eventos propios';

  @override
  String get userStaffEvents => 'Eventos donde ayuda';

  @override
  String get userSuspendedSince => 'Suspendida desde';

  @override
  String get userDeletesOn => 'Se borra del todo el';

  @override
  String get userSuspend => 'Suspender';

  @override
  String userSuspendTitle(String email) {
    return '¿Suspender $email?';
  }

  @override
  String get userSuspendBody =>
      'Se cierran todas sus sesiones al momento y no podrá entrar hasta que levantes la suspensión. Sus datos y sus eventos se conservan.';

  @override
  String get userSuspended => 'Cuenta suspendida.';

  @override
  String get userUnsuspend => 'Levantar la suspensión';

  @override
  String userUnsuspendTitle(String email) {
    return '¿Levantar la suspensión de $email?';
  }

  @override
  String get userUnsuspendBody =>
      'Podrá volver a entrar con sus datos de siempre.';

  @override
  String get userUnsuspended => 'Suspensión levantada.';

  @override
  String get userDelete => 'Borrar la cuenta';

  @override
  String userDeleteTitle(String email) {
    return '¿Borrar la cuenta $email?';
  }

  @override
  String get userDeleteBody =>
      'Es el mismo borrado que pide el usuario: se cierra su sesión, le llega un email y se borra del todo a los 30 días. Hasta entonces puede recuperarla entrando. Una cuenta dueña de eventos no se puede borrar.';

  @override
  String userDeleted(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Cuenta borrada. Se borra del todo el $dateString.';
  }

  @override
  String get userOwnsEvents =>
      'Esta cuenta es dueña de eventos: hay que traspasarlos o borrarlos antes.';

  @override
  String get userChanged =>
      'La cuenta ha cambiado mientras tanto; se ha recargado.';

  @override
  String teamWithMembers(int number, String members) {
    return 'Equipo $number ($members)';
  }

  @override
  String ghostName(String name) {
    return '$name · comodín';
  }

  @override
  String get planEmpty => 'Nada pendiente';

  @override
  String planSummary(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count combates pendientes, el primero a las $time',
      one: '1 combate pendiente, empieza a las $time',
    );
    return '$_temp0';
  }

  @override
  String get planHint =>
      'Orden previsto de los combates recomendados si todo va según lo previsto (cada combate con su tiempo entero y el cambio). Las horas son estimadas.';

  @override
  String groupCreatedBy(String name) {
    return 'Hecho por $name';
  }
}
