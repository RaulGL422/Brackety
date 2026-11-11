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
  String registerAccept(String terms, String privacy) {
    return 'I accept the $terms and the $privacy.';
  }

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
  String get draftGhost => 'Ghost competitor';

  @override
  String get draftGhostHint => 'Pick the ghost: fights but does not score.';

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
  String get groupsConflict =>
      'A participant is already in a group or the mat has lost its referee. The list has been refreshed.';

  @override
  String get groupsError => 'The group could not be created.';

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
    return 'Group $number, ages $category';
  }

  @override
  String get matRecommended => 'Recommended match';

  @override
  String get matInProgress => 'In progress';

  @override
  String get matPending => 'Other available matches';

  @override
  String get matYours => 'Your mat';

  @override
  String matToPlay(int count) {
    return '$count to play';
  }

  @override
  String get matOpenScoreboard => 'Open the scoreboard';

  @override
  String get matBackToScoreboard => 'Back to the scoreboard';

  @override
  String get matWatch => 'Watch the match';

  @override
  String get matGroups => 'Groups on this mat';

  @override
  String get matFinished => 'Fought';

  @override
  String get matWaiting => 'A fighter is in a match right now';

  @override
  String get matNoneAvailable => 'No match can start right now.';

  @override
  String get versus => 'vs';

  @override
  String scoreboardTitle(int mat, int group) {
    return 'Mat $mat, group $group';
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
  String addPointFor(String corner) {
    return '+1 $corner';
  }

  @override
  String sanctionsFor(String corner) {
    return 'Warnings: $corner';
  }

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
    return '$action: $fighter';
  }

  @override
  String get reasonLabel => 'Reason';

  @override
  String get reasonConfirm =>
      'Write the reason. It stays in the match history.';

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
  String get removePoint => '−1';

  @override
  String removePointFor(String corner) {
    return 'Take a point from $corner';
  }

  @override
  String whatPointRemoved(String corner) {
    return '−1 $corner';
  }

  @override
  String whatClockAdjust(String delta) {
    return '$delta s on the clock';
  }

  @override
  String clockAdjustBy(String delta) {
    return '$delta s';
  }

  @override
  String clockAdjustTooltip(String delta) {
    return 'Adjust the clock $delta s';
  }

  @override
  String get clockAdjustHint => 'Adjust the clock (stopped)';

  @override
  String get tlPointRemoved => 'Point taken back';

  @override
  String get tlClockAdjust => 'Clock adjusted';

  @override
  String get tlNextUndo => 'what Undo takes back next';

  @override
  String undoDetail(String what, String clock) {
    return '$what · $clock';
  }

  @override
  String get recentActions => 'Last actions';

  @override
  String get refusalNoPoints => 'There are no points to take back.';

  @override
  String get refusalClockRunning => 'Stop the clock before adjusting it.';

  @override
  String get refusalClockLimit => 'The clock cannot go further.';

  @override
  String get settingsMatchRules => 'Matches';

  @override
  String get settingsMatchLength => 'Match length (min:s)';

  @override
  String get settingsMatchLengthHint =>
      'From 0:30 to 20:00. It does not change while a match is in progress.';

  @override
  String get settingsMatchLengthInvalid =>
      'Type minutes and seconds between 0:30 and 20:00, for example 3:00.';

  @override
  String get settingsPointsLimit => 'Points that end the match';

  @override
  String get settingsPointsLimitHint =>
      'The match ends when one fighter reaches them. A disqualification gives them to the rival. It does not change once a match has started.';

  @override
  String get settingsMatchRulesConflict =>
      'It cannot change now: a match is in progress or has started.';

  @override
  String get settingsPointsLimitInvalid => 'Between 1 and 99.';

  @override
  String get matWaitingTitle => 'Waiting';

  @override
  String get matStartRecommended => 'Start this match';

  @override
  String get matRecommendedWhy =>
      'Its fighters have rested the longest and none has just fought.';

  @override
  String get matAfterCurrent => 'When the match in progress ends.';

  @override
  String get undoGroup => 'Undo group';

  @override
  String undoGroupNumber(int number) {
    return 'Undo Group $number';
  }

  @override
  String undoGroupConfirm(int number) {
    return 'Group $number and its matches are undone. Its participants go back to the list to be grouped again.';
  }

  @override
  String undoGroupDone(int number) {
    return 'Group $number undone';
  }

  @override
  String get undoGroupStarted =>
      'A match of this group has already started: only the administrator can undo it.';

  @override
  String get undoGroupError => 'The group could not be undone.';

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
    String _temp0 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups groups',
      one: '1 group',
    );
    String _temp1 = intl.Intl.pluralLogic(
      pending,
      locale: localeName,
      other: '$pending pending matches',
      one: '1 pending match',
    );
    return '$_temp0 · $_temp1';
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
  String get exportMenu => 'Export';

  @override
  String get exportStandings => 'Standings (CSV)';

  @override
  String get exportMatches => 'Matches (CSV)';

  @override
  String get exportTimeline => 'Timeline (CSV)';

  @override
  String get exportEventPackage => 'Export event package';

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
  String get teamGroup => 'Team group';

  @override
  String get matPickerLabel => 'Mat';

  @override
  String get matAuto => 'Automatic';

  @override
  String get matAutoOption => 'The one free first';

  @override
  String get matAutoHint =>
      'It is assigned automatically to the mat that will be free first.';

  @override
  String matManualHint(String mat) {
    return 'It goes to $mat, picked by hand.';
  }

  @override
  String get individualGroupHint =>
      'For those left without a team: groups of 4 participants.';

  @override
  String categoryTeamCounts(int participants, int teams, int grouped) {
    return '$participants registered · $teams teams · $grouped in groups';
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

  @override
  String get settingsTitle => 'Account settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsEmailVerified => 'Verified';

  @override
  String get settingsEmailUnverified => 'Not verified';

  @override
  String get settingsChangeEmail => 'Change email';

  @override
  String get changeEmailNew => 'New email';

  @override
  String get changeEmailSubmit => 'Send link';

  @override
  String changeEmailSent(String email) {
    return 'We have sent an email to $email. Open its link to finish the change (it expires in 24 hours).';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageHint =>
      'It is also the language of the emails we send you.';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsLanguageError => 'The language could not be changed.';

  @override
  String get settingsProfiles => 'Profiles';

  @override
  String get profileValidated => 'Validated';

  @override
  String get profilePendingValidation => 'Pending validation';

  @override
  String profileTaxId(String taxId) {
    return 'Tax ID (CIF): $taxId';
  }

  @override
  String get profileAdd => 'Add profile';

  @override
  String get profileAdded => 'Profile added.';

  @override
  String get profileRemove => 'Remove profile';

  @override
  String profileRemoveConfirm(String profile) {
    return 'Remove the $profile profile?';
  }

  @override
  String get profileRemoved => 'Profile removed.';

  @override
  String get removeAction => 'Remove';

  @override
  String get profileLast => 'Your account needs at least one profile.';

  @override
  String get profileCombination =>
      'That profile cannot be combined with the ones you have.';

  @override
  String get profileNeedsVerifiedEmail =>
      'Verify your email before adding profiles.';

  @override
  String get settingsSignInMethods => 'Sign-in methods';

  @override
  String get signInPassword => 'Email and password';

  @override
  String get signInGoogle => 'Google';

  @override
  String get googleUnlink => 'Unlink';

  @override
  String get googleUnlinkConfirm =>
      'Unlink your Google account? You will only be able to sign in with email and password.';

  @override
  String get googleUnlinked => 'Google unlinked.';

  @override
  String get passwordRemove => 'Remove password';

  @override
  String get passwordRemoveConfirm =>
      'You will only be able to sign in with Google, and all your sessions will be closed, this one too. To have a password again, use \"Forgot your password?\".';

  @override
  String get lastSignInMethod =>
      'This is your only way to sign in. Add another one first.';

  @override
  String get needsGoogle =>
      'This action needs you to confirm with Google, coming soon to the app.';

  @override
  String get settingsData => 'Your data';

  @override
  String get settingsDataHint => 'Download a copy of your account data (JSON).';

  @override
  String get settingsExport => 'Export my data';

  @override
  String get settingsDanger => 'Danger zone';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountHint =>
      'It is deleted for good after 30 days. Until then you can restore it by signing in.';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'All your sessions will be closed. The account, with its profiles and data, will be deleted for good after 30 days. Until then you can restore it by signing in.';

  @override
  String get deleteOwnsEvents =>
      'You are in charge of events. Hand them over to someone else or delete them before deleting your account.';

  @override
  String loginAccountDeleted(String date) {
    return 'Your account will be deleted on $date. Sign in before then to restore it.';
  }

  @override
  String get loginPasswordRemoved =>
      'Password removed and sessions closed. You can now only sign in with Google.';

  @override
  String get reauthTitle => 'Confirm it\'s you';

  @override
  String get reauthBody => 'Enter your password to continue.';

  @override
  String get reauthSubmit => 'Confirm';

  @override
  String get reauthFailed => 'Wrong password.';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get confirmEmailChangeTitle => 'Email change';

  @override
  String get confirmEmailChangeDone =>
      'Email changed. All sessions have been closed: sign in with the new email.';

  @override
  String get categoryIndividual => 'Individual';

  @override
  String categoryTeams(int size) {
    return 'Teams of $size';
  }

  @override
  String get categoryAdd => 'Add category';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryRemove => 'Remove category';

  @override
  String get categoryNameLabel => 'Name';

  @override
  String get categoryMinAge => 'From';

  @override
  String get categoryMaxAge => 'To';

  @override
  String get categoryByTeams => 'By teams';

  @override
  String get categoryTeamSize => 'Participants per team';

  @override
  String categoryGroupSize(int size) {
    return 'Groups of $size';
  }

  @override
  String get categoryAgesInvalid =>
      'The minimum age cannot be above the maximum.';

  @override
  String get categoriesInUse =>
      'A category with groups or teams can only change its name.';

  @override
  String get categoriesInvalid =>
      'Check the categories: their ages cannot overlap.';

  @override
  String standingTeam(String team, String detail) {
    return '$team · $detail';
  }

  @override
  String get categoryAgeSuffix => 'years';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryByAge => 'By age';

  @override
  String get importButton => 'Import participants';

  @override
  String get importFormatTitle => 'What the list should look like';

  @override
  String get importFormatBody =>
      'One row per participant: first name, last name, date of birth (dd/mm/yyyy), height in cm (optional) and category (optional). Photos, a CSV, an Excel or TXT file, or pasted text.';

  @override
  String get importTemplate => 'Download template';

  @override
  String get importPickPhotos => 'Choose photos';

  @override
  String get importPickFile => 'Choose a file';

  @override
  String get importPasteHint => 'Or paste the list here';

  @override
  String get importConsent =>
      'I confirm that every participant on this list, and their guardians if they are minors, agreed to register for this event without exception, and that the list will be processed by an external AI service (Anthropic) only to read it. Images and files are not kept.';

  @override
  String get importRead => 'Read list';

  @override
  String get importReading => 'Reading the list… it can take up to a minute.';

  @override
  String get importReadError =>
      'The list could not be read. Try a sharper photo or a file.';

  @override
  String get importTooMany =>
      'Too many lists read in the last hour. Try again later.';

  @override
  String importInvalidFiles(int max) {
    return 'Only photos (JPG, PNG, WebP), CSV, TXT or Excel: up to $max files of 10 MB.';
  }

  @override
  String importSummary(int total, int errors, int warnings) {
    return '$total participants · $errors with errors · $warnings to check';
  }

  @override
  String importRegister(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Register $count participants',
      one: 'Register 1 participant',
    );
    return '$_temp0';
  }

  @override
  String importRegistered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants registered',
      one: '1 participant registered',
    );
    return '$_temp0';
  }

  @override
  String get importRegisterRefused =>
      'Nobody was registered: check the marked rows.';

  @override
  String get importAddRow => 'Add participant';

  @override
  String get importEditRow => 'Edit participant';

  @override
  String get importRemoveRow => 'Remove from the list';

  @override
  String get importStartOver => 'Upload again';

  @override
  String get importEmpty => 'The list has no participants.';

  @override
  String importUseCategory(String name) {
    return 'Use $name';
  }

  @override
  String get fieldFirstName => 'the first name';

  @override
  String get fieldLastName => 'the last name';

  @override
  String get fieldBirthDate => 'the date of birth';

  @override
  String get fieldHeight => 'the height';

  @override
  String get fieldCategory => 'the category';

  @override
  String issueMissing(String field) {
    return 'Missing $field';
  }

  @override
  String issueTooLong(String field) {
    return 'Too long: $field';
  }

  @override
  String issueInvalidDate(String text) {
    return 'Not a valid date: $text';
  }

  @override
  String get issueFutureDate => 'The date of birth must be before today';

  @override
  String issueHeight(String cm) {
    return 'Height $cm: it must be between 50 and 250 cm';
  }

  @override
  String issueNoCategory(String age) {
    return 'No category of the event is for age $age';
  }

  @override
  String issueUnknownCategory(String name) {
    return 'There is no category \"$name\" in the event';
  }

  @override
  String get issueChosenCategoryGone => 'The chosen category no longer exists';

  @override
  String issueCategoryMismatch(String written, String byAge) {
    return 'It says $written, but by age it is $byAge';
  }

  @override
  String issueDuplicate(String row) {
    return 'Repeated in the list (row $row)';
  }

  @override
  String get issueAlreadyRegistered => 'Already registered in the event';

  @override
  String issueUnsure(String field) {
    return 'Check $field: it was not read with certainty';
  }

  @override
  String get legalSection => 'Legal';

  @override
  String get legalPrivacy => 'Privacy policy';

  @override
  String get legalTerms => 'Terms of use';

  @override
  String get legalCookies => 'Cookie policy';

  @override
  String get legalNotice => 'Legal notice';

  @override
  String get legalPrivacyShort => 'Privacy';

  @override
  String get legalTermsShort => 'Terms';

  @override
  String get legalCookiesShort => 'Cookies';

  @override
  String get legalLicenses => 'Licenses';

  @override
  String get legalPrivacyLink => 'privacy policy';

  @override
  String get legalTermsLink => 'terms of use';

  @override
  String get legalNotFound => 'This legal page does not exist.';

  @override
  String get registerLegalOutdated =>
      'The terms of use or the privacy policy have changed. Review them and accept them again.';

  @override
  String participantPrivacyNotice(String privacy) {
    return 'The student\'s data is handled according to the $privacy.';
  }

  @override
  String importPrivacyNotice(String privacy) {
    return 'The students\' data is handled according to the $privacy.';
  }

  @override
  String serverCurrent(String name) {
    return 'Server: $name';
  }

  @override
  String get serverChange => 'Change';

  @override
  String get serverDialogTitle => 'Choose server';

  @override
  String get serverHall => 'Sports hall';

  @override
  String get serverInternet => 'Internet';

  @override
  String get serverOther => 'Other URL';

  @override
  String get serverUrlLabel => 'Server URL';

  @override
  String get serverUrlHint => 'https://server.example';

  @override
  String get serverUrlInvalid =>
      'Type a URL starting with http:// or https:// with a host.';

  @override
  String get serverUrlCleartext =>
      'Without https the app only reaches the sports hall (192.168.137.1): this URL will not connect.';

  @override
  String get serverUse => 'Use';

  @override
  String get syncConnected => 'Connected';

  @override
  String get syncOffline => 'Offline';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions waiting',
      one: '1 action waiting',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions refused',
      one: '1 action refused',
    );
    return '$_temp0';
  }

  @override
  String get syncRejectedShow => 'Show';

  @override
  String get syncRejectedTitle => 'Refused actions';

  @override
  String get syncRejectedBody =>
      'The server did not accept these actions and they do not count in the match. Tell the club if needed.';

  @override
  String get syncRejectedDismiss => 'Remove from the list';

  @override
  String get close => 'Close';

  @override
  String get matOfflineBoard =>
      'Offline: board saved on the phone. No recommendation; you can start a pending match if none is in progress.';

  @override
  String get matInReview => 'Under the club\'s review';

  @override
  String get refusalFinished => 'The match is already finished.';

  @override
  String get refusalOver => 'The match is already over.';

  @override
  String get refusalRunning => 'The clock is already running.';

  @override
  String get refusalNotRunning => 'The clock is not running.';

  @override
  String get refusalNothingToUndo => 'Nothing to undo.';

  @override
  String get refusalNotOver => 'The match is not over yet.';

  @override
  String get refusalNotForAge =>
      'The one-hand warning is only for fighters aged 4 to 7.';

  @override
  String get refusalInReview => 'The match is under the club\'s review.';

  @override
  String get refusalMatBusy => 'Another match is in progress on this mat.';

  @override
  String get reviewBannerReferee =>
      'Under the club\'s review: this match waits until the club applies or discards this phone\'s actions.';

  @override
  String get reviewTitle => 'Phone actions under review';

  @override
  String get reviewReasonKnownEvents =>
      'Another device wrote in the match while the phone was offline.';

  @override
  String get reviewReasonRules =>
      'The scoreboard rules did not allow one of the phone\'s actions.';

  @override
  String get reviewReasonAge => 'One-hand warning to someone not aged 4 to 7.';

  @override
  String get reviewReasonMatBusy => 'Another match was in progress on the mat.';

  @override
  String get reviewReasonFighterBusy =>
      'A fighter was in a match on another mat.';

  @override
  String get reviewReasonUnknown => 'Clash with the server.';

  @override
  String get reviewApply => 'Apply';

  @override
  String get reviewDiscard => 'Discard';

  @override
  String get reviewApplyConfirm =>
      'The phone\'s actions go in, in order and at their time. Those the rules do not allow are skipped.';

  @override
  String get reviewDiscardConfirm =>
      'The phone\'s actions do not count in the match. They stay in the log.';

  @override
  String reviewApplied(int applied, int skipped) {
    return 'Applied: $applied · Skipped: $skipped';
  }

  @override
  String get reviewDiscarded => 'Actions discarded.';

  @override
  String matsInReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches under review',
      one: '1 match under review',
    );
    return '$_temp0';
  }

  @override
  String logoutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You have $count actions not sent yet; if you sign out they will be lost.',
      one: 'You have 1 action not sent yet; if you sign out it will be lost.',
    );
    return '$_temp0';
  }

  @override
  String get refusalNotStarted => 'Start the clock before scoring.';

  @override
  String undoneWhat(String what) {
    return 'Undone: $what';
  }

  @override
  String whatPoint(String corner) {
    return '+1 $corner';
  }

  @override
  String whatWarning(String corner) {
    return '$corner warning';
  }

  @override
  String whatOneHand(String corner) {
    return '$corner one-hand warning';
  }

  @override
  String whatDisqualification(String corner) {
    return '$corner disqualification';
  }

  @override
  String get winner => 'Winner';

  @override
  String get draw => 'Draw';

  @override
  String get matLocked => 'Cannot open yet';

  @override
  String get needsGuardian => 'Guardian missing';

  @override
  String settingsRemoveMatConfirm(int number) {
    return 'Mat $number is removed; its referee is no longer assigned.';
  }

  @override
  String get draftTitle => 'New group';

  @override
  String get draftReady => 'Complete';

  @override
  String draftMissing(int count) {
    return '$count to go';
  }

  @override
  String draftSlot(int number) {
    return 'Slot $number';
  }

  @override
  String ghostOf(String name) {
    return '$name (ghost)';
  }

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceHint =>
      'Automatic follows the device\'s light or dark mode. It is saved on this device only.';

  @override
  String get themeSystem => 'Automatic';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get refusalStale =>
      'The match changed on another device. Check the scoreboard and press again.';

  @override
  String get accountSuspended =>
      'This account is suspended. If you think it is a mistake, write to the privacy contact on the legal pages.';

  @override
  String backTo(String place) {
    return 'Back to $place';
  }

  @override
  String get reasonApplyWarning => 'Give warning';

  @override
  String get reasonApplyDisqualify => 'Disqualify';

  @override
  String get accountMenu => 'My account';

  @override
  String get back => 'Back';
}
