import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/session_controller.dart';
import 'widgets/auth_form_page.dart';
import 'widgets/resend_button.dart';

/// After signing up. The same answer whether or not the email already had an account.
class CheckEmailScreen extends ConsumerWidget {
  const CheckEmailScreen({super.key, this.email});

  /// Lost on a page reload; then there is nothing to resend to.
  final String? email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final email = this.email;
    return AuthFormPage(
      title: l10n.checkEmailTitle,
      children: [
        Text(l10n.checkEmailBody),
        if (email != null) ...[
          const SizedBox(height: AppSpacing.l),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ResendButton(
              send: () => ref.read(authApiProvider).resendVerification(email),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.l),
        FilledButton(
          onPressed: () => context.go('/login'),
          child: Text(l10n.goToLogin),
        ),
      ],
    );
  }
}
