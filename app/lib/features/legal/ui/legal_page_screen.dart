import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/up_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/legal_repository.dart';
import '../state/legal_providers.dart';
import 'legal_document_view.dart';

/// `/legal/<slug>`, open with or without a session, in the app's language. The bar only takes
/// you back: the text names itself, once, as its heading (Raul, 2026-11-25).
class LegalPageScreen extends StatelessWidget {
  const LegalPageScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = LegalDocumentType.fromSlug(slug);
    return Scaffold(
      appBar: AppBar(
        leading: UpButton(label: l10n.back, fallback: '/', isPlace: false),
        leadingWidth: UpButton.leadingWidth(context),
      ),
      body: type == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Text(l10n.legalNotFound, textAlign: TextAlign.center),
              ),
            )
          : _LegalText(type: type),
    );
  }
}

class _LegalText extends ConsumerWidget {
  const _LegalText({required this.type});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = legalTextProvider((
      type,
      Localizations.localeOf(context).languageCode,
    ));
    return AsyncView(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      data: (text) =>
          LegalDocumentView(key: ValueKey(type), type: type, text: text),
    );
  }
}
