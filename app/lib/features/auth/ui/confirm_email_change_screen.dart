import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/api_error.dart';
import '../state/auth_providers.dart';
import 'widgets/auth_form_page.dart';
import 'widgets/form_message.dart';

/// Opened from the link sent to the new email: confirms at once, whatever the session.
class ConfirmEmailChangeScreen extends ConsumerWidget {
  const ConfirmEmailChangeScreen({super.key, this.token});

  final String? token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final token = this.token;
    return AuthFormPage(
      title: l10n.confirmEmailChangeTitle,
      children: [
        if (token == null || token.isEmpty)
          _Outcome(error: l10n.linkInvalid)
        else
          switch (ref.watch(confirmEmailChangeProvider(token))) {
            AsyncData() => _Outcome(success: l10n.confirmEmailChangeDone),
            AsyncError(:final DioException error)
                when ApiError.from(error).noResponse =>
              _Outcome(
                error: l10n.noServer,
                onRetry: () => ref.invalidate(confirmEmailChangeProvider),
              ),
            AsyncError() => _Outcome(error: l10n.linkInvalid),
            _ => const Center(child: CircularProgressIndicator()),
          },
      ],
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({this.success, this.error, this.onRetry});

  final String? success;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onRetry = this.onRetry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (success case final success?) FormMessage.success(success),
        if (error case final error?) FormMessage.error(error),
        const SizedBox(height: AppSpacing.l),
        if (onRetry != null)
          OutlinedButton(onPressed: onRetry, child: Text(l10n.retry))
        else
          // Signed out (the confirmation closes every session), "/" leads to the sign-in.
          FilledButton(
            onPressed: () => context.go('/'),
            child: Text(success != null ? l10n.goToLogin : l10n.continueAction),
          ),
      ],
    );
  }
}
