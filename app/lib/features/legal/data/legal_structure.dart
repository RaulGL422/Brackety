/// A legal text split the way its page shows it (Raul, 2026-11-25): the title, what comes before
/// the first section (the summary and the opening paragraph), and each `## ` section with its
/// own heading, so the page can list them and jump to one. Tables come apart from the prose:
/// on a phone each row becomes a block instead of a table that scrolls sideways.
class LegalStructure {
  const LegalStructure({
    required this.title,
    required this.intro,
    required this.sections,
  });

  factory LegalStructure.parse(String markdown) {
    String? title;
    final intro = <LegalBlock>[];
    final sections = <LegalSection>[];
    var blocks = intro;
    final prose = <String>[];
    final table = <String>[];

    void flushProse() {
      final text = prose.join('\n').trim();
      if (text.isNotEmpty) blocks.add(LegalProse(text));
      prose.clear();
    }

    void flushTable() {
      if (table.isEmpty) return;
      blocks.add(LegalTable.parse(table));
      table.clear();
    }

    for (final line in markdown.split('\n')) {
      final trimmed = line.trimRight();
      if (trimmed.startsWith('|')) {
        flushProse();
        table.add(trimmed);
        continue;
      }
      flushTable();
      if (title == null && trimmed.startsWith('# ')) {
        title = trimmed.substring(2).trim();
      } else if (trimmed.startsWith('## ')) {
        flushProse();
        final section = LegalSection.fromHeading(trimmed.substring(3).trim());
        sections.add(section);
        blocks = section.blocks;
      } else {
        prose.add(trimmed);
      }
    }
    flushTable();
    flushProse();
    return LegalStructure(title: title, intro: intro, sections: sections);
  }

  /// Null when the text has no `# ` line: the page then names it itself.
  final String? title;
  final List<LegalBlock> intro;
  final List<LegalSection> sections;
}

class LegalSection {
  LegalSection({required this.number, required this.title});

  /// «3. Para qué…» → number "3"; a heading without one keeps the whole text as its title.
  factory LegalSection.fromHeading(String heading) {
    final match = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(heading);
    return match == null
        ? LegalSection(number: null, title: heading)
        : LegalSection(number: match[1], title: match[2]!);
  }

  final String? number;
  final String title;
  final blocks = <LegalBlock>[];
}

sealed class LegalBlock {
  const LegalBlock();
}

/// Markdown as it is: paragraphs, lists, the summary's quote.
class LegalProse extends LegalBlock {
  const LegalProse(this.markdown);

  final String markdown;
}

/// A markdown table; each cell is still inline markdown (`code`, **bold**).
class LegalTable extends LegalBlock {
  const LegalTable({required this.header, required this.rows});

  /// The lines of a table: the header, the `|---|` line, then the rows.
  factory LegalTable.parse(List<String> lines) {
    List<String> cells(String line) {
      var inner = line.trim();
      if (inner.startsWith('|')) inner = inner.substring(1);
      if (inner.endsWith('|')) inner = inner.substring(0, inner.length - 1);
      return [for (final cell in inner.split('|')) cell.trim()];
    }

    bool isRule(String line) => RegExp(r'^\|?[\s:|-]+\|?$').hasMatch(line);
    final header = cells(lines.first);
    // As many cells as the header, so a short or long row cannot break the table.
    List<String> fit(List<String> row) => [
      for (var i = 0; i < header.length; i++) i < row.length ? row[i] : '',
    ];
    return LegalTable(
      header: header,
      rows: [
        for (final line in lines.skip(1))
          if (!isRule(line)) fit(cells(line)),
      ],
    );
  }

  final List<String> header;
  final List<List<String>> rows;
}
