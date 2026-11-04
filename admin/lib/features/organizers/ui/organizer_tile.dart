import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../core/table_line.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/organizers_api.dart';

/// Column widths of the desktop table: name, CIF, type, email, joined, state with its action.
const organizerColumns = [3, 2, 2, 4, 2, 4];

List<String> organizerColumnLabels(AppLocalizations l10n) => [
  l10n.organizerColumnName,
  l10n.organizerColumnTaxId,
  l10n.organizerColumnType,
  l10n.organizerColumnEmail,
  l10n.organizerColumnCreated,
  l10n.organizerColumnState,
];

String organizerTypeName(AppLocalizations l10n, OrganizerType type) =>
    switch (type) {
      OrganizerType.club => l10n.organizerClub,
      OrganizerType.externalEntity => l10n.organizerExternalEntity,
    };

/// A table row when [table], else a card.
class OrganizerTile extends StatelessWidget {
  const OrganizerTile({
    super.key,
    required this.organizer,
    required this.table,
    required this.onValidate,
  });

  final Organizer organizer;
  final bool table;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final taxId = organizer.taxId;
    final validate = organizer.validated
        ? null
        : FilledButton.tonal(
            onPressed: onValidate,
            child: Text(l10n.organizerValidate),
          );
    // The button goes under the chip when they do not fit side by side, never over it.
    final state = Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StateChip(validated: organizer.validated),
        ?validate,
      ],
    );

    if (table) {
      return TableLine(
        flexes: organizerColumns,
        cells: [
          _Name(organizer.organizationName, oneLine: true),
          OneLineText(taxId ?? l10n.organizerNoTaxId),
          Text(organizerTypeName(l10n, organizer.type)),
          OneLineText(organizer.email),
          Text(l10n.organizerDate(organizer.createdAt.toLocal())),
          state,
        ],
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Name(organizer.organizationName, large: true),
            Text(l10n.organizerTaxId(taxId ?? l10n.organizerNoTaxId)),
            Text(organizerTypeName(l10n, organizer.type)),
            SelectableText(organizer.email),
            Text(l10n.organizerCreated(organizer.createdAt.toLocal())),
            const SizedBox(height: AppSpacing.s),
            state,
          ],
        ),
      ),
    );
  }
}

/// Organizers created before the sign-up asked for it have no name: says so instead of a blank.
class _Name extends StatelessWidget {
  const _Name(this.name, {this.large = false, this.oneLine = false});

  final String? name;
  final bool large;

  /// In the table: one line with an ellipsis, like the other long values.
  final bool oneLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = large ? theme.textTheme.titleMedium : null;
    final name = this.name;
    if (name != null) {
      return oneLine
          ? OneLineText(name, style: style)
          : Text(name, style: style);
    }
    return Text(
      AppLocalizations.of(context).organizerNoData,
      style: (style ?? const TextStyle()).copyWith(
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Icon and text, not colour alone.
class _StateChip extends StatelessWidget {
  const _StateChip({required this.validated});

  final bool validated;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Chip(
      avatar: Icon(
        validated ? Icons.verified_outlined : Icons.hourglass_empty,
        color: validated
            ? BracketyColors.of(context).success
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: Text(validated ? l10n.organizerValidated : l10n.organizerPending),
    );
  }
}
