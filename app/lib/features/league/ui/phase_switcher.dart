import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../events/state/events_providers.dart';

/// Moves the club panel between the phases of its league; hidden while the league has only one.
class PhaseSwitcher extends ConsumerWidget {
  const PhaseSwitcher({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final phases = ref.watch(clubPhasesProvider(eventId)).value ?? const [];
    if (phases.length < 2) return const SizedBox.shrink();
    final current = phases.firstWhere((p) => p.id == eventId);
    return PopupMenuButton<String>(
      tooltip: l10n.leagueSwitchPhase,
      initialValue: eventId,
      onSelected: (id) => context.go('/events/$id/club'),
      itemBuilder: (_) => [
        for (final p in phases) PopupMenuItem(value: p.id, child: Text(p.name)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.phaseNumber(current.phaseNumber),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
