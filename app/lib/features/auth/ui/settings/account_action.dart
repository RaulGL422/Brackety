import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../data/api_error.dart';
import '../../state/reauth.dart';
import '../auth_texts.dart';

/// What to tell the user after a failed settings action; null when there is nothing to say
/// (they cancelled the password dialog).
String? accountErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ReauthCancelled) return null;
  if (error is ReauthNeedsGoogle) return l10n.needsGoogle;
  if (error is! DioException) return l10n.unexpectedError;
  final api = ApiError.from(error);
  // Adding a profile is the only call here that needs a verified email; its 403 carries no code.
  if (api.code == 'EMAIL_NOT_VERIFIED' ||
      (api.status == 403 && api.code == null)) {
    return l10n.profileNeedsVerifiedEmail;
  }
  return switch (api.code) {
    'LAST_PROFILE' => l10n.profileLast,
    'PROFILE_COMBINATION_NOT_ALLOWED' => l10n.profileCombination,
    'OWNS_EVENTS' => l10n.deleteOwnsEvents,
    'LAST_SIGN_IN_METHOD' => l10n.lastSignInMethod,
    _ => apiErrorMessage(l10n, api),
  };
}

/// Runs a settings action and tells the outcome in a snackbar: [done] on success, the reason on failure.
Future<void> runAccountAction(
  BuildContext context,
  Future<void> Function() action, {
  String? done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  String? message;
  try {
    await action();
    message = done;
  } on Exception catch (e) {
    message = accountErrorMessage(l10n, e);
  }
  if (message != null) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
