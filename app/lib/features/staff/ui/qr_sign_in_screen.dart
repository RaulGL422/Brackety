import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/api_error.dart';
import '../../auth/state/account_controller.dart';
import '../../auth/state/session_controller.dart';
import '../../auth/ui/widgets/auth_form_page.dart';
import '../../auth/ui/widgets/auth_note.dart';
import '../../auth/ui/widgets/form_message.dart';

/// Where a club's QR leads: signs in to the temporary account at once, with no account of one's
/// own. Already signed in with another account, it asks first: that session ends.
class QrSignInScreen extends ConsumerStatefulWidget {
  const QrSignInScreen({super.key, this.code});

  final String? code;

  @override
  ConsumerState<QrSignInScreen> createState() => _QrSignInScreenState();
}

class _QrSignInScreenState extends ConsumerState<QrSignInScreen> {
  var _signingIn = false;
  var _started = false;
  String? _error;

  Future<void> _signIn() async {
    final code = widget.code;
    if (code == null || code.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _signingIn = true;
      _error = null;
    });
    final session = ref.read(sessionProvider.notifier);
    try {
      if (ref.read(sessionProvider).status == SessionStatus.signedIn) {
        await session.logout();
      }
      await session.signInWithQr(code);
      if (mounted) context.go('/');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _signingIn = false;
        _error = ApiError.from(e).noResponse
            ? l10n.noServer
            : l10n.qrAccessInvalid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(sessionProvider.select((s) => s.status));
    final code = widget.code;
    // Signed out: straight in, nothing to ask.
    if (status == SessionStatus.signedOut && !_started && code != null) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _signIn());
    }
    return AuthFormPage(
      title: l10n.qrAccessSignInTitle,
      children: [
        if (code == null || code.isEmpty)
          FormMessage.error(l10n.qrAccessInvalid)
        else if (_error != null) ...[
          FormMessage.error(_error!),
          const SizedBox(height: AppSpacing.l),
          OutlinedButton(
            onPressed: () => context.go('/login'),
            child: Text(l10n.qrAccessGoToLogin),
          ),
        ] else if (status == SessionStatus.signedIn && !_signingIn) ...[
          Text(switch (ref.watch(accountProvider).value?.email) {
            final email? => l10n.qrAccessOpenSession(email),
            null => l10n.qrAccessOpenSessionUnnamed,
          }),
          const SizedBox(height: AppSpacing.l),
          AuthNote(
            title: l10n.qrAccessIfYouEnter,
            items: [l10n.qrAccessEndsSession, l10n.qrAccessOnlyEvent],
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: _signIn, child: Text(l10n.qrAccessEnter)),
          const SizedBox(height: AppSpacing.s),
          TextButton(
            onPressed: () => context.go('/'),
            child: Text(l10n.qrAccessKeepSession),
          ),
        ] else
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
