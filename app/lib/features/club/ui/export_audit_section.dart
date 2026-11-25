import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/club_providers.dart';

/// Who downloaded personal data, when and which columns (docs/producto/exportaciones.md); the files are not kept.
class ExportAuditSection extends ConsumerWidget {
  const ExportAuditSection({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final when = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .add_Hm();
    final entries = ref.watch(exportAuditProvider(eventId)).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.exportAuditTitle, style: text.titleMedium),
        Text(l10n.exportAuditHint, style: text.bodySmall),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: Text(l10n.exportAuditEmpty),
          ),
        for (final e in entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.shield_outlined),
            title: Text(
              '${e.account} · ${when.format(e.at.toLocal())}',
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${e.sheet}: ${e.columns}'),
          ),
      ],
    );
  }
}
