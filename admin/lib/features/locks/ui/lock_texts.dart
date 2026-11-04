import '../../../l10n/gen/app_localizations.dart';
import '../data/locks_api.dart';

String lockTypeName(AppLocalizations l10n, LockType type) => switch (type) {
  LockType.email => l10n.lockTypeEmail,
  LockType.ip => l10n.lockTypeIp,
  LockType.admin => l10n.lockTypeAdmin,
};

/// The account's email or the IP; an email lock without account has neither.
String lockTarget(AppLocalizations l10n, Lock lock) =>
    lock.email ?? lock.ip ?? l10n.lockUnknownEmail;

/// "12 min left · until 14:32"; minutes round up, so "1 min" until the very end.
String lockTimeLeft(AppLocalizations l10n, Lock lock, DateTime now) {
  final left = lock.lockedUntil.difference(now);
  if (left <= Duration.zero) return l10n.lockExpired;
  final minutes = (left.inSeconds / 60).ceil();
  return '${l10n.lockMinutesLeft(minutes)} · '
      '${l10n.lockUntil(lock.lockedUntil.toLocal())}';
}
