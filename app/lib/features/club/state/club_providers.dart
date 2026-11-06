import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/polling.dart';

import '../data/club_models.dart';
import '../data/club_repository.dart';

/// Scores and mats change while the club watches; they refresh on their own.
const liveRefresh = Duration(seconds: 5);

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
      (ref, eventId) => reloadEvery(
        ref,
        liveRefresh,
        () => ref.watch(clubRepositoryProvider).standings(eventId),
      ),
    );

final matsOverviewProvider = FutureProvider.autoDispose
    .family<List<MatOverview>, String>(
      (ref, eventId) => reloadEvery(
        ref,
        liveRefresh,
        () => ref.watch(clubRepositoryProvider).mats(eventId),
      ),
    );
