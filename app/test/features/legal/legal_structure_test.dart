import 'package:brackety/features/legal/data/legal_structure.dart';
import 'package:flutter_test/flutter_test.dart';

const _text = '''
# Política de cookies

> **En resumen**
>
> - Solo cookies técnicas.

Brackety solo usa cookies técnicas.

## 1. Qué usamos

| Nombre | Dónde | Duración |
|---|---|---|
| `brackety_refresh` | Web | 30 días |
| Corta | Android |
| Larga | Web | Días | Sobra |

Nada más.

## Contacto

Escribe a privacidad@example.test.
''';

void main() {
  final structure = LegalStructure.parse(_text);

  test('the title comes from the first heading', () {
    expect(structure.title, 'Política de cookies');
  });

  test('the summary and the opening paragraph come before any section', () {
    final intro = structure.intro.cast<LegalProse>();
    expect(intro, hasLength(1));
    expect(intro.single.markdown, startsWith('> **En resumen**'));
    expect(intro.single.markdown, endsWith('cookies técnicas.'));
  });

  test('sections keep their number apart from their title', () {
    expect(
      [for (final s in structure.sections) (s.number, s.title)],
      [('1', 'Qué usamos'), (null, 'Contacto')],
    );
  });

  test('a table comes apart from the prose around it, row by row', () {
    final blocks = structure.sections.first.blocks;
    expect(blocks.map((b) => b.runtimeType), [LegalTable, LegalProse]);
    final table = blocks.first as LegalTable;
    expect(table.header, ['Nombre', 'Dónde', 'Duración']);
    expect(table.rows.first, ['`brackety_refresh`', 'Web', '30 días']);
  });

  test('a short or long row takes the header\'s width', () {
    final table = structure.sections.first.blocks.first as LegalTable;
    expect(table.rows[1], ['Corta', 'Android', '']);
    expect(table.rows[2], ['Larga', 'Web', 'Días']);
  });

  test('a text without headings is all opening', () {
    final plain = LegalStructure.parse('Solo texto.');
    expect(plain.title, isNull);
    expect(plain.sections, isEmpty);
    expect((plain.intro.single as LegalProse).markdown, 'Solo texto.');
  });
}
