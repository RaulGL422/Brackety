import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/group_draft.dart';
import 'mat_picker.dart';

/// The group being built: the ghost box, the create button and the mat it goes to.
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

  /// Opens the ghost team picker; only for groups of teams.
  final VoidCallback? onPickGhostTeam;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: group.ghostMode,
                title: Text(
                  group.ofTeams ? l10n.draftGhostTeam : l10n.draftGhost,
                ),
                subtitle: group.choosingGhost
                    ? Text(l10n.draftGhostHint)
                    : group.ofTeams && group.ghostMode
                    ? Text(l10n.draftGhostTeamHint(group.ghostTeamSize!))
                    : null,
                onChanged: (on) =>
                    onChanged((g) => g.setGhostMode(on ?? false)),
              ),
              if (group.ofTeams &&
                  group.ghostMode &&
                  group.members.length == DraftGroup.size - 1) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSizes.touchTarget),
                  ),
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: Text(
                    l10n.pickGhostTeam(
                      group.ghostTeam.length,
                      group.ghostTeamSize!,
                    ),
                  ),
                  onPressed: onPickGhostTeam,
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSizes.touchTarget,
                        ),
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
              const SizedBox(height: AppSpacing.xs),
              MatPickerHint(eventId: eventId, matId: matId),
            ],
          ),
        ),
      ),
    );
  }
}
