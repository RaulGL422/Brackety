import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/server_choice.dart';
import '../state/server_providers.dart';
import 'server_dialog.dart';
import 'server_texts.dart';

/// The sign-in's server line, Android only: the one place to switch servers, so never with a
/// session open.
class ServerTile extends ConsumerWidget {
  const ServerTile({super.key});

  Future<void> _change(BuildContext context, WidgetRef ref) async {
    final url = await showDialog<String>(
      context: context,
      builder: (_) => ServerDialog(current: ref.read(serverProvider)),
    );
    if (url != null) await ref.read(serverProvider.notifier).select(url);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(serverSelectableProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final url = ref.watch(serverProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.dns_outlined),
      title: Text(l10n.serverCurrent(serverOptionName(l10n, optionOf(url)))),
      subtitle: Text(url),
      trailing: TextButton(
        onPressed: () => _change(context, ref),
        child: Text(l10n.serverChange),
      ),
    );
  }
}
