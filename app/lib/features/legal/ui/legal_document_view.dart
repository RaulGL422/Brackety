import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/legal_repository.dart';
import '../data/legal_structure.dart';
import 'external_link.dart';
import 'legal_contents.dart';
import 'legal_links.dart';
import 'legal_table_view.dart';

/// One legal text as a page to read (Raul, 2026-11-25): its title and the date of its version,
/// the summary in a box, «En esta página» and the sections in larger type. On a phone the
/// contents fold above the text; on a desktop they stay at its side with the other texts.
class LegalDocumentView extends StatefulWidget {
  const LegalDocumentView({super.key, required this.type, required this.text});

  final LegalDocumentType type;
  final LegalText text;

  @override
  State<LegalDocumentView> createState() => _LegalDocumentViewState();
}

class _LegalDocumentViewState extends State<LegalDocumentView> {
  late final _structure = LegalStructure.parse(widget.text.markdown);
  late final _sectionKeys = [for (final _ in _structure.sections) GlobalKey()];
  final _contentsKey = GlobalKey();
  final _current = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _current.dispose();
    super.dispose();
  }

  void _show(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// The section being read: the last one whose heading has reached the top of the view.
  bool _track(ScrollNotification notification) {
    final view = context.findRenderObject() as RenderBox?;
    if (view == null) return false;
    final top = view.localToGlobal(Offset.zero).dy + 120;
    int? current;
    for (var i = 0; i < _sectionKeys.length; i++) {
      final box = _sectionKeys[i].currentContext?.findRenderObject();
      if (box is RenderBox && box.localToGlobal(Offset.zero).dy <= top) {
        current = i;
      }
    }
    _current.value = current;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= LegalFooter.desktop;
    final style = _style(Theme.of(context));
    return wide ? _wide(style) : _narrow(style);
  }

  Widget _narrow(MarkdownStyleSheet style) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: _column(
        maxWidth: AppSizes.readingMaxWidth,
        children: [
          ..._opening(style),
          KeyedSubtree(
            key: _contentsKey,
            child: LegalContents(
              sections: _structure.sections,
              folding: true,
              onSelected: (i) => _show(_sectionKeys[i]),
            ),
          ),
          ..._sections(style),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _show(_contentsKey),
              icon: const Icon(Icons.arrow_upward),
              label: Text(l10n.legalBackToContents),
            ),
          ),
          const Divider(height: AppSpacing.xl),
          LegalOtherDocuments(current: widget.type),
        ],
      ),
    );
  }

  Widget _wide(MarkdownStyleSheet style) {
    const side = 280.0;
    final aside = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LegalContents(
            sections: _structure.sections,
            current: _current,
            onSelected: (i) => _show(_sectionKeys[i]),
          ),
          const Divider(height: AppSpacing.xl),
          LegalOtherDocuments(current: widget.type),
        ],
      ),
    );
    final text = NotificationListener<ScrollNotification>(
      onNotification: _track,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: _column(
          maxWidth: AppSizes.readingMaxWidth,
          children: [..._opening(style), ..._sections(style)],
        ),
      ),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: side + AppSpacing.xxl + AppSizes.readingMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: side, child: aside),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(child: text),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _column({
    required double maxWidth,
    required List<Widget> children,
  }) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.l,
        children: children,
      ),
    ),
  );

  /// The title, the date of the version, and what comes before the first section.
  List<Widget> _opening(MarkdownStyleSheet style) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          Semantics(
            header: true,
            child: Text(
              _structure.title ?? legalTitle(l10n, widget.type),
              style: theme.textTheme.displaySmall,
            ),
          ),
          Text(
            legalVersionText(context, widget.text.version),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      for (final block in _structure.intro) _block(block, style),
    ];
  }

  List<Widget> _sections(MarkdownStyleSheet style) {
    final theme = Theme.of(context);
    return [
      for (var i = 0; i < _structure.sections.length; i++)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.m,
          children: [
            // Where a jump lands: a little above the heading, so it does not touch the bar.
            SizedBox(key: _sectionKeys[i], height: AppSpacing.s),
            Semantics(
              header: true,
              child: Text(switch (_structure.sections[i]) {
                LegalSection(:final number?, :final title) => '$number. $title',
                LegalSection(:final title) => title,
              }, style: theme.textTheme.headlineSmall),
            ),
            for (final block in _structure.sections[i].blocks)
              _block(block, style),
          ],
        ),
    ];
  }

  Widget _block(LegalBlock block, MarkdownStyleSheet style) => switch (block) {
    LegalProse(:final markdown) => MarkdownBody(
      data: markdown,
      // As wide as the text, so the summary's box lines up with it.
      fitContent: false,
      styleSheet: style,
      onTapLink: (_, href, _) => openExternalLink(href),
    ),
    LegalTable() => LegalTableView(table: block, style: style),
  };

  /// Larger type to read (17 px, airy lines); the summary's quote as a white box.
  static MarkdownStyleSheet _style(ThemeData theme) {
    final scheme = theme.colorScheme;
    final body = theme.textTheme.bodyLarge!.copyWith(fontSize: 17, height: 1.6);
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: body,
      // The texts' own links: in ink and underlined (docs/07-diseno.md), not Material's blue.
      a: TextStyle(
        color: scheme.onSurface,
        decoration: TextDecoration.underline,
      ),
      listBullet: body,
      blockquote: body,
      blockquotePadding: const EdgeInsets.all(AppSpacing.m),
      blockquoteDecoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      code: body.copyWith(
        fontFamily: 'monospace',
        fontSize: 15,
        backgroundColor: scheme.surfaceContainerLowest,
      ),
      tableBody: body.copyWith(
        fontSize: 15,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
