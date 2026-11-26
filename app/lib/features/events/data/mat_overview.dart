class MatOverview {
  const MatOverview({
    required this.id,
    required this.number,
    required this.groups,
    required this.pendingMatches,
    required this.matchInProgress,
    required this.remaining,
    required this.estimatedEnd,
    this.referee,
    this.matchesInReview = 0,
    this.disabledAt,
    this.disabledReferee,
  });

  factory MatOverview.fromJson(Map<String, dynamic> json) => MatOverview(
    id: json['id'] as String,
    number: json['number'] as int,
    referee: json['referee'] as String?,
    groups: json['groups'] as int,
    pendingMatches: json['pendingMatches'] as int,
    matchInProgress: json['matchInProgress'] as bool,
    remaining: Duration(seconds: json['remainingSeconds'] as int),
    estimatedEnd: DateTime.parse(json['estimatedEnd'] as String).toLocal(),
    matchesInReview: json['matchesInReview'] as int? ?? 0,
    disabledAt: switch (json['disabledAt']) {
      final String at => DateTime.parse(at).toLocal(),
      _ => null,
    },
    disabledReferee: json['disabledReferee'] as String?,
  );

  final String id;
  final int number;
  final String? referee;
  final int groups;
  final int pendingMatches;
  final bool matchInProgress;
  final Duration remaining;
  final DateTime estimatedEnd;

  /// Matches waiting for the club to apply or discard what a phone sent.
  final int matchesInReview;

  /// Out of use since then (F1-1); null while in use.
  final DateTime? disabledAt;

  /// The referee it had, who gets it back on enabling it.
  final String? disabledReferee;

  bool get isDisabled => disabledAt != null;
}
