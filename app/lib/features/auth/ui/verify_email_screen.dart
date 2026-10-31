import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/api_error.dart';
import '../state/auth_providers.dart';
import '../state/session_controller.dart';
import 'widgets/auth_form_page.dart';
import 'widgets/form_message.dart';
import 'widgets/resend_button.dart';

/// Opened from the email link: verifies at once.
class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key, this.token});

  final String? token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final token = this.token;
    return AuthFormPage(
      title: l10n.verifyTitle,
      children: [
        if (token == null || token.isEmpty)
          const _InvalidLink()
        else
          switch (ref.watch(verifyEmailProvider(token))) {
            AsyncData() => _Verified(),
            AsyncError(:final DioException error)
                when ApiError.from(error).noResponse =>
              _NoServer(onRetry: () => ref.invalidate(verifyEmailProvider)),
            AsyncError() => const _InvalidLink(),
            _ => const Center(child: CircularProgressIndicator()),
          },
      ],
    );
  }
}

class _Verified extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormMessage.success(l10n.verifySuccess),
        const SizedBox(height: AppSpacing.l),
        // Signed out, the router sends "/" to the sign-in.
        FilledButton(
          onPressed: () => context.go('/'),
          child: Text(l10n.continueAction),
        ),
      ],
    );
  }
}

class _NoServer extends StatelessWidget {
  const _NoServer({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormMessage.error(l10n.noServer),
        const SizedBox(height: AppSpacing.l),
        OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}

class _InvalidLink extends ConsumerWidget {
  const _InvalidLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final signedIn = ref.watch(
      sessionProvider.select((s) => s.status == SessionStatus.signedIn),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormMessage.error(l10n.linkInvalid),
        const SizedBox(height: AppSpacing.l),
        if (signedIn)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ResendButton(
              send: ref.read(sessionProvider.notifier).resendVerification,
            ),
          )
        else
          FilledButton(
            onPressed: () => context.go('/login'),
            child: Text(l10n.goToLogin),
          ),
      ],
    );
  }
}
