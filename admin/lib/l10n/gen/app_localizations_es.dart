// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Brackety Admin';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navConnection => 'Conexión';

  @override
  String get dashboardTitle => 'Panel de superadmin';

  @override
  String get dashboardSubtitle => 'Gestión global de la plataforma.';

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
}
