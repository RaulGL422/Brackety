import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/admin_session.dart';

/// App bar action; hidden on the pages open without a session (connection, design system).
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(adminSessionProvider.select((s) => s.signedIn));
    if (!signedIn) return const SizedBox.shrink();
    return IconButton(
      tooltip: AppLocalizations.of(context).logout,
      icon: const Icon(Icons.logout),
      onPressed: () => ref.read(adminSessionProvider.notifier).logout(),
    );
  }
}
