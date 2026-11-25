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

/// The foot of the screens before signing in (Raul, 2026-11-25): the legal texts as one group, and
/// the app's own facts (version, software licenses) apart. On a phone the texts sit two by two, on a
/// tablet in one row; a desktop keeps them left and the app's facts right, all along the bottom.
class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key});

  // The window, not the parent: the footer sits in a scroll view sized by its content.
  static const _phone = 420.0;
  static const desktop = 840.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final legal = [
      for (final type in LegalDocumentType.values)
        _FooterLink(
          _shortTitle(l10n, type),
          onPressed: () => openLegalPage(context, type),
        ),
    ];
    final app = [
      const AppVersionText(),
      _FooterLink(
        CoreLocalizations.of(context).licenses,
        onPressed: () => showLicensePage(context: context),
      ),
    ];
    final line = BorderSide(
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    // One group for the screen reader too: «Textos legales».
    Widget group(Widget child) =>
        Semantics(container: true, label: l10n.legalFooterLabel, child: child);
    return width >= desktop
        ? _wide(line, group(Wrap(spacing: AppSpacing.l, children: legal)), app)
        : _narrow(line, group(_grid(legal, width < _phone ? 2 : 4)), app);
  }

  /// All along the bottom: the legal texts left, the app's facts right.
  static Widget _wide(BorderSide line, Widget legal, List<Widget> app) =>
      DecoratedBox(
        decoration: BoxDecoration(border: Border(top: line)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              legal,
              Wrap(
                spacing: AppSpacing.l,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: app,
              ),
            ],
          ),
        ),
      );

  /// The legal texts above, the app's facts on their own line under a rule.
  static Widget _narrow(BorderSide line, Widget legal, List<Widget> app) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            legal,
            DecoratedBox(
              decoration: BoxDecoration(border: Border(top: line)),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: app,
              ),
            ),
          ],
        ),
      );

  /// Equal columns, [columns] per row.
  static Widget _grid(List<Widget> links, int columns) => Column(
    children: [
      for (var i = 0; i < links.length; i += columns)
        Row(
          children: [
            for (final link in links.skip(i).take(columns))
              Expanded(child: link),
          ],
        ),
    ],
  );
}

/// A quiet link of the foot: grey, underlined only when pointed at or focused, as tall as a finger.
/// The grouping and its place say it is a link; the texts' own links keep their underline.
class _FooterLink extends StatelessWidget {
  const _FooterLink(this.text, {required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium!;
    return TextButton(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.s),
        ),
        foregroundColor: WidgetStatePropertyAll(
          theme.colorScheme.onSurfaceVariant,
        ),
        textStyle: WidgetStateProperty.resolveWith(
          (states) => base.copyWith(
            decoration:
                states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
      ),
      onPressed: onPressed,
      child: Text(text, textAlign: TextAlign.center),
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
