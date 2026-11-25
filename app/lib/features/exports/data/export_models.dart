/// What a column holds; decides how it is filtered (a number takes a range).
enum FieldKind {
  text,
  number,
  decimal,
  date,
  time,
  dateTime,
  duration;

  static FieldKind parse(String name) => switch (name) {
    'NUMBER' => number,
    'DECIMAL' => decimal,
    'DATE' => date,
    'TIME' => time,
    'DATE_TIME' => dateTime,
    'DURATION' => duration,
    _ => text,
  };

  bool get isNumber => this == number || this == decimal;
}

/// docs/06-legal-rgpd.md: personal data (birth date, measures) and data about minors.
enum Sensitivity {
  normal,
  personal,
  minors;

  static Sensitivity parse(String name) => switch (name) {
    'PERSONAL' => personal,
    'MINORS' => minors,
    _ => normal,
  };
}

/// A column a sheet offers, titled in the app's language.
class ExportField {
  const ExportField({
    required this.key,
    required this.title,
    this.kind = FieldKind.text,
    this.sensitivity = Sensitivity.normal,
  });

  factory ExportField.fromJson(Map<String, dynamic> json) => ExportField(
    key: json['key'] as String,
    title: json['title'] as String,
    kind: FieldKind.parse(json['kind'] as String),
    sensitivity: Sensitivity.parse(json['sensitivity'] as String),
  );

  final String key;
  final String title;
  final FieldKind kind;
  final Sensitivity sensitivity;

  bool get isPersonal => sensitivity != Sensitivity.normal;
}

/// One set of rows the club can export: participants, matches, standings…
class ExportSheet {
  const ExportSheet({
    required this.key,
    required this.title,
    required this.fields,
  });

  factory ExportSheet.fromJson(Map<String, dynamic> json) => ExportSheet(
    key: json['key'] as String,
    title: json['title'] as String,
    fields: [
      for (final f in json['fields'] as List)
        ExportField.fromJson(f as Map<String, dynamic>),
    ],
  );

  final String key;
  final String title;
  final List<ExportField> fields;

  ExportField? field(String key) {
    for (final f in fields) {
      if (f.key == key) return f;
    }
    return null;
  }

  /// To start with: the first columns that are not personal data.
  List<String> get startingColumns => [
    for (final f in fields.where((f) => !f.isPersonal).take(6)) f.key,
  ];
}

enum ExportFormat {
  csv('text/csv'),
  xlsx('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
  pdf('application/pdf');

  const ExportFormat(this.mimeType);

  final String mimeType;
}

/// Rows whose cell is one of [anyOf] and, for a number, inside [min]–[max].
class ExportFilter {
  const ExportFilter({
    required this.column,
    this.anyOf = const [],
    this.min,
    this.max,
  });

  final String column;
  final List<String> anyOf;
  final num? min;
  final num? max;

  bool get isEmpty => anyOf.isEmpty && min == null && max == null;

  Map<String, dynamic> toJson() => {
    'column': column,
    if (anyOf.isNotEmpty) 'anyOf': anyOf,
    'min': ?min,
    'max': ?max,
  };
}

class ExportSort {
  const ExportSort({required this.column, this.descending = false});

  final String column;
  final bool descending;

  Map<String, dynamic> toJson() => {'column': column, 'descending': descending};
}

/// What the club is putting together; the server checks it all again.
class ExportDraft {
  const ExportDraft({
    required this.sheet,
    required this.columns,
    this.titles = const {},
    this.filters = const [],
    this.sort = const [],
    this.splitBy,
    this.format = ExportFormat.csv,
    this.english = false,
    this.pdfTitle = '',
    this.landscape,
    this.forPublishing = false,
  });

  final String sheet;
  final List<String> columns;
  final Map<String, String> titles;
  final List<ExportFilter> filters;
  final List<ExportSort> sort;
  final String? splitBy;
  final ExportFormat format;
  final bool english;
  final String pdfTitle;

  /// Null: the server turns the page when there are many columns.
  final bool? landscape;

  /// «Para publicar»: first name and the initial of the last name, no personal columns.
  final bool forPublishing;

  ExportDraft copyWith({
    String? sheet,
    List<String>? columns,
    Map<String, String>? titles,
    List<ExportFilter>? filters,
    List<ExportSort>? sort,
    String? Function()? splitBy,
    ExportFormat? format,
    bool? english,
    String? pdfTitle,
    bool? Function()? landscape,
    bool? forPublishing,
  }) => ExportDraft(
    sheet: sheet ?? this.sheet,
    columns: columns ?? this.columns,
    titles: titles ?? this.titles,
    filters: filters ?? this.filters,
    sort: sort ?? this.sort,
    splitBy: splitBy == null ? this.splitBy : splitBy(),
    format: format ?? this.format,
    english: english ?? this.english,
    pdfTitle: pdfTitle ?? this.pdfTitle,
    landscape: landscape == null ? this.landscape : landscape(),
    forPublishing: forPublishing ?? this.forPublishing,
  );

  /// Filters still being written (no value yet) are left out.
  Map<String, dynamic> toJson() => {
    'sheet': sheet,
    'columns': columns,
    if (titles.isNotEmpty) 'titles': titles,
    'filters': [
      for (final f in filters)
        if (!f.isEmpty) f.toJson(),
    ],
    'sort': [for (final s in sort) s.toJson()],
    'splitBy': ?splitBy,
    'locale': english ? 'en' : 'es',
    'format': format.name,
    if (format == ExportFormat.pdf && pdfTitle.trim().isNotEmpty)
      'title': pdfTitle.trim(),
    if (format == ExportFormat.pdf) 'landscape': ?landscape,
    if (forPublishing) 'forPublishing': true,
  };
}

/// The first rows as the file will write them, and how many there are.
class ExportPreview {
  const ExportPreview({
    required this.headers,
    required this.rows,
    required this.totalRows,
  });

  factory ExportPreview.fromJson(Map<String, dynamic> json) => ExportPreview(
    headers: [for (final h in json['headers'] as List) h as String],
    rows: [
      for (final r in json['rows'] as List)
        [for (final c in r as List) c as String?],
    ],
    totalRows: json['totalRows'] as int,
  );

  final List<String> headers;
  final List<List<String?>> rows;
  final int totalRows;
}

/// A download with personal data: who, when, which sheet and which personal columns.
class ExportAuditEntry {
  const ExportAuditEntry({
    required this.account,
    required this.at,
    required this.sheet,
    required this.columns,
  });

  factory ExportAuditEntry.fromJson(Map<String, dynamic> json) =>
      ExportAuditEntry(
        account: json['account'] as String,
        at: DateTime.parse(json['at'] as String),
        sheet: json['sheet'] as String,
        columns: json['columns'] as String,
      );

  final String account;
  final DateTime at;
  final String sheet;
  final String columns;
}
