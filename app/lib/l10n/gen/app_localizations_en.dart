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
  String get noServer => 'Cannot reach the server.';

  @override
  String get unexpectedError => 'Something went wrong. Try again.';

  @override
  String tooManyRequests(int seconds) {
    return 'Too many requests. Wait $seconds s and try again.';
  }

  @override
  String get tooManyRequestsWait =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueAction => 'Continue';

  @override
  String get fieldRequired => 'Required.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailInvalid => 'Enter a valid email.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'At least 10 characters.';

  @override
  String get passwordTooShort => 'The password needs at least 10 characters.';

  @override
  String get passwordTooLong => 'The password can have at most 128 characters.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get goToLogin => 'Go to sign in';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginInvalid => 'Wrong email or password.';

  @override
  String loginLocked(String lockId) {
    return 'Account locked for 15 minutes after too many failed attempts. If you need help, quote the code $lockId.';
  }

  @override
  String get loginForgot => 'Forgot your password?';

  @override
  String get loginNoAccount => 'No account? Sign up';

  @override
  String get loginPasswordChanged =>
      'Password changed. You can sign in with the new one.';

  @override
  String get loginDemoAccounts => 'Test accounts (development only)';

  @override
  String get restoreTitle => 'Account pending deletion';

  @override
  String restoreBody(String date) {
    return 'Your account will be deleted on $date. Do you want to restore it?';
  }

  @override
  String get restoreConfirm => 'Restore account';

  @override
  String get restoreExpired =>
      'Too much time has passed. Sign in again to restore the account.';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubmit => 'Create account';

  @override
  String get registerBirthDate => 'Date of birth';

  @override
  String get registerUnderage =>
      'Children under 14 cannot create their own account. A parent or guardian adds them from their own account by adding a minor profile (coming soon).';

  @override
  String get registerProfile => 'How will you use Brackety?';

  @override
  String get registerProfileRequired => 'Choose a profile.';

  @override
  String get profileClub => 'Club';

  @override
  String get profileClubHint => 'Organises events and registers its athletes.';

  @override
  String get profileExternalEntity => 'External entity';

  @override
  String get profileExternalEntityHint =>
      'Federation, city council or another body that organises events.';

  @override
  String get profileHelper => 'Helper';

  @override
  String get profileHelperHint =>
      'Helps at events: groups, table or refereeing.';

  @override
  String get profileExternal => 'External';

  @override
  String get profileExternalHint =>
      'Follows events and results without belonging to a club.';

  @override
  String get profileStudent => 'Student';

  @override
  String get profileStudentHint => 'Athlete who competes with their club.';

  @override
  String get registerAccept =>
      'I accept the terms of use and the privacy policy.';

  @override
  String get registerAcceptRequired =>
      'You must accept them to create the account.';

  @override
  String get registerOrganizationName => 'Organization name';

  @override
  String get registerOrganizationNameLength => 'Between 2 and 200 characters.';

  @override
  String get registerTaxId => 'CIF (Spanish tax ID)';

  @override
  String get registerTaxIdHelper =>
      'The platform uses it to verify the organization before it can publish events.';

  @override
  String get registerTaxIdInvalid => 'Invalid CIF.';

  @override
  String get registerRepresentative =>
      'I am of legal age and represent this organization.';

  @override
  String get registerRepresentativeRequired =>
      'You must confirm it to register the organization.';

  @override
  String get registerHaveAccount => 'Already have an account? Sign in';

  @override
  String get checkEmailTitle => 'Check your email';

  @override
  String get checkEmailBody =>
      'We have sent you an email. Open its link to verify the account; it expires in 24 hours.';

  @override
  String get resendEmail => 'Resend email';

  @override
  String get resendSent => 'Email sent.';

  @override
  String get verifyBanner => 'Verify your email: some actions need it.';

  @override
  String get verifyTitle => 'Verify email';

  @override
  String get verifySuccess => 'Email verified. Thank you!';

  @override
  String get linkInvalid => 'The link is invalid or has expired.';

  @override
  String get forgotTitle => 'Recover password';

  @override
  String get forgotIntro =>
      'Enter your email and we will send you a link to choose a new password.';

  @override
  String get forgotSubmit => 'Send link';

  @override
  String get forgotSent =>
      'If there is an account with that email, we have sent you a link to change the password.';

  @override
  String get resetTitle => 'New password';

  @override
  String get resetNewPassword => 'New password';

  @override
  String get resetConfirmPassword => 'Repeat the password';

  @override
  String get resetMismatch => 'The passwords do not match.';

  @override
  String get resetSubmit => 'Change password';

  @override
  String get resetRequestNew => 'Request another link';

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

  @override
  String teamName(int number) {
    return 'Team $number';
  }

  @override
  String teamGhostName(int number) {
    return 'Team $number (ghost)';
  }

  @override
  String get tabParticipants => 'Participants';

  @override
  String get tabTeams => 'Teams';

  @override
  String get individualGroup => 'Individual group';

  @override
  String get individualGroupHint =>
      'For those left without a team: groups of 4 participants.';

  @override
  String categoryTeamCounts(
    int participants,
    int inTeams,
    int teams,
    int grouped,
  ) {
    return '$participants registered · $inTeams in $teams teams · $grouped in groups';
  }

  @override
  String newTeamCount(int count, int size) {
    return 'New team · $count/$size';
  }

  @override
  String get createTeam => 'Create team';

  @override
  String teamCreated(String team) {
    return '$team created';
  }

  @override
  String get teamConflict =>
      'A participant is already in a team or group. The list has been refreshed.';

  @override
  String get teamError => 'The team could not be created.';

  @override
  String get teamsEmpty => 'No teams yet: make them in Participants.';

  @override
  String get deleteTeam => 'Undo team';

  @override
  String deleteTeamConfirm(String team) {
    return 'Undo $team? Its participants become free.';
  }

  @override
  String get deleteTeamError => 'The team could not be undone.';

  @override
  String get draftGhostTeam => 'Ghost team';

  @override
  String draftGhostTeamHint(int size) {
    return 'Pick any $size participants of the category: they fight but do not score.';
  }

  @override
  String pickGhostTeam(int count, int size) {
    return 'Pick participants · $count/$size';
  }
}
