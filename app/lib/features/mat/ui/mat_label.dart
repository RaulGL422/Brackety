import '../../../l10n/gen/app_localizations.dart';

/// "Tapiz 2", or "Tapices libres" for a team match or group in the pool (no mat yet).
String matLabel(AppLocalizations l10n, int? matNumber) =>
    matNumber == null ? l10n.matPool : l10n.matTitle(matNumber);
