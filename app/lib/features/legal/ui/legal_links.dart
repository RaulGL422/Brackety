import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/legal_repository.dart';
import 'linked_text.dart';

String legalTitle(AppLocalizations l10n, LegalDocumentType type) =>
    switch (type) {
      LegalDocumentType.privacy => l10n.legalPrivacy,
      LegalDocumentType.terms => l10n.legalTerms,
      LegalDocumentType.cookies => l10n.legalCookies,
      LegalDocumentType.legalNotice => l10n.legalNotice,
    };

String _shortTitle(AppLocalizations l10n, LegalDocumentType type) =>
    switch (type) {
      LegalDocumentType.privacy => l10n.legalPrivacyShort,
      LegalDocumentType.terms => l10n.legalTermsShort,
      LegalDocumentType.cookies => l10n.legalCookiesShort,
      LegalDocumentType.legalNotice => l10n.legalNotice,
    };

/// Pushed, so the screen below (a half-filled form) is still there on the way back.
void openLegalPage(BuildContext context, LegalDocumentType type) =>
    context.push('/legal/${type.slug}');

/// The legal links at the foot of the signed-out screens.
class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = TextButton.styleFrom(
      textStyle: Theme.of(context).textTheme.bodySmall,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.xs,
      children: [
        for (final type in LegalDocumentType.values)
          TextButton(
            style: style,
            onPressed: () => openLegalPage(context, type),
            child: Text(_shortTitle(l10n, type)),
          ),
        TextButton(
          style: style,
          onPressed: () => showLicensePage(context: context),
          child: Text(l10n.legalLicenses),
        ),
      ],
    );
  }
}

/// A one-line notice where student data is entered, with the privacy policy one tap away.
class PrivacyNotice extends StatelessWidget {
  const PrivacyNotice({super.key, required this.message});

  /// The localized sentence, given the "privacy policy" words to link.
  final String Function(String privacy) message;

  @override
  Widget build(BuildContext context) {
    final link = AppLocalizations.of(context).legalPrivacyLink;
    return LinkedText(
      text: message(link),
      style: Theme.of(context).textTheme.bodySmall,
      links: {link: () => openLegalPage(context, LegalDocumentType.privacy)},
    );
  }
}
