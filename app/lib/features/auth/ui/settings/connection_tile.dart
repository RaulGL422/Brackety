import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/account_controller.dart';

/// The Connection screen, at the end of the settings and only for support and debug
/// ([connectionAllowedProvider]): which server, its version and its day. Nothing for customers.
class ConnectionTile extends ConsumerWidget {
  const ConnectionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(connectionAllowedProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final tile = ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.dns_outlined),
      title: Text(l10n.navConnection),
      subtitle: Text(l10n.connectionSupportHint),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/connection'),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: tile,
    );
  }
}
