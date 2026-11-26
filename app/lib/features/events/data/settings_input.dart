/// What the event's settings fields accept, and how they show it: the panel's settings and the
/// dialogs that create an event or a phase.
const maxMats = 20;

/// "3:00" for 3 minutes.
String formatMatchLength(Duration length) =>
    '${length.inMinutes}:${(length.inSeconds % 60).toString().padLeft(2, '0')}';

/// "3:00", "3" (minutes) or "2:30" between 0:30 and 20:00 (the server's range), else null.
Duration? parseMatchLength(String text) {
  final match = RegExp(r'^\s*(\d{1,2})(?::(\d{2}))?\s*$').firstMatch(text);
  if (match == null) return null;
  final seconds = int.parse(match[2] ?? '0');
  if (seconds > 59) return null;
  final length = Duration(minutes: int.parse(match[1]!), seconds: seconds);
  return length < const Duration(seconds: 30) ||
          length > const Duration(minutes: 20)
      ? null
      : length;
}

/// Empty or 0: no limit (returns 0); else up to [max], or null if invalid.
int? parsePointsLimit(String text, {int max = 99}) {
  if (text.trim().isEmpty) return 0;
  final value = int.tryParse(text.trim());
  return value == null || value < 0 || value > max ? null : value;
}

/// Seconds, 0 to 600.
Duration? parseMinRest(String text) {
  final value = int.tryParse(text.trim());
  return value == null || value < 0 || value > 600
      ? null
      : Duration(seconds: value);
}

int? parseAttendancePoints(String text) {
  final value = int.tryParse(text.trim());
  return value == null || value < 0 || value > 100 ? null : value;
}
