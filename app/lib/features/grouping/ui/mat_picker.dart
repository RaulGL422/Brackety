import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../club/data/club_models.dart';
import '../../club/state/club_providers.dart';

/// Where the next group goes: "Automatic" (the mat free first, chosen by the server) or a mat
/// with a referee. Mats without one are listed but cannot be picked.
class MatPicker extends ConsumerWidget {
  const MatPicker({
    super.key,
    required this.eventId,
    required this.matId,
    required this.onChanged,
  });

  final String eventId;

  /// Null = automatic.
  final String? matId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mats = ref.watch(matsOverviewProvider(eventId)).value ?? const [];
    // A mat that disappeared (removed by the club) falls back to automatic.
    final value = mats.any((m) => m.id == matId) ? matId : null;
    return DropdownButtonFormField<String?>(
      // The field keeps its own value: a new key shows the parent's (back to automatic after
      // creating a group, or once the mats load).
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.matPickerLabel),
      selectedItemBuilder: (_) => [
        _Selected(icon: Icons.auto_mode, label: l10n.matAuto),
        for (final m in mats)
          _Selected(icon: Icons.place_outlined, label: l10n.matTitle(m.number)),
      ],
      items: [
        DropdownMenuItem(
          value: null,
          child: _Option(title: l10n.matAuto, subtitle: l10n.matAutoOption),
        ),
        for (final m in mats)
          DropdownMenuItem(
            value: m.id,
            enabled: m.referee != null,
            child: _Option(
              title: l10n.matTitle(m.number),
              subtitle: _detail(l10n, m),
              enabled: m.referee != null,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }

  String _detail(AppLocalizations l10n, MatOverview mat) => mat.referee == null
      ? l10n.matNoReferee
      : '${mat.referee} · ${l10n.matSummary(mat.groups, mat.pendingMatches)}';
}

/// One line under the button saying where the group will go.
class MatPickerHint extends ConsumerWidget {
  const MatPickerHint({super.key, required this.eventId, required this.matId});

  final String eventId;
  final String? matId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mats = ref.watch(matsOverviewProvider(eventId)).value ?? const [];
    final mat = mats.where((m) => m.id == matId).firstOrNull;
    return Text(
      mat == null
          ? l10n.matAutoHint
          : l10n.matManualHint(l10n.matTitle(mat.number)),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

/// The picked option inside the field: a small icon so the label keeps room on a phone.
class _Selected extends StatelessWidget {
  const _Selected({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: IconTheme.of(context).size! * 0.8),
      const SizedBox(width: AppSpacing.xs),
      Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
    ],
  );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.subtitle,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final disabled = Theme.of(context).disabledColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: enabled
              ? text.bodyLarge
              : text.bodyLarge?.copyWith(color: disabled),
        ),
        Text(
          subtitle,
          style: enabled
              ? text.bodySmall
              : text.bodySmall?.copyWith(color: disabled),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
