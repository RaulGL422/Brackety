import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/club_models.dart';
import '../data/club_repository.dart';

/// Scores and mats change while the club watches; they refresh on their own.
const liveRefresh = Duration(seconds: 5);

void _refreshEvery(Ref ref, Duration period) {
  final timer = Timer(period, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
}

final eventSettingsProvider = FutureProvider.autoDispose
    .family<EventSettings, String>(
      (ref, eventId) => ref.watch(clubRepositoryProvider).settings(eventId),
    );

final participantsProvider = FutureProvider.autoDispose
    .family<List<Participant>, String>(
      (ref, eventId) => ref.watch(clubRepositoryProvider).participants(eventId),
    );

final standingsProvider = FutureProvider.autoDispose
    .family<List<StandingRow>, String>((ref, eventId) {
      _refreshEvery(ref, liveRefresh);
      return ref.watch(clubRepositoryProvider).standings(eventId);
    });

final matsOverviewProvider = FutureProvider.autoDispose
    .family<List<MatOverview>, String>((ref, eventId) {
      _refreshEvery(ref, liveRefresh);
      return ref.watch(clubRepositoryProvider).mats(eventId);
    });
