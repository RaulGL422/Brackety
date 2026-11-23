/// A sport to pick (docs/producto/plantillas-deporte.md): its [code] in the API, its names by
/// language, and whether it has a scoreboard yet ([available]); the others are listed for later.
class Sport {
  const Sport({
    required this.code,
    required this.names,
    required this.available,
  });

  factory Sport.fromJson(Map<String, dynamic> json) => Sport(
    code: json['discipline'] as String,
    names: (json['names'] as Map<String, dynamic>).cast<String, String>(),
    available: json['available'] as bool,
  );

  final String code;
  final Map<String, String> names;
  final bool available;

  /// In the app's language; otherwise in Spanish, the language the sports are written in first.
  String name(String languageCode) =>
      names[languageCode] ?? names['es'] ?? names.values.firstOrNull ?? code;
}

List<Sport> sportsFromJson(List<dynamic> json) => [
  for (final s in json.cast<Map<String, dynamic>>()) Sport.fromJson(s),
];

/// [code]'s name among [sports] in [localeTag]'s language (`es`, `es-ES`); the code itself for
/// one no longer listed.
String sportName(List<Sport> sports, String code, String localeTag) =>
    sports
        .where((s) => s.code == code)
        .firstOrNull
        ?.name(localeTag.split('-').first) ??
    code;

/// How many golds, silvers and bronzes a category gives on the final league standings.
class Podium {
  const Podium({
    required this.firsts,
    required this.seconds,
    required this.thirds,
  });

  factory Podium.fromJson(Map<String, dynamic> json) => Podium(
    firsts: json['firsts'] as int,
    seconds: json['seconds'] as int,
    thirds: json['thirds'] as int,
  );

  final int firsts;
  final int seconds;
  final int thirds;

  Map<String, dynamic> toJson() => {
    'firsts': firsts,
    'seconds': seconds,
    'thirds': thirds,
  };
}

class CategoryPodium {
  const CategoryPodium({required this.categoryName, required this.podium});

  factory CategoryPodium.fromJson(Map<String, dynamic> json) => CategoryPodium(
    categoryName: json['categoryName'] as String,
    podium: Podium.fromJson(json['podium'] as Map<String, dynamic>),
  );

  final String categoryName;
  final Podium podium;

  Map<String, dynamic> toJson() => {
    'categoryName': categoryName,
    'podium': podium.toJson(),
  };
}

/// A phase of the league: an event of its own, with its entries, mats, scores and settings.
class LeaguePhase {
  const LeaguePhase({
    required this.eventId,
    required this.number,
    required this.name,
    required this.date,
    required this.sport,
    required this.participants,
  });

  factory LeaguePhase.fromJson(Map<String, dynamic> json) => LeaguePhase(
    eventId: json['eventId'] as String,
    number: json['number'] as int,
    name: json['name'] as String,
    date: DateTime.parse(json['date'] as String),
    sport: json['discipline'] as String,
    participants: json['participants'] as int,
  );

  final String eventId;
  final int number;
  final String name;
  final DateTime date;

  /// Its sport's code ([Sport.code]).
  final String sport;
  final int participants;
}

class League {
  const League({
    required this.name,
    required this.podium,
    required this.categoryPodiums,
    required this.phases,
    required this.categoryNames,
    required this.sports,
    this.globalStandings = false,
  });

  factory League.fromJson(Map<String, dynamic> json) => League(
    name: json['name'] as String,
    podium: Podium.fromJson(json['podium'] as Map<String, dynamic>),
    globalStandings: json['globalStandings'] as bool? ?? false,
    categoryPodiums: [
      for (final c in json['categoryPodiums'] as List)
        CategoryPodium.fromJson(c as Map<String, dynamic>),
    ],
    phases: [
      for (final p in (json['phases'] as List).cast<Map<String, dynamic>?>())
        LeaguePhase.fromJson(p as Map<String, dynamic>),
    ],
    categoryNames: [for (final n in json['categoryNames'] as List) n as String],
    sports: sportsFromJson(json['disciplines'] as List),
  );

  final String name;
  final Podium podium;
  final List<CategoryPodium> categoryPodiums;
  final List<LeaguePhase> phases;

  /// Every category of every phase, youngest first.
  final List<String> categoryNames;

  /// Every sport, with or without a scoreboard yet.
  final List<Sport> sports;

  /// Also every category together (F2-4); off, the standings are only per category.
  final bool globalStandings;
}

/// Someone entered in another phase and not in this one, with their latest entry.
class LeagueCandidate {
  const LeagueCandidate({
    required this.personId,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.lastPhase,
    this.organizationName,
    this.categoryName,
  });

  factory LeagueCandidate.fromJson(Map<String, dynamic> json) =>
      LeagueCandidate(
        personId: json['personId'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        age: json['age'] as int,
        lastPhase: json['lastPhase'] as int,
        organizationName: json['organizationName'] as String?,
        categoryName: json['categoryName'] as String?,
      );

  final String personId;
  final String firstName;
  final String lastName;

  /// On this phase's date.
  final int age;
  final int lastPhase;
  final String? organizationName;
  final String? categoryName;
}

typedef PhasePoints = ({int attendance, int matches});

/// One person on the accumulated standings; [phasePoints] follows the league's phases, null where absent.
class LeagueStandingRow {
  const LeagueStandingRow({
    required this.categoryName,
    required this.position,
    required this.firstName,
    required this.lastName,
    required this.phasePoints,
    required this.total,
    this.medal,
    this.organizationName,
    this.warnings = 0,
    this.disqualifications = 0,
    this.eventId,
    this.participantId,
    this.personId,
  });

  factory LeagueStandingRow.fromJson(Map<String, dynamic> json) =>
      LeagueStandingRow(
        categoryName: json['categoryName'] as String?,
        position: json['position'] as int,
        medal: json['medal'] as int?,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        organizationName: json['organizationName'] as String?,
        phasePoints: [
          for (final p
              in (json['phases'] as List).cast<Map<String, dynamic>?>())
            p == null
                ? null
                : (
                    attendance: p['attendancePoints'] as int,
                    matches: p['matchPoints'] as int,
                  ),
        ],
        total: json['total'] as int,
        warnings: json['warnings'] as int? ?? 0,
        disqualifications: json['disqualifications'] as int? ?? 0,
        eventId: json['eventId'] as String?,
        participantId: json['participantId'] as String?,
        personId: json['personId'] as String?,
      );

  final String? categoryName;
  final int position;

  /// The person across phases: their warnings in the whole league come by it.
  final String? personId;

  /// 1, 2 or 3 by the category's podium.
  final int? medal;
  final String firstName;
  final String lastName;
  final String? organizationName;
  final List<PhasePoints?> phasePoints;
  final int total;

  /// In every match of the league (both kinds of warning; a team's count for each member).
  final int warnings;
  final int disqualifications;

  /// Their entry in the latest phase they are in: their record opens from there.
  final String? eventId;
  final String? participantId;
}

class LeagueStandings {
  const LeagueStandings({required this.phaseNumbers, required this.rows});

  factory LeagueStandings.fromJson(Map<String, dynamic> json) =>
      LeagueStandings(
        phaseNumbers: [
          for (final p
              in (json['phases'] as List).cast<Map<String, dynamic>?>())
            (p as Map<String, dynamic>)['number'] as int,
        ],
        rows: [
          for (final r in json['rows'] as List)
            LeagueStandingRow.fromJson(r as Map<String, dynamic>),
        ],
      );

  final List<int> phaseNumbers;
  final List<LeagueStandingRow> rows;
}
