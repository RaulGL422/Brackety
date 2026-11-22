// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get draftGhostTeamPanelHint =>
      'Up to 3 wildcard teams: they fight but do not score. A team of another group always is.';

  @override
  String get teamJoinsAsWildcard => 'Tap to join as a wildcard team';

  @override
  String get ghostTeamPageTitle => 'Make a wildcard team';

  @override
  String get ghostTeamSearch => 'Search a participant';

  @override
  String get formGhostTeam => 'Make a wildcard team with loose participants';

  @override
  String get teamPickWildcards => 'Pick wildcards';

  @override
  String matReservedElsewhere(int mat) {
    return 'Someone in this match is expected on mat $mat now';
  }

  @override
  String get matAfterIndividual => 'After your individual group';

  @override
  String matPlannedAt(String time) {
    return 'Expected around $time';
  }

  @override
  String get controlMenu => 'Change';

  @override
  String get controlDone => 'Done';

  @override
  String get controlError =>
      'The change could not be made. Reload and try again.';

  @override
  String get controlMatchInProgress =>
      'A match of this group is in progress: wait until it ends.';

  @override
  String get controlMatchNotPending =>
      'That match has started: it cannot change.';

  @override
  String get controlMatIsDisabled =>
      'That mat is disabled: enable it or pick another.';

  @override
  String get controlOrderChanged =>
      'The matches changed meanwhile: reload and order them again.';

  @override
  String get controlTeamSize => 'Teams must stay of 2 or 3.';

  @override
  String get controlGroupStarted =>
      'The group of those teams has started: its teams no longer change.';

  @override
  String get controlSameFighter =>
      'That person already fights in the other team\'s group (as a wildcard).';

  @override
  String get controlMatInReview =>
      'A match on this mat waits for review: resolve it first.';

  @override
  String get controlMatBusy =>
      'A match is in progress on this mat: wait for it to end.';

  @override
  String get controlDisableMat => 'Disable mat';

  @override
  String controlDisableMatTitle(int number) {
    return 'Disable mat $number?';
  }

  @override
  String get controlDisableMatBody =>
      'Choose the mat each group with pending matches goes to (Automatic: the one that ends first). Team matches go to the other mats. To use it again, \"Enable mat\" in Mats gives it back its referee.';

  @override
  String controlMatDisabled(int groups, int pool) {
    String _temp0 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups groups moved',
      one: '1 group moved',
      zero: 'no group moved',
    );
    String _temp1 = intl.Intl.pluralLogic(
      pool,
      locale: localeName,
      other: ', $pool team matches back to the pool',
      one: ', 1 team match back to the pool',
      zero: '',
    );
    return 'Mat disabled: $_temp0$_temp1.';
  }

  @override
  String get controlPickMat => 'To which mat?';

  @override
  String get controlEnableMat => 'Enable mat';

  @override
  String controlMatEnabled(int number) {
    return 'Mat $number back in use with its referee.';
  }

  @override
  String get controlMatNotDisabled => 'This mat is already in use.';

  @override
  String get controlMatRefereeTaken =>
      'Its referee is no longer free: assign one in Settings.';

  @override
  String get matDisabled => 'Out of use';

  @override
  String matDisabledSince(String time) {
    return 'Out of use since $time';
  }

  @override
  String matDisabledReferee(String name) {
    return 'Referee: $name';
  }

  @override
  String get controlNoOtherMat => 'No other mat is in use.';

  @override
  String controlMatOption(int number, String referee, int pending) {
    String _temp0 = intl.Intl.pluralLogic(
      pending,
      locale: localeName,
      other: '$pending pending',
      one: '1 pending',
      zero: 'nothing pending',
    );
    return 'Mat $number · $referee · $_temp0';
  }

  @override
  String get controlMoveMatch => 'Move this match to another mat';

  @override
  String get controlWaiveRest => 'Let it start without waiting for the rest';

  @override
  String get controlWaiveRestTitle => 'Start without the least rest?';

  @override
  String controlWaiveRestBody(String red, String blue) {
    return '$red against $blue may start although someone has not rested. Who allowed it is recorded.';
  }

  @override
  String get controlConfirm => 'Yes, allow';

  @override
  String get controlMoveGroup => 'Move the group to another mat';

  @override
  String get controlReorder => 'Change the order of the matches';

  @override
  String get controlReorderHint =>
      'Drag to order the pending matches. The played ones do not change.';

  @override
  String get controlMoveMember => 'Move a participant to another team';

  @override
  String get controlMoveMemberWho => 'Who changes?';

  @override
  String get controlMoveMemberTo => 'To which team?';

  @override
  String get settingsMatNeedsReferee =>
      'That mat has matches to play: it cannot be left without a referee. Assign another referee or wait until they finish.';

  @override
  String get refusalResting =>
      'Not yet: someone in this match has not had the least rest since their last match. Wait until the board unlocks it.';

  @override
  String cornerFightingNow(int mat) {
    return 'Fighting on mat $mat';
  }

  @override
  String cornerFighting(int mat, String time) {
    return 'Fighting on mat $mat · free around $time';
  }

  @override
  String cornerResting(String time) {
    return 'Resting until $time';
  }

  @override
  String cornerPending(int count, String mats) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more matches',
      one: 'One more match',
    );
    return '$_temp0 on mat $mats';
  }

  @override
  String get rulebookTitle => 'Phase rulebook';

  @override
  String get rulebookHint =>
      'The PDF with the full rulebook. Referees open it from their mat screen, also on the sports hall laptop (it travels in the event package).';

  @override
  String get rulebookNone => 'No rulebook';

  @override
  String get rulebookUpload => 'Upload PDF';

  @override
  String get rulebookReplace => 'Replace PDF';

  @override
  String get rulebookOpen => 'Open rulebook';

  @override
  String get rulebookRemove => 'Remove';

  @override
  String get rulebookUploaded => 'Rulebook uploaded';

  @override
  String get rulebookUploadError =>
      'Could not upload: it must be a PDF of up to 10 MB.';

  @override
  String get rulebookRemoveError => 'Could not remove the rulebook.';

  @override
  String get rulebookOpenError =>
      'Could not open the rulebook. Check the connection.';

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
  String get newEventButton => 'New event';

  @override
  String get newEventTitle => 'New event';

  @override
  String get newEventHint =>
      'A standalone event, with its mats. Categories, entries and referees are added later from its panel.';

  @override
  String get newEventName => 'Event name';

  @override
  String get newEventMats => 'Mats';

  @override
  String newEventMatsInvalid(int max) {
    return 'From 1 to $max';
  }

  @override
  String get newEventCreate => 'Create event';

  @override
  String get newEventDone => 'Event created';

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
  String participantGrouped(int group, String mat) {
    return 'Group $group · $mat';
  }

  @override
  String draftGroup(int number) {
    return 'Group $number';
  }

  @override
  String get draftGhost => 'Wildcard';

  @override
  String get draftGhostHint =>
      'Up to 3 wildcards: they fight but do not score. Anyone already in a group and the 4th pick always are.';

  @override
  String get draftAddAs => 'Add as';

  @override
  String get draftAddAsReal => 'Normal';

  @override
  String get draftAddAsGhost => 'Wildcard';

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
      'A participant is already in another group. The list has been refreshed.';

  @override
  String get groupsMatDisabled =>
      'That mat is disabled: pick another or \"Automatic\".';

  @override
  String get groupsError => 'The group could not be created.';

  @override
  String get ok => 'OK';

  @override
  String get ghostBadge => 'Wildcard';

  @override
  String matTitle(int number) {
    return 'Mat $number';
  }

  @override
  String get matPool => 'Free mats';

  @override
  String queuedOffline(String what) {
    return 'Offline: $what will be sent when the network is back. Meanwhile its participants show as pending.';
  }

  @override
  String queuedSent(String what) {
    return 'Sent: $what';
  }

  @override
  String queuedRefused(String what) {
    return '$what could not be created: someone was already in another group or team. Check the list.';
  }

  @override
  String get queuedPending => 'Waiting to be sent (offline)';

  @override
  String queuedGroupLabel(String names) {
    return 'the group of $names';
  }

  @override
  String queuedTeamLabel(String names) {
    return 'the team of $names';
  }

  @override
  String get matEmpty => 'No groups on this mat yet.';

  @override
  String matGroupHeader(int number, String category) {
    return 'Group $number · $category';
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
  String matResting(String time) {
    return 'Resting until $time';
  }

  @override
  String matProposedElsewhere(int number) {
    return 'Proposed to mat $number';
  }

  @override
  String get matPoolOffline => 'Offline: another mat may be running it';

  @override
  String get matTeamPoolNotice =>
      'No individual groups pending: this mat takes team matches from the shared pool, spread over the free mats. The most rested go first.';

  @override
  String get matNoneAvailable => 'No match can start right now.';

  @override
  String get versus => 'vs';

  @override
  String scoreboardTitle(String mat, int group) {
    return '$mat, group $group';
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
  String addPointsFor(int points, String corner, String labels) {
    return '+$points $corner: $labels';
  }

  @override
  String removePointsValue(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Take back $points points',
      one: 'Take back 1 point',
    );
    return '$_temp0';
  }

  @override
  String get extraTimeWon => 'Won the extra time';

  @override
  String extraTimeWonBy(String corner) {
    return '$corner won the extra time';
  }

  @override
  String winConfirmTitle(String what) {
    return '$what?';
  }

  @override
  String winConfirmBody(String corner) {
    return '$corner wins and the match ends. It can be undone.';
  }

  @override
  String get winConfirm => 'Give the win';

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
  String get endSuperiority => 'Ended by superiority';

  @override
  String get endWarnings => 'Ended by warnings';

  @override
  String get endSubmission => 'Ended by submission';

  @override
  String get endExtraTime => 'Ended in extra time';

  @override
  String actionRefused(String detail) {
    return 'Could not record it. $detail';
  }

  @override
  String get tlStart => 'Clock started';

  @override
  String get tlStop => 'Stop';

  @override
  String tlPoints(int points) {
    return '$points points';
  }

  @override
  String tlPointsRemoved(int points) {
    return '$points points taken back';
  }

  @override
  String get tlPoint => 'Point';

  @override
  String get tlUndo => 'Undo';

  @override
  String get tlFinish => 'Match finished';

  @override
  String get tlAutomatic => 'automatic';

  @override
  String get tlOvertime => 'after time';

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
  String whatPointRemoved(int points, String corner) {
    return '−$points $corner';
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
  String get refusalNotInThisSport =>
      'This action does not exist in this sport.';

  @override
  String get refusalInvalidValue => 'No action of this sport is worth that.';

  @override
  String get refusalNoExtraTime =>
      'Extra time is only for a tie at the end that no tiebreaker settles.';

  @override
  String get refusalExtraTimePending =>
      'Tied after every tiebreaker: extra time first.';

  @override
  String get settingsMatchRules => 'Matches';

  @override
  String get settingsMatchLength => 'Individual: match length (min:s)';

  @override
  String get settingsTeamMatchLength => 'Teams: match length (min:s)';

  @override
  String get settingsTeamPointsLimit => 'Teams: points that end the match';

  @override
  String get settingsTeamPointsLimitHint =>
      'Empty = no limit: the time ends it. A disqualification gives the rival 15 points, or theirs if higher.';

  @override
  String get settingsMinRest => 'Least rest between matches (seconds)';

  @override
  String get settingsMinRestHint =>
      'Nobody starts a match without this rest since their last one, on any mat. Until then the match waits.';

  @override
  String get settingsMinRestInvalid => 'Between 0 and 600 seconds.';

  @override
  String get settingsMatchLengthHint =>
      'From 0:30 to 20:00. It does not change while a match is in progress.';

  @override
  String get settingsMatchLengthInvalid =>
      'Type minutes and seconds between 0:30 and 20:00, for example 3:00.';

  @override
  String get settingsPointsLimit => 'Individual: points that end the match';

  @override
  String get settingsPointsLimitHint =>
      'The match ends when one fighter reaches them. Empty = no limit: the time ends it. A disqualification gives them to the rival. It does not change once a match has started.';

  @override
  String get settingsMatchRulesConflict =>
      'It cannot change now: a match is in progress or has started.';

  @override
  String get settingsPointsLimitInvalid =>
      'Between 0 and 99 (empty = no limit).';

  @override
  String get settingsSuperiorityGap => 'Points difference that ends the match';

  @override
  String get settingsSuperiorityGapHint =>
      'Whoever gets this lead wins (grappling: 15). Empty = it never ends on difference. It does not change once a match has started.';

  @override
  String get settingsSuperiorityGapInvalid =>
      'Between 0 and 100 (empty = it never ends on difference).';

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
  String standingsClassification(int points) {
    return '$points class. pts';
  }

  @override
  String standingsWinsDetail(int wins, int points, int matches) {
    return 'Wins $wins · Technical points $points ($matches)';
  }

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
  String get sexLabel => 'Sex';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexMale => 'Male';

  @override
  String get sexUnknown => 'sex not declared';

  @override
  String get weightOptional => 'Weight in kg (optional)';

  @override
  String get weightInvalid => 'Between 10 and 250 kg, one decimal at most';

  @override
  String get weightUnknown => 'no weight';

  @override
  String get weightMissing => 'weight missing';

  @override
  String get heightMissing => 'height missing';

  @override
  String get measuresTitle => 'Weight and height';

  @override
  String get measuresHint =>
      'Required: nobody goes into a group or team without it, and the helper can write it down on the day. Optional: the grouping screens say who lacks it.';

  @override
  String get measureWeight => 'Weight';

  @override
  String get measureHeight => 'Height';

  @override
  String requirementSport(String value) {
    return 'As the sport ($value)';
  }

  @override
  String get requirementOff => 'Not asked';

  @override
  String get requirementOptional => 'Optional';

  @override
  String get requirementRequired => 'Required';

  @override
  String measuresOf(String name) {
    return 'Weight and height of $name';
  }

  @override
  String get measuresWrite => 'Write down weight and height';

  @override
  String get measuresMissingError =>
      'Someone lacks the required weight or height: write it down before grouping.';

  @override
  String weightKg(String kg) {
    return '$kg kg';
  }

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
  String get organizationsTitle => 'Clubs taking part';

  @override
  String get organizationsEmpty =>
      'No clubs yet. Add them to set the club of each participant.';

  @override
  String get organizationAdd => 'Add club';

  @override
  String get organizationEdit => 'Edit club';

  @override
  String get organizationRemove => 'Remove club';

  @override
  String get organizationName => 'Club name';

  @override
  String get organizationShortName => 'Short name (optional)';

  @override
  String get organizationLabel => 'Club';

  @override
  String get organizationNone => 'No club';

  @override
  String get organizationsConflict =>
      'Not possible: that club has participants or another one has the same name.';

  @override
  String get exportParticipants => 'Participants (CSV)';

  @override
  String get exportFull => 'The whole event (.zip)';

  @override
  String get importResults => 'Import results from the sports hall';

  @override
  String get importResultsTitle => 'Import these results?';

  @override
  String importResultsBody(
    int groups,
    int matches,
    int actions,
    int participants,
  ) {
    return '$groups groups, $matches matches and $actions scoreboard actions will be added, and $participants participants who were not here. It cannot be undone.';
  }

  @override
  String get importResultsConfirm => 'Import';

  @override
  String get importResultsDone => 'Results imported.';

  @override
  String get importResultsAlready =>
      'These results were already imported: nothing changes.';

  @override
  String get importResultsOtherEvent =>
      'The file is from another event (another name or date).';

  @override
  String get importResultsConflict =>
      'This event already has groups of its own: results are only imported into an event without competition.';

  @override
  String get importResultsInvalid =>
      'The file is not a Brackety export (.zip or .brackety) with results.';

  @override
  String get importResultsError => 'The results could not be imported.';

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
    return 'Team $number (wildcard)';
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
  String get draftGhostTeam => 'Wildcard team';

  @override
  String draftGhostTeamHint(int size) {
    return 'Wildcard teams (up to 3): 2 to $size participants of the category not in the group yet. They fight but do not score.';
  }

  @override
  String get addGhostTeam => 'Add wildcard team';

  @override
  String get teamGroupPoolHint =>
      'No mat: its matches are spread over the mats without individual groups.';

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
  String get categoryTeams => 'Teams of 2 or 3';

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
  String categoryOwnLength(String length) {
    return '$length per match';
  }

  @override
  String get categoryMatchLength => 'Own match length (min:s)';

  @override
  String get categoryMatchLengthHint =>
      'Empty: the event\'s. In grappling, 4:00 for U13, U15 and veterans.';

  @override
  String get categoryByTeams => 'By teams';

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
  String get splitByAge => 'Split by age';

  @override
  String ageHeading(int age, int count) {
    return '$age years · $count';
  }

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
  String get fieldSex => 'the sex';

  @override
  String get fieldWeight => 'the weight';

  @override
  String issueWeight(String kg) {
    return 'Weight $kg: it must be between 10 and 250 kg, one decimal at most';
  }

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
  String get syncExport => 'Export pending actions';

  @override
  String get syncExportBody =>
      'If this device cannot connect again, give the file to the club: they import it from their panel and nothing is lost.';

  @override
  String get syncExportSave => 'Download CSV';

  @override
  String get importOps => 'Import actions from a device';

  @override
  String importOpsResult(
    int applied,
    int duplicates,
    int inReview,
    int skipped,
  ) {
    return 'Imported: $applied new · $duplicates already there · $inReview to review · $skipped refused';
  }

  @override
  String get importOpsError =>
      'Could not import: the file is not one of pending actions or is from another event.';

  @override
  String get close => 'Close';

  @override
  String get matOfflineBoard =>
      'Offline: board saved on this device. No recommendation; you can start a pending match if none is in progress.';

  @override
  String get matSyncingTitle => 'Syncing matches';

  @override
  String matSyncingBody(int count, String mats) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The mats have changed and mats $mats have not got it yet. Until they do, their proposed matches may change.',
      one:
          'The mats have changed and mat $mats has not got it yet. Until it does, its proposed match may change.',
    );
    return '$_temp0';
  }

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
      'The one-hand warning is only for fighters aged 4 to 8.';

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
  String get reviewReasonAge => 'One-hand warning to someone not aged 4 to 8.';

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
  String whatPoint(int points, String corner) {
    return '+$points $corner';
  }

  @override
  String whatFinish(String what, String corner) {
    return '$what $corner';
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
    return '$name (wildcard)';
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

  @override
  String get clubLeague => 'League';

  @override
  String phaseNumber(int number) {
    return 'Phase $number';
  }

  @override
  String get leagueSwitchPhase => 'Switch phase';

  @override
  String leaguePodiumSummary(int firsts, int seconds, int thirds) {
    return 'Podium: $firsts golds, $seconds silvers and $thirds bronzes per category';
  }

  @override
  String get leagueEdit => 'Edit league';

  @override
  String get leaguePhases => 'Phases';

  @override
  String get leagueNewPhase => 'New phase';

  @override
  String leaguePhaseEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get leagueCurrentPhase => 'This phase';

  @override
  String get disciplineTambo => 'Tambo';

  @override
  String get disciplineGrappling => 'Grappling';

  @override
  String get disciplineGround => 'Ground';

  @override
  String get disciplineThrows => 'Throws';

  @override
  String get disciplineTechnicalExpression => 'Technical expression';

  @override
  String disciplineSoon(String name) {
    return '$name (coming soon)';
  }

  @override
  String get leagueStandings => 'League standings';

  @override
  String get leagueStandingsCsv => 'Download CSV';

  @override
  String get leagueStandingsByCategory => 'One CSV per category (.zip)';

  @override
  String get leagueStandingsPdf => 'Standings as PDF';

  @override
  String leaguePhasePoints(int number, int total, int attendance, int matches) {
    return 'Phase $number: $total ($attendance for attending + $matches in matches)';
  }

  @override
  String leaguePhaseAbsent(int number) {
    return 'Phase $number: not entered';
  }

  @override
  String get leagueNoPoints => 'No points yet: no place';

  @override
  String leagueCategoryHeader(String category, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$category · $_temp0';
  }

  @override
  String get medalGold => 'Gold';

  @override
  String get medalSilver => 'Silver';

  @override
  String get medalBronze => 'Bronze';

  @override
  String leaguePhaseDefaultName(String league, int number) {
    return '$league · Phase $number';
  }

  @override
  String leagueNewPhaseTitle(int number) {
    return 'New phase $number';
  }

  @override
  String get leagueNewPhaseHint =>
      'Mats with their referees, helpers, categories, clubs and scoreboard rules are copied from this phase. Entries start empty: you can then enter people from other phases.';

  @override
  String get leaguePhaseName => 'Phase name';

  @override
  String get leagueDiscipline => 'Discipline';

  @override
  String get leagueAttendancePoints => 'Attendance points';

  @override
  String get leagueAttendanceInvalid => 'Between 0 and 100';

  @override
  String get leagueNewPhaseCreate => 'Create phase';

  @override
  String leagueNewPhaseDone(int number) {
    return 'Phase $number created';
  }

  @override
  String get leagueName => 'League name';

  @override
  String get leaguePodium => 'General podium';

  @override
  String get leaguePodiumHint =>
      'How many golds, silvers and bronzes each category gives on the final standings. Ties share the medal.';

  @override
  String get leagueCategoryPodiums => 'Categories with their own podium';

  @override
  String get leagueOwnPodium => 'Own podium';

  @override
  String get reenrolButton => 'Enter from other phases';

  @override
  String get reenrolTitle => 'Enter from other phases';

  @override
  String get reenrolEmpty =>
      'Everyone from other phases is already entered in this one.';

  @override
  String get reenrolHint =>
      'They are entered with their data from the latest phase; the category follows their age in this one.';

  @override
  String get reenrolSearch => 'Search by name, category or club';

  @override
  String reenrolSelectAll(int count) {
    return 'Select all ($count)';
  }

  @override
  String reenrolLastPhase(int number) {
    return 'Latest: phase $number';
  }

  @override
  String get reenrolGuardianConsent =>
      'I have the consent of the guardians of the selected minors';

  @override
  String reenrolConfirm(int count) {
    return 'Enter ($count)';
  }

  @override
  String reenrolDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entered',
      one: '1 entered',
    );
    return '$_temp0';
  }

  @override
  String get settingsAttendanceHint =>
      'Everyone competing in a group of this phase adds them to the standings. Changing them recalculates the standings.';

  @override
  String draftTakenElsewhere(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names are already in another group: taken out of the new group.',
      one: '$names is already in another group: taken out of the new group.',
    );
    return '$_temp0';
  }

  @override
  String get teamGhostMember => 'joins as a wildcard';

  @override
  String get teamGhostHint =>
      'Whoever already has a team or a group joins as a wildcard: fights, but does not score for this team.';

  @override
  String ghostMemberName(String name) {
    return '$name (wildcard)';
  }

  @override
  String get teamOverlapTitle =>
      'Not possible: participants in two teams of the group';

  @override
  String teamOverlapLine(String name, String teams) {
    return '$name: $teams';
  }

  @override
  String groupCreatedBy(String name) {
    return 'by $name';
  }

  @override
  String get staffTitle => 'Staff';

  @override
  String get staffHint =>
      'Who is behind each account: shown on the mats and on who made each group.';

  @override
  String get staffNameHint => 'Person\'s name';

  @override
  String get staffReferee => 'referee';

  @override
  String get staffHelper => 'helper';

  @override
  String get cancelMatch => 'Cancel match';

  @override
  String get cancelMatchTitle =>
      'Cancel the match: back to pending, all at 0. Why?';

  @override
  String get cancelMatchDone => 'Match cancelled: pending again.';

  @override
  String get reopenMatch => 'Reopen match';

  @override
  String get reopenMatchTitle => 'Reopen the match to correct it. Why?';

  @override
  String get reopenMatchDone => 'Match reopened: correct it and finish again.';

  @override
  String get refusalNotFinished => 'The match is not finished.';

  @override
  String get tlCancel => 'Match cancelled';

  @override
  String get tlReopen => 'Match reopened';

  @override
  String get tlSubmission => 'Submission';

  @override
  String get tlExtraTime => 'Extra time won';

  @override
  String get matOneAtATime =>
      'A match is in progress: the next one can start when it ends.';

  @override
  String get matQueued => 'Pending';

  @override
  String get keepMatch => 'Keep the match';

  @override
  String get watchClockRunning => 'Clock running';

  @override
  String get watchClockStopped => 'Clock stopped';

  @override
  String placeInCategory(int place, String category, int age) {
    return '#$place in $category · $age years';
  }

  @override
  String recordTotals(int attendance, int matches, int total) {
    return 'Attendance $attendance + matches $matches = $total points';
  }

  @override
  String get recordNoMatches => 'Not in a group yet.';

  @override
  String recordVs(String rival) {
    return 'Against $rival';
  }

  @override
  String recordWhere(String mat, int group) {
    return '$mat · Group $group';
  }

  @override
  String get recordWon => 'Won';

  @override
  String get recordLost => 'Lost';

  @override
  String get recordDraw => 'Draw';

  @override
  String get recordAsGhost => 'as a wildcard (no score)';

  @override
  String recordWarnings(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warnings',
      one: '1 warning',
    );
    return '$_temp0';
  }

  @override
  String recordOneHand(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count one-hand',
      one: '1 one-hand',
    );
    return '$_temp0';
  }

  @override
  String get recordDisqualified => 'Disqualified';

  @override
  String get recordNoIncidents => 'No warnings in this phase.';

  @override
  String get recordNoIncidentsLeague => 'No warnings in the league.';

  @override
  String recordWarningsLeague(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warnings in the league',
      one: '1 warning in the league',
      zero: 'No warnings in the league',
    );
    return '$_temp0';
  }

  @override
  String get recordIncidentsHint =>
      'Tap to see in which match, the minute and the reason.';

  @override
  String recordPhase(int number, String name) {
    return 'Phase $number · $name';
  }

  @override
  String get incidentWarning => 'Warning';

  @override
  String get incidentOneHand => 'One-hand warning';

  @override
  String get incidentOvertimePoint => 'Point after time';

  @override
  String incidentBy(String who) {
    return 'given by $who';
  }

  @override
  String get incidentGavePoint => '+1 to the rival';

  @override
  String leagueDisqualifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count disqualifications',
      one: '1 disqualification',
    );
    return '$_temp0';
  }

  @override
  String get recordRivalDisqualified => 'Rival disqualified';

  @override
  String get recordOpen => 'See matches';

  @override
  String get openLeague => 'Open the league';

  @override
  String podiumPreset(int gold, int silver, int bronze) {
    return '$gold gold · $silver silver · $bronze bronze';
  }

  @override
  String get podiumOther => 'Other';

  @override
  String podiumAsGeneral(String podium) {
    return 'As the general one ($podium)';
  }

  @override
  String get podiumOwn => 'Its own';

  @override
  String podiumLess(String metal) {
    return 'One less: $metal';
  }

  @override
  String podiumMore(String metal) {
    return 'One more: $metal';
  }

  @override
  String get leagueCategoryPodiumsHint =>
      'Most use the general one; pick \"Its own\" only where other medals are given.';

  @override
  String get warningReasonsTitle => 'Warning reasons';

  @override
  String get warningReasonsSportHint =>
      'The sport\'s. The referee picks one with a tap, or types another. Change the list for this event.';

  @override
  String get warningReasonsHint =>
      'This event\'s. The referee picks one with a tap, or types another.';

  @override
  String get warningReasonsAdd => 'New reason';

  @override
  String get warningReasonsAddButton => 'Add';

  @override
  String warningReasonsFull(int count) {
    return '$count reasons at most';
  }

  @override
  String warningReasonsRemove(String reason) {
    return 'Remove “$reason”';
  }

  @override
  String get warningReasonsUseSport => 'Back to the sport\'s';

  @override
  String get reasonPick => 'Pick the reason. It stays in the match history.';

  @override
  String get reasonOther => 'Other reason';

  @override
  String get invitationInvite => 'Invite';

  @override
  String get invitationHint =>
      'They get an email with a link. They sign in, or create their account, with that same email and accept. The link expires in 14 days.';

  @override
  String get invitationEmail => 'Email';

  @override
  String get invitationEmailInvalid => 'Write a valid email';

  @override
  String get invitationSend => 'Send invitation';

  @override
  String invitationSent(String email) {
    return 'Invitation sent to $email';
  }

  @override
  String get invitationPending => 'pending';

  @override
  String get invitationExpired => 'expired: invite again';

  @override
  String get invitationCancel => 'Cancel invitation';

  @override
  String get invitationCancelled => 'Invitation cancelled';

  @override
  String get staffRemove => 'Remove';

  @override
  String staffRemoveAs(String role) {
    return 'Remove as $role';
  }

  @override
  String staffRemoveTooltip(String name) {
    return 'Remove $name';
  }

  @override
  String staffRemoveConfirm(String name, String role) {
    return '$name is no longer a $role in this event. You can invite them again.';
  }

  @override
  String get staffRemoved => 'Removed from the event';

  @override
  String get staffErrorAlready => 'They already have that role in the event.';

  @override
  String get staffErrorTooSoon => 'Wait a minute before sending it again.';

  @override
  String get staffErrorTooMany => 'Too many pending invitations: cancel some.';

  @override
  String get staffErrorOnMat => 'Take them off their mat first.';

  @override
  String get invitationTitle => 'Invitation';

  @override
  String invitationFrom(String organizer, String role) {
    return '$organizer invites you as a $role to:';
  }

  @override
  String get invitationAccept => 'Accept';

  @override
  String get invitationAccepted => 'You are in the event';

  @override
  String invitationOtherEmail(String email) {
    return 'This invitation is for $email. Sign in with that account to accept it.';
  }

  @override
  String get invitationSwitchAccount => 'Sign in with another account';

  @override
  String get invitationInvalid =>
      'The invitation does not exist, was used or has expired. Ask the club to invite you again.';

  @override
  String get invitationVerifyFirst =>
      'Confirm your email first with the link we sent when you signed up.';

  @override
  String get leagueGlobalStandings => 'Global standings';

  @override
  String get leagueGlobalStandingsHint =>
      'Every category together in Scores and League. Off, one category at a time.';

  @override
  String get settingsMatHasGroups =>
      'That mat already has groups and keeps where they were played: it cannot be removed. If it is done, use \"Disable mat\" in the mats tab.';

  @override
  String get phaseNotStarted =>
      'The phase has not started yet: the club has to press \"Start phase\".';

  @override
  String get phaseNotStartedClub =>
      'The phase has not started yet: without it, no groups are created and nothing is refereed.';

  @override
  String get phaseInProgress => 'Phase in progress';

  @override
  String get phaseFinished => 'Phase finished: read only';

  @override
  String get phaseStart => 'Start phase';

  @override
  String get phaseFinish => 'Finish phase';

  @override
  String get phaseReopen => 'Reopen phase';

  @override
  String get phaseFinishTitle => 'Finish the phase?';

  @override
  String get phaseFinishBody =>
      'Nobody will be able to create groups, score or move matches. You can reopen it with a reason.';

  @override
  String phaseFinishPending(int count) {
    return '$count matches are left to play and will stay unplayed in the history. Nobody will be able to create groups, score or move matches. You can reopen it with a reason.';
  }

  @override
  String get phaseReopenTitle => 'Why do you reopen the phase?';

  @override
  String get phaseNotStartedError =>
      'The phase has not started: the club has to start it.';

  @override
  String get phaseFinishedError =>
      'The phase is finished: the club has to reopen it to change anything.';

  @override
  String get phaseMatchInProgressError =>
      'A match is in progress or waits for review: finish it first.';

  @override
  String permissionsTooltip(String name) {
    return 'Permissions of $name';
  }

  @override
  String permissionsTitle(String name) {
    return 'What $name may do';
  }

  @override
  String get permissionsHint =>
      'The club may always do everything. Reopening a phase and managing the staff are the club\'s alone.';

  @override
  String get permissionsSaved => 'Permissions saved';

  @override
  String get permissionGroups => 'Create and undo groups';

  @override
  String get permissionTeams => 'Form teams';

  @override
  String get permissionMeasures => 'Record weights and heights';

  @override
  String get permissionOwnMat => 'Referee their mat';

  @override
  String get permissionPhase => 'Start and finish the phase';

  @override
  String get permissionControl =>
      'Control panel: move groups and matches, reorder, skip the rest, disable mats';

  @override
  String get permissionReviews => 'Resolve matches in review';

  @override
  String get permissionDeviceImport => 'Import a device\'s actions (CSV)';

  @override
  String get permissionParticipants => 'Add and edit participants';

  @override
  String get eventStaffPanel => 'Event panel';

  @override
  String get staffPanelOnlyImport =>
      'From here you can import a device\'s actions with the button above.';

  @override
  String get permissionView => 'See groups, mats and matches (read only)';

  @override
  String get permissionsReadOnly =>
      'You can only look: the club has not let you change anything here.';

  @override
  String get qrAccessCreateHelper => 'Helper by QR';

  @override
  String qrAccessCreateReferee(int mat) {
    return 'Mat $mat referee by QR';
  }

  @override
  String get qrAccessHint =>
      'For someone helping without a Brackety account: type their name and let them scan the QR with their phone. They get in without signing up, only to this event and while the phase lasts.';

  @override
  String get qrAccessName => 'Full name';

  @override
  String get qrAccessCreate => 'Create QR';

  @override
  String get qrAccessPhaseFinished => 'The phase is over: no more QR access.';

  @override
  String get qrAccessTooMany => 'This event already has too many QR accesses.';

  @override
  String qrAccessCodeLabel(String name) {
    return 'Access QR for $name';
  }

  @override
  String get qrAccessScan =>
      'Let them scan it with their phone camera. It works once.';

  @override
  String get qrAccessWaiting => 'Waiting for them to sign in…';

  @override
  String qrAccessSignedIn(String name) {
    return '$name is in.';
  }

  @override
  String get qrAccessTitle => 'QR access';

  @override
  String get qrAccessSectionHint =>
      'Helpers and referees without an account. Each QR works once and for one phone: if they change phones, create a new one. They stop working when the phase ends.';

  @override
  String qrAccessMatsWithoutReferee(String mats) {
    return 'Mats without a referee: $mats. Use the QR next to each mat.';
  }

  @override
  String get qrAccessNoGrouper => 'Nobody but the club can create groups.';

  @override
  String qrAccessRefereeOf(int mat) {
    return 'Mat $mat referee';
  }

  @override
  String get qrAccessReferee => 'Referee';

  @override
  String get qrAccessHelper => 'Helper';

  @override
  String get qrAccessEnded => 'no access';

  @override
  String qrAccessSignedInAt(String time) {
    return 'signed in at $time';
  }

  @override
  String get qrAccessNotYet => 'not signed in yet';

  @override
  String get qrAccessRenew => 'New QR (signs them out)';

  @override
  String get qrAccessEnd => 'Remove access';

  @override
  String qrAccessEndConfirm(String name) {
    return '$name will no longer be able to sign in and will be signed out.';
  }

  @override
  String get qrAccessSignInTitle => 'Sign in with QR';

  @override
  String get qrAccessInvalid =>
      'This QR no longer works: ask the club for a new one.';

  @override
  String get qrAccessGoToLogin => 'Go to sign in';

  @override
  String get qrAccessReplaceSession =>
      'You are signing in with the club\'s QR. The session open on this device will end.';

  @override
  String get qrAccessEnter => 'Sign in';
}
