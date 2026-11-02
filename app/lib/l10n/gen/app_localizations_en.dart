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

  @override
  String matTitle(int number) {
    return 'Mat $number';
  }

  @override
  String get matEmpty => 'No groups on this mat yet.';

  @override
  String matGroupHeader(int number, String category) {
    return 'Group $number · ages $category';
  }

  @override
  String get matRecommended => 'Recommended next';

  @override
  String get matInProgress => 'In progress';

  @override
  String get matPending => 'Pending';

  @override
  String get matFinished => 'Finished';

  @override
  String get matWaiting => 'A fighter is in a match on another mat';

  @override
  String get matNoneAvailable => 'No match can start right now.';

  @override
  String get versus => 'vs';

  @override
  String scoreboardTitle(int mat, int group) {
    return 'Mat $mat · Group $group';
  }

  @override
  String get cornerRed => 'Red';

  @override
  String get cornerBlue => 'Blue';

  @override
  String get clockStart => 'Start';

  @override
  String get clockStop => 'Stop';

  @override
  String get clockResume => 'Resume';

  @override
  String get finishMatch => 'Finish match';

  @override
  String get matchFinished => 'Match finished';

  @override
  String get backToMat => 'Back to the mat';

  @override
  String get undo => 'Undo';

  @override
  String get timeline => 'Timeline';

  @override
  String get addPoint => '+1';

  @override
  String warningsCount(int count) {
    return 'Warnings: $count';
  }

  @override
  String oneHandCount(int count) {
    return 'One hand: $count';
  }

  @override
  String get disqualified => 'Disqualified';

  @override
  String get actionWarning => 'Warning';

  @override
  String get actionOneHand => 'Warning for hitting with one hand';

  @override
  String get actionDisqualify => 'Disqualification';

  @override
  String reasonTitle(String action, String fighter) {
    return '$action · $fighter';
  }

  @override
  String get reasonLabel => 'Reason (required)';

  @override
  String get reasonConfirm => 'Sure? It is recorded.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get endPoints => 'Ended on points';

  @override
  String get endTime => 'Time is up';

  @override
  String get endDisqualification => 'Ended by disqualification';

  @override
  String actionRefused(String detail) {
    return 'Could not record it. $detail';
  }

  @override
  String get tlStart => 'Clock started';

  @override
  String get tlStop => 'Stop';

  @override
  String get tlPoint => 'Point';

  @override
  String get tlUndo => 'Undo';

  @override
  String get tlFinish => 'Match finished';

  @override
  String get tlAutomatic => 'automatic';

  @override
  String get tlUndone => 'undone';

  @override
  String get tlRivalPoint => 'point to the rival';

  @override
  String get clubStandings => 'Scores';

  @override
  String get clubMats => 'Mats';

  @override
  String get clubParticipants => 'Entries';

  @override
  String get clubSettings => 'Settings';

  @override
  String get allCategories => 'All categories';

  @override
  String get noCategory => 'No category';

  @override
  String get sortByPoints => 'Points';

  @override
  String get standingsEmpty => 'No scores yet.';

  @override
  String standingsTotal(int total) {
    return '$total pts';
  }

  @override
  String standingsDetail(int attendance, int points, int matches) {
    return 'Attendance $attendance · Matches $points ($matches)';
  }

  @override
  String get matsEmpty => 'No mats.';

  @override
  String matSummary(int groups, int pending) {
    return '$groups groups · $pending pending matches';
  }

  @override
  String get matNoReferee => 'No referee';

  @override
  String matEstimatedEnd(String time) {
    return 'Estimated end $time';
  }

  @override
  String get matFighting => 'Match in progress';

  @override
  String get matIdle => 'Idle';

  @override
  String get participantAdd => 'Add student';

  @override
  String get participantEdit => 'Edit student';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get heightOptional => 'Height in cm (optional)';

  @override
  String get heightInvalid => 'Between 50 and 250 cm';

  @override
  String get guardianConsent => 'The legal guardian agrees';

  @override
  String get guardianConsentRequired => 'Required for under-18s.';

  @override
  String get fieldRequired => 'Required';

  @override
  String participantAgeCategory(int age, String category) {
    return '$age years · $category';
  }

  @override
  String deleteParticipantTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get saved => 'Saved';

  @override
  String get saveConflict =>
      'Not possible: there are groups that depend on it.';

  @override
  String get saveInvalid => 'Check the data.';

  @override
  String get saveError => 'Could not save.';

  @override
  String get settingsName => 'Event name';

  @override
  String get settingsDate => 'Date';

  @override
  String get settingsMaxGroups => 'Groups per mat at once';

  @override
  String get settingsMaxGroupsHint => '1 = no multigroup';

  @override
  String get settingsAddMat => 'Add mat';

  @override
  String get settingsRemoveMat => 'Remove the last mat';

  @override
  String get settingsReferee => 'Referee';

  @override
  String categoryRange(String name, int min, int max) {
    return '$name · $min to $max years';
  }

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportStandings => 'Standings';

  @override
  String get exportMatches => 'Matches';

  @override
  String get exportTimeline => 'Timeline';

  @override
  String get exportError => 'Could not export.';

  @override
  String get matchLive => 'In progress';

  @override
  String get matchNotStarted => 'Not started';
}
