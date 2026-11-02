import '../../../l10n/gen/app_localizations.dart';
import '../data/admin_api_error.dart';

/// The message for failures any admin call can get; screens handle their own cases first.
String adminErrorMessage(AppLocalizations l10n, AdminApiError error) {
  if (error.noResponse) return l10n.noServer;
  if (error.isLocked) return l10n.loginLocked(error.lockId!);
  if (error.isRateLimited) {
    final wait = error.retryAfter;
    return wait == null
        ? l10n.tooManyRequestsWait
        : l10n.tooManyRequests(wait.inSeconds);
  }
  return switch (error.status) {
    // Superadmin variables or Cloudflare Access missing on the server.
    503 => l10n.adminNotConfigured,
    // No valid Cloudflare Access header: opened outside the protected admin host.
    403 => l10n.adminAccessDenied,
    401 => l10n.sessionExpired,
    _ => l10n.unexpectedError,
  };
}

/// For a failed action on a signed-in page; null on a 401, where the router already goes to
/// the sign-in page with its own message.
String? actionErrorMessage(AppLocalizations l10n, AdminApiError error) =>
    error.status == 401 ? null : adminErrorMessage(l10n, error);

String loginErrorMessage(AppLocalizations l10n, AdminApiError error) =>
    error.status == 401 ? l10n.loginInvalid : adminErrorMessage(l10n, error);
