import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/group_draft.dart';

/// The group as 4 slots that fill as the helper picks: what is missing at a glance.
/// [labelOf] names a member (first name, "Team N"). Tapping a filled slot takes it out.
class DraftSlots extends StatelessWidget {
  const DraftSlots({
    super.key,
    required this.group,
    required this.labelOf,
    required this.onChanged,
    this.ghostTeamLabel,
  });

  final DraftGroup group;
  final String Function(String id) labelOf;

  /// Names a wildcard team ("Equipo 7", or its people); null: just "Comodín".
  final String Function(List<String> people)? ghostTeamLabel;
  final void Function(DraftGroup Function(DraftGroup group) change) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      spacing: AppSpacing.s,
      children: [
        for (var i = 0; i < DraftGroup.size; i++)
          Expanded(child: _slot(l10n, i)),
      ],
    );
  }

  Widget _slot(AppLocalizations l10n, int i) {
    final ghostSlot = group.ghostMode && i == DraftGroup.size - 1;
    if (i < group.members.length) {
      final id = group.members[i];
      return _Slot(
        label: labelOf(id),
        onTap: () => onChanged((g) => g.toggle(id, grouped: false)),
      );
    }
    final ghostIndex = i - group.members.length;
    if (ghostIndex < group.ghosts.length) {
      final ghost = group.ghosts[ghostIndex];
      return _Slot(
        label: l10n.ghostOf(labelOf(ghost)),
        ghost: true,
        onTap: () => onChanged((g) => g.toggle(ghost, grouped: false)),
      );
    }
    if (group.ofTeams && ghostIndex < group.ghostTeams.length) {
      final team = group.ghostTeams[ghostIndex];
      return _Slot(
        label: ghostTeamLabel == null
            ? l10n.ghostBadge
            : l10n.ghostOf(ghostTeamLabel!(team)),
        ghost: true,
        onTap: () => onChanged((g) => g.removeGhostTeam(ghostIndex)),
      );
    }
    return _Slot(
      label: ghostSlot ? l10n.ghostBadge : l10n.draftSlot(i + 1),
      empty: true,
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.label,
    this.ghost = false,
    this.empty = false,
    this.onTap,
  });

  final String label;
  final bool ghost;
  final bool empty;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (fill, onFill) = empty
        ? (Colors.transparent, scheme.onSurfaceVariant)
        : ghost
        ? (scheme.secondaryContainer, scheme.onSecondaryContainer)
        : (scheme.primary, scheme.onPrimary);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.m),
      side: empty
          ? BorderSide(color: scheme.outline, width: 2)
          : BorderSide.none,
    );
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: fill,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: AppSizes.touchTarget,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Center(
                child: Text(
                  label,
                  style: (empty ? text.bodySmall : text.titleSmall)?.copyWith(
                    color: onFill,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
