import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/polling.dart';

import '../data/club_models.dart';
import '../data/club_repository.dart';

/// Scores and mats change while the club watches: they follow the event on the live socket.
Set<String> eventTopics(String eventId) => {'event:$eventId'};

final eventSettingsProvider = FutureProvider.autoDispose
    .family<EventSettings, String>(
      (ref, eventId) => ref.watch(clubRepositoryProvider).settings(eventId),
    );

final participantsProvider = FutureProvider.autoDispose
    .family<List<Participant>, String>(
      (ref, eventId) => ref.watch(clubRepositoryProvider).participants(eventId),
    );

final standingsProvider = FutureProvider.autoDispose
    .family<List<StandingRow>, String>(
      (ref, eventId) => liveReload(
        ref,
        eventTopics(eventId),
        () => ref.watch(clubRepositoryProvider).standings(eventId),
      ),
    );

typedef ParticipantKey = ({String eventId, String participantId});

/// Live: it changes with every point of their matches.
final participantRecordProvider = FutureProvider.autoDispose
    .family<ParticipantRecord, ParticipantKey>(
      (ref, key) => liveReload(
        ref,
        eventTopics(key.eventId),
        () => ref
            .watch(clubRepositoryProvider)
            .record(key.eventId, key.participantId),
      ),
    );

final matsOverviewProvider = FutureProvider.autoDispose
    .family<List<MatOverview>, String>(
      (ref, eventId) => liveReload(
        ref,
        eventTopics(eventId),
        () => ref.watch(clubRepositoryProvider).mats(eventId),
      ),
    );
