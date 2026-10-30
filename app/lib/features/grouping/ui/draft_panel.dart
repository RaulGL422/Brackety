import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../core/group_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../state/group_draft.dart';

/// The groups being built: pick which one to fill, the ghost box and the create button.
class DraftPanel extends StatelessWidget {
  const DraftPanel({
    super.key,
    required this.draft,
    required this.busy,
    required this.onChanged,
    required this.onCreate,
  });

  final GroupDraft draft;
  final bool busy;

  /// Applies a change to the draft as it is when the tap lands, not as it was when built.
  final void Function(GroupDraft Function(GroupDraft draft) change) onChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final group = draft.currentGroup;
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
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (var i = 0; i < draft.groups.length; i++)
                    _GroupChip(
                      index: i,
                      group: draft.groups[i],
                      selected: i == draft.current,
                      onTap: () => onChanged((d) => d.select(i)),
                    ),
                  if (draft.maxGroups > 1)
                    ActionChip(
                      avatar: const Icon(Icons.add),
                      label: Text(l10n.draftAddGroup),
                      onPressed: draft.canAddGroup
                          ? () => onChanged((d) => d.addGroup())
                          : null,
                    ),
                  if (draft.groups.length > 1)
                    ActionChip(
                      avatar: const Icon(Icons.remove),
                      label: Text(l10n.draftRemoveGroup),
                      onPressed: () => onChanged((d) => d.removeCurrent()),
                    ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: group.ghostMode,
                title: Text(l10n.draftGhost),
                subtitle: group.choosingGhost
                    ? Text(l10n.draftGhostHint)
                    : null,
                onChanged: (on) =>
                    onChanged((d) => d.setGhostMode(on ?? false)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.touchTarget),
                ),
                onPressed: draft.isReady && !busy ? onCreate : null,
                child: Text(l10n.createGroup(draft.groups.length)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.index,
    required this.group,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final DraftGroup group;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = groupColor(index);
    final count = group.members.length + (group.ghost == null ? 0 : 1);
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: CircleAvatar(
        backgroundColor: color.color,
        foregroundColor: color.onColor,
        child: Text('${index + 1}'),
      ),
      label: Text('${l10n.draftGroup(index + 1)} · ${l10n.draftCount(count)}'),
    );
  }
}
