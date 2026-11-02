import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/grouping_models.dart';
import '../data/grouping_repository.dart';

final categoriesProvider = FutureProvider.autoDispose
    .family<List<CategorySummary>, String>(
      (ref, eventId) =>
          ref.watch(groupingRepositoryProvider).categories(eventId),
    );

typedef CategoryKey = ({String eventId, String categoryId});

final categoryParticipantsProvider = FutureProvider.autoDispose
    .family<List<CategoryParticipant>, CategoryKey>(
      (ref, key) => ref
          .watch(groupingRepositoryProvider)
          .participants(key.eventId, key.categoryId),
    );

final categoryTeamsProvider = FutureProvider.autoDispose
    .family<List<Team>, CategoryKey>(
      (ref, key) => ref
          .watch(groupingRepositoryProvider)
          .teams(key.eventId, key.categoryId),
    );

enum ParticipantSort { name, height }

/// By name as the server sends them, or shortest first (then by name) with unknown heights last.
List<CategoryParticipant> sortParticipants(
  List<CategoryParticipant> participants,
  ParticipantSort sort,
) {
  if (sort == ParticipantSort.name) return participants;
  return [...participants]..sort((a, b) {
    if (a.heightCm == b.heightCm) return a.fullName.compareTo(b.fullName);
    if (a.heightCm == null) return 1;
    if (b.heightCm == null) return -1;
    return a.heightCm!.compareTo(b.heightCm!);
  });
}
