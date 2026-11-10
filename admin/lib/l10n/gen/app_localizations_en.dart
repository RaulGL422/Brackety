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

  @override
  String get navEvents => 'Events';

  @override
  String get eventsTitle => 'Events';

  @override
  String get eventsEmpty => 'No events yet.';

  @override
  String get eventColumnName => 'Event';

  @override
  String get eventColumnDate => 'Date';

  @override
  String get eventColumnOwner => 'Organizer';

  @override
  String get eventColumnMats => 'Mats';

  @override
  String get eventColumnEntries => 'Entries';

  @override
  String get eventColumnGroups => 'Groups';

  @override
  String get eventColumnMatches => 'Matches fought';

  @override
  String eventDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String eventMatchesProgress(int finished, int total) {
    return '$finished of $total';
  }

  @override
  String eventCounts(int entries, int groups, int finished, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      entries,
      locale: localeName,
      other: '$entries entries',
      one: '1 entry',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups groups',
      one: '1 group',
    );
    return '$_temp0, $_temp1, $finished of $total matches fought';
  }

  @override
  String eventsPageOf(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get eventsPrevious => 'Previous';

  @override
  String get eventsNext => 'Next';

  @override
  String get eventBack => 'Back to the events';

  @override
  String eventEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get eventMats => 'Mats';

  @override
  String eventMatNoReferee(int number) {
    return 'Mat $number: no referee';
  }

  @override
  String eventMatReferee(int number, String referee) {
    return 'Mat $number: $referee';
  }

  @override
  String get eventGroups => 'Groups';

  @override
  String get eventNoGroups => 'No groups yet.';

  @override
  String groupTitle(int number, String category) {
    return 'Group $number, $category';
  }

  @override
  String groupMat(int number) {
    return 'Mat $number';
  }

  @override
  String matchTeam(int number) {
    return 'Team $number';
  }

  @override
  String get matchPending => 'Pending';

  @override
  String get matchInProgress => 'In progress';

  @override
  String get matchFinished => 'Finished';

  @override
  String get matchInReview => 'In review';

  @override
  String get matchReset => 'Restart';

  @override
  String matchResetTitle(int order) {
    return 'Restart match $order?';
  }

  @override
  String get matchResetBody =>
      'All its actions are deleted and it is pending again, as if it had never started. The referee sees it when their board refreshes.';

  @override
  String get matchResetDone => 'Match restarted.';

  @override
  String get groupDissolve => 'Undo group';

  @override
  String groupDissolveTitle(int number) {
    return 'Undo group $number?';
  }

  @override
  String get groupDissolveBody =>
      'The group and its matches are deleted, the fought ones too. Its members are without a group again and the helper can group them anew.';

  @override
  String groupDissolved(int number) {
    return 'Group $number undone.';
  }

  @override
  String get competitionClear => 'Clear the competition';

  @override
  String competitionClearTitle(String name) {
    return 'Clear the competition of $name?';
  }

  @override
  String get competitionClearBody =>
      'Every group, match, score and team is deleted. The settings, mats, referees and entries stay. It cannot be undone.';

  @override
  String competitionCleared(int groups, int teams) {
    String _temp0 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups groups',
      one: '1 group',
    );
    String _temp1 = intl.Intl.pluralLogic(
      teams,
      locale: localeName,
      other: '$teams teams',
      one: '1 team',
    );
    return 'Competition cleared: $_temp0 and $_temp1 deleted.';
  }

  @override
  String get reasonLabel => 'Reason';

  @override
  String get reasonHelper => 'It is kept in the audit.';

  @override
  String typeToConfirm(String name) {
    return 'Type \"$name\" to confirm';
  }

  @override
  String get eventChanged =>
      'The event changed meanwhile; it has been reloaded.';
}
