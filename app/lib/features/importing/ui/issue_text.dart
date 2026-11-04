import '../../../l10n/gen/app_localizations.dart';
import '../data/import_models.dart';

/// What the club reads for each problem the server found in a row.
String issueText(AppLocalizations l10n, RowIssue issue, CheckedRow row) {
  final field = switch (issue.field) {
    'firstName' => l10n.fieldFirstName,
    'lastName' => l10n.fieldLastName,
    'birthDate' => l10n.fieldBirthDate,
    'heightCm' => l10n.fieldHeight,
    _ => l10n.fieldCategory,
  };
  final detail = issue.detail ?? '';
  return switch (issue.code) {
    IssueCode.missing => l10n.issueMissing(field),
    IssueCode.tooLong => l10n.issueTooLong(field),
    IssueCode.invalidDate => l10n.issueInvalidDate(detail),
    IssueCode.futureDate => l10n.issueFutureDate,
    IssueCode.heightOutOfRange => l10n.issueHeight(detail),
    IssueCode.noCategory => l10n.issueNoCategory(detail),
    IssueCode.unknownCategory =>
      issue.detail == null
          ? l10n.issueChosenCategoryGone
          : l10n.issueUnknownCategory(detail),
    IssueCode.categoryMismatch => l10n.issueCategoryMismatch(
      row.indicatedCategoryName ?? detail,
      row.ageCategoryName ?? '',
    ),
    IssueCode.duplicateInList => l10n.issueDuplicate(detail),
    IssueCode.alreadyRegistered => l10n.issueAlreadyRegistered,
    IssueCode.unsure => l10n.issueUnsure(field),
  };
}
