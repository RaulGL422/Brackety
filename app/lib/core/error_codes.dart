import 'package:dio/dio.dart';

import '../l10n/gen/app_localizations.dart';

/// What the server meant by the `code` of a refusal, in the user's language (L3 in
/// docs/producto/plan-limpieza.md). Null without a code, or with one this version does not know yet:
/// the caller then says something generic. A screen with a more precise text for a code checks it first.
///
/// Every code the server sends is here: ErrorCodesTranslatedTest (server) fails otherwise.
String? errorCodeMessage(AppLocalizations l10n, String? code) => switch (code) {
  'ALREADY_GROUPED' => l10n.errorAlreadyGrouped,
  'ALREADY_STAFF' => l10n.staffErrorAlready,
  'CATEGORY_AGES_INVERTED' => l10n.errorCategoryAgesInverted,
  'CATEGORY_AGES_OVERLAP' => l10n.errorCategoryAgesOverlap,
  'CATEGORY_IN_USE' => l10n.errorCategoryInUse,
  'CATEGORY_ONLY_NAME' => l10n.errorCategoryOnlyName,
  'CONSENT_REQUIRED' => l10n.errorConsentRequired,
  'DATE_LOCKED' => l10n.errorDateLocked,
  'EXPORT_FILTER_NOT_A_NUMBER' => l10n.errorExportFilterNotANumber,
  'EXPORT_REPEATED_COLUMN' => l10n.errorExportRepeatedColumn,
  'EXPORT_UNKNOWN_COLUMN' => l10n.errorExportUnknownColumn,
  'EXPORT_UNKNOWN_SHEET' => l10n.errorExportUnknownSheet,
  'FIGHTER_BUSY' => l10n.reviewReasonFighterBusy,
  'FIGHTER_RESTING' => l10n.errorFighterResting,
  'GROUP_SIZE' => l10n.errorGroupSize,
  'GROUP_SIZE_INVERTED' => l10n.errorGroupSizeInverted,
  'GROUP_STARTED' => l10n.controlGroupStarted,
  'GUARDIAN_CONSENT_REQUIRED' => l10n.errorGuardianConsentRequired,
  'IMPORT_FILE_COUNT' => l10n.errorImportFileCount,
  'IMPORT_FILE_SIZE' => l10n.errorImportFileSize,
  'IMPORT_FILE_TYPE' => l10n.errorImportFileType,
  'IMPORT_TOO_MANY_ROWS' => l10n.errorImportTooManyRows,
  'INVITATION_OTHER_EMAIL' => l10n.errorInvitationOtherEmail,
  'INVITATION_TOO_SOON' => l10n.staffErrorTooSoon,
  'KNOWN_EVENTS' => l10n.errorMatchStale,
  'LEGAL_GATE' => l10n.legalGateError,
  'LENGTH_LOCKED' => l10n.errorLengthLocked,
  'MATCH_IN_PROGRESS' => l10n.phaseMatchInProgressError,
  'MATCH_IN_REVIEW' => l10n.controlMatInReview,
  'MATCH_NOT_IN_REVIEW' => l10n.errorMatchNotInReview,
  'MATCH_NOT_PENDING' => l10n.controlMatchNotPending,
  'MATCH_STALE' => l10n.errorMatchStale,
  'MAT_BUSY' => l10n.controlMatBusy,
  'MAT_DISABLED' => l10n.controlMatIsDisabled,
  'MAT_HAS_GROUPS' => l10n.settingsMatHasGroups,
  'MAT_HAS_INDIVIDUAL' => l10n.errorMatHasIndividual,
  'MAT_HAS_MATCHES' => l10n.settingsMatNeedsReferee,
  'MAT_NOT_DISABLED' => l10n.controlMatNotDisabled,
  'MEASURES_MISSING' => l10n.measuresMissingError,
  'NO_OTHER_MAT' => l10n.controlNoOtherMat,
  'NO_REFEREE_ON_MATS' => l10n.errorNoRefereeOnMats,
  'ORDER_CHANGED' => l10n.controlOrderChanged,
  'ORGANIZATION_DUPLICATE' => l10n.errorOrganizationDuplicate,
  'ORGANIZATION_IN_USE' => l10n.errorOrganizationInUse,
  'PARTICIPANT_IN_GROUP' => l10n.errorParticipantInGroup,
  'PARTICIPANT_LOCKED' => l10n.errorParticipantLocked,
  'PHASE_ALREADY_STARTED' => l10n.errorPhaseAlreadyStarted,
  'PHASE_FINISHED' => l10n.phaseFinishedError,
  'PHASE_NOT_FINISHED' => l10n.errorPhaseNotFinished,
  'PHASE_NOT_STARTED' => l10n.phaseNotStartedError,
  'PODIUM_TWICE' => l10n.errorPodiumTwice,
  'POINTS_LIMIT_LOCKED' => l10n.errorPointsLimitLocked,
  'REENROL_INVALID' => l10n.errorReenrolInvalid,
  'REFEREE_GONE' => l10n.errorRefereeGone,
  'REFEREE_ON_MAT' => l10n.staffErrorOnMat,
  'REFEREE_ON_OTHER_MAT' => l10n.controlMatRefereeTaken,
  'REFEREE_WITHOUT_MAT' => l10n.errorRefereeWithoutMat,
  'RESULTS_CONFLICT' => l10n.importResultsConflict,
  'RESULTS_OTHER_EVENT' => l10n.importResultsOtherEvent,
  'RETURN_LEG_IN_USE' => l10n.categoryReturnLegInUse,
  'RULEBOOK_NOT_PDF' => l10n.errorRulebookNotPdf,
  'RULEBOOK_TOO_LARGE' => l10n.errorRulebookTooLarge,
  'RULES' => l10n.reviewReasonRules,
  'SAME_FIGHTER' => l10n.controlSameFighter,
  'TEAM_ALREADY_GROUPED' => l10n.errorTeamAlreadyGrouped,
  'TEAM_IN_GROUP' => l10n.errorTeamInGroup,
  'TEAM_SIZE' => l10n.controlTeamSize,
  'TOO_MANY_INVITATIONS' => l10n.staffErrorTooMany,
  'TOO_MANY_QR_ACCESSES' => l10n.qrAccessTooMany,
  _ => null,
};

/// [errorCodeMessage] for a failed call, or [fallback] (the screen's usual answer) when it has none.
String errorMessage(
  AppLocalizations l10n,
  DioException error,
  String fallback,
) {
  final body = error.response?.data;
  final code = body is Map ? body['code'] : null;
  return errorCodeMessage(l10n, code is String ? code : null) ?? fallback;
}
