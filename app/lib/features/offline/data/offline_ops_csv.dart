import '../../scoreboard/data/match_view.dart';
import 'offline_op.dart';

/// The actions a device could not send, as a file the club imports (docs/modulos/offline.md,
/// "Rescate"). Read by the server's `OfflineOpsCsv`: same header, version and columns.
String offlineOpsCsv(List<OfflineOp> ops) {
  final lines = [
    'brackety-offline-ops;1',
    'opId;matchId;type;side;reason;at;knownEvents;actor',
    for (final op in ops)
      [
        op.opId,
        op.matchId,
        op.action.wire,
        sideToJson(op.side) ?? '',
        op.reason ?? '',
        op.at.toUtc().toIso8601String(),
        op.knownEvents,
        op.account ?? '',
      ].map((cell) => _cell('$cell')).join(';'),
  ];
  // A BOM so a spreadsheet opens accents right; CRLF as spreadsheets expect.
  return '﻿${lines.join('\r\n')}\r\n';
}

String _cell(String text) => text.contains(RegExp('[;"\r\n]'))
    ? '"${text.replaceAll('"', '""')}"'
    : text;
