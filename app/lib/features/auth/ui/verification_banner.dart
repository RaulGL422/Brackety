import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/session_controller.dart';
import 'widgets/resend_button.dart';

/// Above every screen while signed in with an unverified email. It does not block: the server
/// refuses what needs a verified email.
class VerificationBanner extends ConsumerWidget {
  const VerificationBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
      sessionProvider.select(
        (s) => s.status == SessionStatus.signedIn && !s.emailVerified,
      ),
    );
    if (!pending) return child;
    return Column(
      // Edge to edge: centred, the banner would shrink to its content.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Banner(),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Banner extends ConsumerWidget {
  const _Banner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BracketyColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: colors.warningContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: colors.onWarningContainer),
            child: OutlinedButtonTheme(
              data: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.onWarningContainer,
                  side: BorderSide(color: colors.onWarningContainer),
                ),
              ),
              child: Wrap(
                spacing: AppSpacing.m,
                runSpacing: AppSpacing.s,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l10n.verifyBanner),
                  ResendButton(
                    send: ref.read(sessionProvider.notifier).resendVerification,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
