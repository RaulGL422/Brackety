import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../legal/data/legal_repository.dart';
import '../../../legal/ui/legal_links.dart';
import 'settings_section.dart';

class LegalSection extends StatelessWidget {
  const LegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.legalSection,
      children: [
        for (final type in LegalDocumentType.values)
          _LinkTile(
            title: legalTitle(l10n, type),
            onTap: () => openLegalPage(context, type),
          ),
        _LinkTile(
          title: CoreLocalizations.of(context).licenses,
          onTap: () => showLicensePage(context: context),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
