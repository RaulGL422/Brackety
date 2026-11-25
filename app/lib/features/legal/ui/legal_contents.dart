import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/legal_repository.dart';
import '../data/legal_structure.dart';
import 'legal_links.dart';

/// «En esta página»: the sections of a legal text, each one tap from its place. On a phone it
/// folds (open at first); on a desktop it stays beside the text and marks the one being read.
class LegalContents extends StatelessWidget {
  const LegalContents({
    super.key,
    required this.sections,
    required this.onSelected,
    this.current,
    this.folding = false,
  });

  final List<LegalSection> sections;
  final ValueChanged<int> onSelected;

  /// The section being read, marked; none on a phone, where the list is out of view by then.
  final ValueListenable<int?>? current;
  final bool folding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final heading = Text(
      l10n.legalContents,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    );
    Widget entries(int? selected) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++)
          _Entry(
            section: sections[i],
            selected: i == selected,
            ruled: folding,
            onPressed: () => onSelected(i),
          ),
      ],
    );
    final current = this.current;
    final list = current == null
        ? entries(null)
        : ValueListenableBuilder(
            valueListenable: current,
            builder: (context, selected, _) => entries(selected),
          );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.legalContents,
      child: folding
          ? ExpansionTile(
              initiallyExpanded: true,
              tilePadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              title: heading,
              children: [list],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading,
                const SizedBox(height: AppSpacing.s),
                list,
              ],
            ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.section,
    required this.selected,
    required this.ruled,
    required this.onPressed,
  });

  final LegalSection section;
  final bool selected;

  /// A line under each entry, as a list on a phone.
  final bool ruled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? BracketyColors.of(context).action
        : theme.colorScheme.onSurface;
    final button = TextButton(
      style: TextButton.styleFrom(
        alignment: AlignmentDirectional.centerStart,
        foregroundColor: color,
        minimumSize: const Size(48, 44),
        padding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        textStyle: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
        ),
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              section.number ?? '',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 19,
                color: color,
              ),
            ),
          ),
          Expanded(child: Text(section.title)),
        ],
      ),
    );
    return Semantics(
      selected: selected,
      child: ruled
          ? DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: button,
            )
          : button,
    );
  }
}

/// The other legal texts, as a quiet list at the end (Raul, 2026-11-25: not three big buttons).
class LegalOtherDocuments extends StatelessWidget {
  const LegalOtherDocuments({super.key, required this.current});

  final LegalDocumentType current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.legalOtherTexts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.legalOtherTexts,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          for (final type in LegalDocumentType.values)
            if (type != current)
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: 48,
                title: Text(legalTitle(l10n, type)),
                trailing: const Icon(Icons.chevron_right),
                // Replaced, not pushed: going back leaves the legal pages at once.
                onTap: () => context.replace('/legal/${type.slug}'),
              ),
        ],
      ),
    );
  }
}
