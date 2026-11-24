/// What importing the hall's results brings. [alreadyImported]: the same results came before, nothing changes.
class ResultsImport {
  const ResultsImport({
    required this.alreadyImported,
    required this.newParticipants,
    required this.groups,
    required this.matches,
    required this.actions,
  });

  factory ResultsImport.fromJson(Map<String, dynamic> json) => ResultsImport(
    alreadyImported: json['alreadyImported'] as bool,
    newParticipants: json['newParticipants'] as int,
    groups: json['groups'] as int,
    matches: json['matches'] as int,
    actions: json['actions'] as int,
  );

  final bool alreadyImported;
  final int newParticipants;
  final int groups;
  final int matches;
  final int actions;
}
