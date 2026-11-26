/// A download with personal data (docs/producto/exportaciones.md): who, when, which sheet and which
/// personal columns.
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
