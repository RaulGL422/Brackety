import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../core/table_line.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/organizers_api.dart';

/// Column widths of the desktop table: name, CIF, type, email, joined, state, action.
const organizerColumns = [3, 2, 2, 3, 2, 2, 2];

List<String> organizerColumnLabels(AppLocalizations l10n) => [
  l10n.organizerColumnName,
  l10n.organizerColumnTaxId,
  l10n.organizerColumnType,
  l10n.organizerColumnEmail,
  l10n.organizerColumnCreated,
  l10n.organizerColumnState,
  '',
];

String organizerTypeName(AppLocalizations l10n, OrganizerType type) =>
    switch (type) {
      OrganizerType.club => l10n.organizerClub,
      OrganizerType.externalEntity => l10n.organizerExternalEntity,
    };

/// A table row on wide windows, a card on phones and tablets.
class OrganizerTile extends StatelessWidget {
  const OrganizerTile({
    super.key,
    required this.organizer,
    required this.onValidate,
  });

  final Organizer organizer;
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
    final state = _StateChip(validated: organizer.validated);

    if (WindowSize.of(context) == WindowSize.expanded) {
      return TableLine(
        flexes: organizerColumns,
        cells: [
          _Name(organizer.organizationName),
          SelectableText(taxId ?? l10n.organizerNoTaxId),
          Text(organizerTypeName(l10n, organizer.type)),
          SelectableText(organizer.email),
          Text(l10n.organizerDate(organizer.createdAt.toLocal())),
          state,
          validate ?? const SizedBox.shrink(),
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
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [state, ?validate],
            ),
          ],
        ),
      ),
    );
  }
}

/// Organizers created before the sign-up asked for it have no name: says so instead of a blank.
class _Name extends StatelessWidget {
  const _Name(this.name, {this.large = false});

  final String? name;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = large ? theme.textTheme.titleMedium : null;
    final name = this.name;
    if (name != null) return Text(name, style: style);
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
