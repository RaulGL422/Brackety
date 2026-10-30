// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Brackety';

  @override
  String get navConnection => 'Connection';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get loadError => 'Could not load. Check the connection.';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginUsername => 'Username';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginInvalid => 'Wrong username or password.';

  @override
  String get loginLocked => 'Too many attempts. Wait a few minutes.';

  @override
  String get loginNoServer => 'Cannot reach the server.';

  @override
  String get loginDemoAccounts => 'Test accounts (development only)';

  @override
  String get logout => 'Sign out';

  @override
  String get eventsTitle => 'My events';

  @override
  String get eventsEmpty => 'You have no events assigned.';

  @override
  String get roleClub => 'Club';

  @override
  String get roleGrouper => 'Helper';

  @override
  String get roleReferee => 'Referee';

  @override
  String get eventMakeGroups => 'Make groups';

  @override
  String eventMyMat(int number) {
    return 'Mat $number';
  }

  @override
  String get eventClubPanel => 'Club panel';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesEmpty => 'No registrations yet.';

  @override
  String categoryCounts(int participants, int grouped) {
    return '$participants registered · $grouped in groups';
  }

  @override
  String categoryAges(String name) {
    return 'Ages $name';
  }

  @override
  String get sortByName => 'Name';

  @override
  String get sortByHeight => 'Height';

  @override
  String participantDetails(int age, String height) {
    return '$age years · $height';
  }

  @override
  String heightCm(int cm) {
    return '$cm cm';
  }

  @override
  String get heightUnknown => 'no height';

  @override
  String participantGrouped(int group, int mat) {
    return 'Group $group · Mat $mat';
  }

  @override
  String draftGroup(int number) {
    return 'Group $number';
  }

  @override
  String draftCount(int count) {
    return '$count/4';
  }

  @override
  String get draftGhost => 'Ghost competitor';

  @override
  String get draftGhostHint => 'Pick the ghost: fights but does not score.';

  @override
  String get draftAddGroup => 'Add group';

  @override
  String get draftRemoveGroup => 'Remove group';

  @override
  String createGroup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Create groups',
      one: 'Create group',
    );
    return '$_temp0';
  }

  @override
  String groupsCreatedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Groups created',
      one: 'Group created',
    );
    return '$_temp0';
  }

  @override
  String groupsCreatedBody(String groups, int mat) {
    return '$groups → Mat $mat';
  }

  @override
  String get groupsConflict =>
      'A participant is already in a group. The list has been refreshed.';

  @override
  String get groupsError => 'The groups could not be created.';

  @override
  String get ok => 'OK';

  @override
  String get ghostBadge => 'Ghost';
}
