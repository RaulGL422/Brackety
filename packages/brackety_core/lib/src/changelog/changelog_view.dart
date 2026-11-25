import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/core_localizations.dart';
import '../theme/tokens.dart';
import 'changelog.dart';
import 'changelog_provider.dart';

/// What each debug build brings (`CHANGELOG.md`), with a search by words: «árbitro qr» keeps the
/// changes that say both. Without the file (not a debug image) it says where it lives.
class ChangelogView extends ConsumerStatefulWidget {
  const ChangelogView({super.key});

  @override
  ConsumerState<ChangelogView> createState() => _ChangelogViewState();
}

class _ChangelogViewState extends ConsumerState<ChangelogView> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CoreLocalizations.of(context);
    final changes = ref.watch(changelogProvider);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: switch (changes) {
          AsyncData(value: final entries?) => _list(context, entries),
          AsyncData() => _Message(l10n.changelogMissing),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _list(BuildContext context, List<ChangelogEntry> all) {
    final l10n = CoreLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: _query,
      builder: (context, query, _) {
        final shown = all.where((e) => e.matches(query.text)).toList();
        final rows = _rows(shown);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.l,
                top: AppSpacing.l,
                right: AppSpacing.l,
                bottom: AppSpacing.xs,
              ),
              child: TextField(
                controller: _query,
                decoration: InputDecoration(
                  labelText: l10n.changelogSearch,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.changelogClear,
                          icon: const Icon(Icons.close),
                          onPressed: _query.clear,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Text(
                l10n.changelogCount(shown.length, all.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? _Message(l10n.changelogNoMatch)
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      itemCount: rows.length,
                      itemBuilder: (_, i) => rows[i],
                    ),
            ),
          ],
        );
      },
    );
  }

  /// The release and the kind once, above their changes.
  static List<Widget> _rows(List<ChangelogEntry> entries) {
    final rows = <Widget>[];
    String? release;
    String? kind;
    for (final e in entries) {
      if (e.release != release) {
        release = e.release;
        kind = null;
        rows.add(_Heading(e.release, release: true));
      }
      if (e.kind != kind && e.kind.isNotEmpty) {
        kind = e.kind;
        rows.add(_Heading(e.kind, release: false));
      }
      rows.add(_Change(e.text));
    }
    return rows;
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {required this.release});

  final String text;
  final bool release;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        top: release ? AppSpacing.l : AppSpacing.m,
        bottom: AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: release ? styles.titleLarge : styles.titleSmall,
        ),
      ),
    );
  }
}

class _Change extends StatelessWidget {
  const _Change(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s,
        children: [
          const ExcludeSemantics(child: Text('•')),
          Expanded(child: SelectableText(text)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
