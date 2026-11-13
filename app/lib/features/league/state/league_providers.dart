import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/league_models.dart';
import '../data/league_repository.dart';

final leagueProvider = FutureProvider.autoDispose.family<League, String>(
  (ref, eventId) => ref.watch(leagueRepositoryProvider).league(eventId),
);

final leagueStandingsProvider = FutureProvider.autoDispose
    .family<LeagueStandings, String>(
      (ref, eventId) => ref.watch(leagueRepositoryProvider).standings(eventId),
    );

final leagueCandidatesProvider = FutureProvider.autoDispose
    .family<List<LeagueCandidate>, String>(
      (ref, eventId) => ref.watch(leagueRepositoryProvider).candidates(eventId),
    );
