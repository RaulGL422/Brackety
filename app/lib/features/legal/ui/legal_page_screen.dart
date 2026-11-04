import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/legal_repository.dart';
import '../state/legal_providers.dart';
import 'external_link.dart';
import 'legal_links.dart';

/// `/legal/<slug>`, open with or without a session, in the app's language.
class LegalPageScreen extends StatelessWidget {
  const LegalPageScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = LegalDocumentType.fromSlug(slug);
    return Scaffold(
      appBar: AppBar(
        title: Text(type == null ? l10n.legalSection : legalTitle(l10n, type)),
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
      data: (text) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.readingMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Markdown(markdown: text.markdown),
                const Divider(height: AppSpacing.xxl),
                _OtherDocuments(current: type),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Markdown extends StatelessWidget {
  const _Markdown({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final compact = WindowSize.of(context) == WindowSize.compact;
    // A fixed column width makes the package scroll the table sideways instead of squeezing it.
    final style = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      tableColumnWidth: compact
          ? const FixedColumnWidth(AppSizes.compactTableColumnWidth)
          : null,
    );
    return MarkdownBody(
      data: markdown,
      styleSheet: style,
      onTapLink: (_, href, _) => openExternalLink(href),
    );
  }
}

class _OtherDocuments extends StatelessWidget {
  const _OtherDocuments({required this.current});

  final LegalDocumentType current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        for (final type in LegalDocumentType.values)
          if (type != current)
            OutlinedButton(
              // Replaced, not pushed: going back leaves the legal pages at once.
              onPressed: () => context.replace('/legal/${type.slug}'),
              child: Text(legalTitle(l10n, type)),
            ),
      ],
    );
  }
}
