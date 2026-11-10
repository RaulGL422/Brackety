import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../features/auth/data/admin_api_error.dart';
import '../features/auth/ui/admin_texts.dart';
import '../l10n/gen/app_localizations.dart';

/// Runs an operation and says how it went in a snackbar: [done] on success, the reason on failure.
/// A 404 means someone changed the page's data meanwhile: [notFound] says so (the caller reloads).
/// [explain] gives the page's own message for an error it knows (null: the general one).
Future<void> runAction<T>(
  BuildContext context,
  Future<T> Function() action, {
  required String Function(T result) done,
  required String notFound,
  String? Function(AdminApiError error)? explain,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  String? message;
  try {
    message = done(await action());
  } on DioException catch (e) {
    final error = AdminApiError.from(e);
    message = error.status == 404
        ? notFound
        : explain?.call(error) ?? actionErrorMessage(l10n, error);
  }
  if (message != null) messenger.showSnackBar(SnackBar(content: Text(message)));
}
