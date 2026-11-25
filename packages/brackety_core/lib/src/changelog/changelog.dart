/// One line of `CHANGELOG.md`: the release it belongs to («Sin publicar (en debug)», «0.8.2»), its
/// kind («Nuevo», «Arreglos», «Interno») and the text, with its pull requests as «(#199)».
class ChangelogEntry {
  ChangelogEntry({
    required this.release,
    required this.kind,
    required this.text,
  }) : _searchable = foldForSearch('$release $kind $text');

  final String release;
  final String kind;
  final String text;
  final String _searchable;

  /// Every word of [query] is somewhere in the entry, whatever its case or accents.
  bool matches(String query) =>
      foldForSearch(query)
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .every(_searchable.contains);
}

/// The lines of `CHANGELOG.md` in its order: `## release`, `### kind`, `- text`. Anything else (the
/// introduction, a release with prose instead of lines) is left out.
List<ChangelogEntry> parseChangelog(String markdown) {
  final entries = <ChangelogEntry>[];
  var release = '';
  var kind = '';
  for (final raw in markdown.split('\n')) {
    final line = raw.trimRight();
    if (line.startsWith('### ')) {
      kind = line.substring(4).trim();
    } else if (line.startsWith('## ')) {
      release = line.substring(3).trim();
      kind = '';
    } else if (line.startsWith('- ') && release.isNotEmpty) {
      entries.add(
        ChangelogEntry(
          release: release,
          kind: kind,
          text: line.substring(2).trim(),
        ),
      );
    }
  }
  return entries;
}

const _accents = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
};

/// Lower case without accents: «Árbitro» is found typing «arbitro».
String foldForSearch(String text) =>
    text.toLowerCase().split('').map((c) => _accents[c] ?? c).join();
