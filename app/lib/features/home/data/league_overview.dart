import '../../events/data/my_event.dart';
import '../../events/state/events_providers.dart';

/// Where a league goes in «Mis eventos»: what is on now, what comes next, what is over.
enum LeagueStage { live, upcoming, finished }

/// What a helper or referee can open in an event; the club opens its panel instead.
enum EventTask { groups, panel, mat }

/// A league (or a standalone event, a league of one phase) as «Mis eventos» shows it: its phases the
/// account has a role in, and the one that matters now.
class LeagueOverview {
  factory LeagueOverview(List<MyEvent> phases) {
    final sorted = [...phases]
      ..sort((a, b) => a.phaseNumber.compareTo(b.phaseNumber));
    final live = sorted.where((p) => p.phaseState == PhaseState.inProgress);
    final next = sorted.where((p) => p.phaseState == PhaseState.notStarted);
    final (featured, stage) = live.isNotEmpty
        ? (live.last, LeagueStage.live)
        : next.isNotEmpty
        ? (next.first, LeagueStage.upcoming)
        : (sorted.last, LeagueStage.finished);
    return LeagueOverview._(sorted, featured, stage);
  }

  const LeagueOverview._(this.phases, this.featured, this.stage);

  final List<MyEvent> phases;

  /// The phase in progress, else the next one to start, else the last one played.
  final MyEvent featured;
  final LeagueStage stage;

  String get name => featured.leagueName;

  /// One phase is a standalone event as far as this account can tell: no phase talk.
  bool get hasPhases => phases.length > 1;
}

/// «Mis eventos» by section: live and upcoming soonest first, finished latest first.
({
  List<LeagueOverview> live,
  List<LeagueOverview> upcoming,
  List<LeagueOverview> finished,
})
overviewOf(List<MyEvent> events) {
  final leagues = [
    for (final phases in byLeague(events)) LeagueOverview(phases),
  ];
  List<LeagueOverview> at(LeagueStage stage, {bool latestFirst = false}) =>
      leagues.where((l) => l.stage == stage).toList()..sort((a, b) {
        final order = a.featured.date.compareTo(b.featured.date);
        return latestFirst ? -order : order;
      });
  return (
    live: at(LeagueStage.live),
    upcoming: at(LeagueStage.upcoming),
    finished: at(LeagueStage.finished, latestFirst: true),
  );
}

/// What a helper or referee can open in [event] now. A referee's mat opens once the phase starts.
List<EventTask> tasksOf(MyEvent event) => [
  if (event.buildsGroups &&
      (event.roles.contains(EventRole.grouper) || !event.isClub))
    EventTask.groups,
  if (event.opensPanel && !event.isClub) EventTask.panel,
  if (event.can(EventPermission.ownMat) &&
      event.matNumber != null &&
      event.phaseState == PhaseState.inProgress)
    EventTask.mat,
];

/// Where each task opens.
String taskRoute(MyEvent event, EventTask task) => switch (task) {
  EventTask.groups => '/events/${event.id}/categories',
  EventTask.panel => '/events/${event.id}/club',
  EventTask.mat => '/mats/${event.matId}?number=${event.matNumber}',
};
