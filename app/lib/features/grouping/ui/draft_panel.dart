import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/group_draft.dart';
import 'draft_slots.dart';
import 'mat_picker.dart';

/// The group being built: its slots, the ghost box, the create button and the mat it goes to.
class DraftPanel extends StatelessWidget {
  const DraftPanel({
    super.key,
    required this.eventId,
    required this.group,
    required this.matId,
    required this.busy,
    required this.onChanged,
    required this.onMatChanged,
    required this.onCreate,
    required this.labelOf,
    this.onPickGhostTeam,
  });

  final String eventId;
  final DraftGroup group;

  /// Null = automatic.
  final String? matId;
  final bool busy;

  /// Applies a change to the group as it is when the tap lands, not as it was when built.
  final void Function(DraftGroup Function(DraftGroup group) change) onChanged;
  final ValueChanged<String?> onMatChanged;
  final VoidCallback onCreate;
  final String Function(String id) labelOf;

  /// Opens the ghost team picker; only for groups of teams.
  final VoidCallback? onPickGhostTeam;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hint = !group.ofTeams && group.ghostMode && !group.isComplete
        ? l10n.draftGhostHint
        : group.ofTeams && group.ghostMode
        ? l10n.draftGhostTeamHint(DraftGroup.maxTeam)
        : group.ofTeams
        ? l10n.teamGroupPoolHint
        : null;
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: Border(top: BorderSide(color: scheme.outlineVariant)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.s,
            children: [
              Row(
                spacing: AppSpacing.s,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: l10n.draftTitle,
                            style: text.titleMedium,
                          ),
                          TextSpan(
                            text: '  ${_status(l10n)}',
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FilterChip(
                    label: Text(
                      group.ofTeams ? l10n.draftGhostTeam : l10n.draftGhost,
                    ),
                    selected: group.ghostMode,
                    // With 4 picked there is no room for a ghost: turning it on would make the 4th one
                    // the ghost, and off again would drop them.
                    onSelected: group.canToggleGhost
                        ? (on) => onChanged((g) => g.setGhostMode(on))
                        : null,
                  ),
                ],
              ),
              DraftSlots(group: group, labelOf: labelOf, onChanged: onChanged),
              if (hint != null)
                Text(
                  hint,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              if (group.canAddGhostTeam)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSizes.touchTarget),
                  ),
                  icon: const Icon(Icons.group_add_outlined),
                  label: Text(l10n.addGhostTeam),
                  onPressed: onPickGhostTeam,
                ),
              // A group of teams has no mat: its matches go to the free mats.
              if (group.ofTeams)
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: group.isComplete && !busy ? onCreate : null,
                  child: Text(l10n.createGroup(1)),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: group.isComplete && !busy ? onCreate : null,
                        child: Text(l10n.createGroup(1)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: MatPicker(
                        eventId: eventId,
                        matId: matId,
                        onChanged: onMatChanged,
                      ),
                    ),
                  ],
                ),
                MatPickerHint(eventId: eventId, matId: matId),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _status(AppLocalizations l10n) {
    final ghosts = group.ofTeams
        ? (group.ghostMode ? group.ghostTeams.length : 0)
        : group.ghosts.length;
    final missing = DraftGroup.size - group.members.length - ghosts;
    return missing == 0 ? l10n.draftReady : l10n.draftMissing(missing);
  }
}
