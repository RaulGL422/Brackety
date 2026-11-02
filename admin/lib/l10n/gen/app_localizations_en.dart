// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Brackety Admin';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navConnection => 'Connection';

  @override
  String get dashboardTitle => 'Superadmin dashboard';

  @override
  String get dashboardSubtitle => 'Platform-wide management.';

  @override
  String get navDesignSystem => 'Design';

  @override
  String get dsTitle => 'Design system';

  @override
  String get dsIntro =>
      'Debug builds only. Everything below uses the real theme in the chosen mode.';

  @override
  String get dsModeLight => 'Light';

  @override
  String get dsModeDark => 'Dark';

  @override
  String dsTextScale(int percent) {
    return 'Text at $percent %';
  }

  @override
  String get dsColors => 'Colors';

  @override
  String get dsStatusColors => 'Status';

  @override
  String get dsCompetitorColors => 'Competitor colors';

  @override
  String get dsContrastHint =>
      'AA: normal text (≥ 4.5). AA large: large text only (≥ 3). ✗: not for text.';

  @override
  String get dsContrastLarge => 'AA large';

  @override
  String get dsTypography => 'Typography';

  @override
  String get dsTypeSample => 'Sample league 2027 · 0123456789';

  @override
  String get dsSpacing => 'Spacing';

  @override
  String get dsRadius => 'Radius';

  @override
  String get dsComponents => 'Components';

  @override
  String get dsSave => 'Save';

  @override
  String get dsTonal => 'Sign up';

  @override
  String get dsCancel => 'Cancel';

  @override
  String get dsMore => 'See more';

  @override
  String get dsDisabled => 'Disabled';

  @override
  String get dsFieldLabel => 'Club name';

  @override
  String get dsFieldHint => 'Sample Sports Club';

  @override
  String get dsFieldError => 'Required field';

  @override
  String get dsNotifications => 'Notifications';

  @override
  String get dsCategoryKids => 'Kids';

  @override
  String get dsCategoryCadet => 'Cadet';

  @override
  String get dsCategorySenior => 'Senior';

  @override
  String get dsCardTitle => 'Sample league 2027';

  @override
  String get dsCardSubtitle => '3 phases · 120 entries';

  @override
  String get dsPaid => 'Paid';

  @override
  String get dsPending => 'Pending';

  @override
  String get dsRejected => 'Rejected';

  @override
  String get dsSamples => 'Samples';

  @override
  String get dsScoreboard => 'Scoreboard';

  @override
  String get dsColorA => 'Color A';

  @override
  String get dsColorB => 'Color B';

  @override
  String dsPenalties(int count) {
    return 'Penalties: $count';
  }

  @override
  String get dsStandings => 'Standings';

  @override
  String get dsPosition => 'Pos.';

  @override
  String get dsCompetitor => 'Competitor';

  @override
  String get dsWins => 'W';

  @override
  String get dsLosses => 'L';

  @override
  String get dsPoints => 'Pts';

  @override
  String get navLocks => 'Locks';

  @override
  String get navOrganizers => 'Organizers';

  @override
  String get logout => 'Sign out';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get loadError => 'Could not load the data.';

  @override
  String get noServer => 'Cannot reach the server.';

  @override
  String get unexpectedError => 'Something went wrong. Try again.';

  @override
  String get adminNotConfigured =>
      'Superadmin access is not configured on this server.';

  @override
  String get adminAccessDenied =>
      'Access denied: the admin only works through its protected host (Cloudflare Access).';

  @override
  String tooManyRequests(int seconds) {
    return 'Too many requests. Wait $seconds s and try again.';
  }

  @override
  String get tooManyRequestsWait =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get loginTitle => 'Superadmin sign-in';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get fieldRequired => 'Required field';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginInvalid => 'Wrong email or password.';

  @override
  String loginLocked(String lockId) {
    return 'Too many failed attempts: access locked for 15 minutes (lock $lockId).';
  }

  @override
  String get sessionExpired => 'Your session has expired. Sign in again.';

  @override
  String get locksTitle => 'Active locks';

  @override
  String get locksEmpty => 'No active locks.';

  @override
  String get lockColumnId => 'Lock';

  @override
  String get lockColumnType => 'Type';

  @override
  String get lockColumnWho => 'Who';

  @override
  String get lockColumnTimeLeft => 'Time left';

  @override
  String get lockTypeEmail => 'Email';

  @override
  String get lockTypeIp => 'IP';

  @override
  String get lockTypeAdmin => 'Superadmin';

  @override
  String get lockUnknownEmail => 'Email without account';

  @override
  String lockMinutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min left',
      one: '1 min left',
    );
    return '$_temp0';
  }

  @override
  String lockUntil(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'until $timeString';
  }

  @override
  String get lockExpired => 'Expired';

  @override
  String get lockRevoke => 'Revoke';

  @override
  String lockRevokeTitle(String lockId) {
    return 'Revoke lock $lockId?';
  }

  @override
  String get lockRevokeBody =>
      'Its failed attempts are cleared and signing in works again right away.';

  @override
  String lockRevoked(String lockId) {
    return 'Lock $lockId revoked.';
  }

  @override
  String get lockAlreadyExpired =>
      'That lock had already expired. List refreshed.';

  @override
  String get organizersTitle => 'Organizers';

  @override
  String get organizerFilterPending => 'Pending';

  @override
  String get organizerFilterValidated => 'Validated';

  @override
  String get organizerFilterAll => 'All';

  @override
  String get organizersEmptyPending => 'No organizers waiting for validation.';

  @override
  String get organizersEmpty => 'No organizers.';

  @override
  String get organizerColumnName => 'Organization';

  @override
  String get organizerColumnTaxId => 'CIF';

  @override
  String get organizerColumnType => 'Type';

  @override
  String get organizerColumnEmail => 'Email';

  @override
  String get organizerColumnCreated => 'Joined';

  @override
  String get organizerColumnState => 'State';

  @override
  String get organizerNoData => 'No data';

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

    return 'Joined: $dateString';
  }

  @override
  String get organizerClub => 'Club';

  @override
  String get organizerExternalEntity => 'External entity';

  @override
  String get organizerPending => 'Pending';

  @override
  String get organizerValidated => 'Validated';

  @override
  String get organizerValidate => 'Validate';

  @override
  String organizerValidateTitle(String name) {
    return 'Validate $name?';
  }

  @override
  String get organizerValidateBody =>
      'They will be able to publish events. The first time they are validated, they get an email telling them.';

  @override
  String organizerValidatedDone(String name) {
    return '$name validated.';
  }

  @override
  String get organizerNotFound =>
      'That organizer no longer exists or is no longer an organizer. List refreshed.';
}
