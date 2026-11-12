import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_controller.dart';
import '../data/my_event.dart';

final myEventsProvider = FutureProvider.autoDispose<List<MyEvent>>((ref) async {
  final response = await ref
      .watch(apiProvider)
      .get<List<dynamic>>('/api/v1/events');
  return [
    for (final json in response.data!)
      MyEvent.fromJson(json as Map<String, dynamic>),
  ];
});

final myEventProvider = FutureProvider.autoDispose.family<MyEvent, String>((
  ref,
  eventId,
) async {
  final events = await ref.watch(myEventsProvider.future);
  return events.firstWhere((e) => e.id == eventId);
});

/// The events grouped by league, the league with the latest phase first; phases in order.
List<List<MyEvent>> byLeague(List<MyEvent> events) {
  final leagues = <String, List<MyEvent>>{};
  for (final e in events) {
    (leagues[e.leagueId] ??= []).add(e);
  }
  return [
    for (final phases in leagues.values)
      phases..sort((a, b) => a.phaseNumber.compareTo(b.phaseNumber)),
  ];
}

/// The phases of [eventId]'s league that the account runs as club, in order.
final clubPhasesProvider = FutureProvider.autoDispose
    .family<List<MyEvent>, String>((ref, eventId) async {
      final events = await ref.watch(myEventsProvider.future);
      final leagueId = events
          .where((e) => e.id == eventId)
          .firstOrNull
          ?.leagueId;
      return [
        for (final e in events)
          if (e.leagueId == leagueId && e.roles.contains(EventRole.club)) e,
      ]..sort((a, b) => a.phaseNumber.compareTo(b.phaseNumber));
    });
