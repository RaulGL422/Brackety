import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/core_localizations.dart';
import '../config/api_config.dart';
import '../theme/brackety_colors.dart';
import '../theme/tokens.dart';
import 'server_info.dart';

/// Shows which backend this build talks to and the server's "today" (shifted in local scenario runs).
class ConnectionScreen extends ConsumerWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = CoreLocalizations.of(context);
    final info = ref.watch(serverInfoProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        Text(
          l10n.connectionTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.l),
        ListTile(
          leading: const Icon(Icons.dns_outlined),
          title: Text(l10n.connectionServer),
          subtitle: SelectableText(apiBaseUrl),
        ),
        switch (info) {
          AsyncData(:final value) => _StatusTile(
            ok: true,
            title: l10n.connectionStatusOk,
            subtitle: l10n.connectionServerToday(value.today),
          ),
          AsyncError() => _StatusTile(
            ok: false,
            title: l10n.connectionStatusError,
            trailing: TextButton(
              onPressed: () => ref.invalidate(serverInfoProvider),
              child: Text(l10n.retry),
            ),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(l10n.licenses),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(context: context),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.ok,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final bool ok;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        ok ? Icons.check_circle_outline : Icons.error_outline,
        color: ok ? BracketyColors.of(context).success : colors.error,
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
    );
  }
}
