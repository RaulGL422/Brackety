import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/polling.dart';
import '../club/state/club_providers.dart';
import 'control_repository.dart';

/// One mat and its groups still to finish (GR-4). [disabled]: it takes no groups.
class MatGroups {
  const MatGroups({
    required this.matId,
    required this.number,
    this.referee,
    this.disabled = false,
    this.finishedGroups = 0,
    this.groups = const [],
  });

  factory MatGroups.fromJson(Map<String, dynamic> json) => MatGroups(
    matId: json['matId'] as String,
    number: json['number'] as int,
    referee: json['referee'] as String?,
    disabled: json['disabled'] as bool? ?? false,
    finishedGroups: json['finishedGroups'] as int? ?? 0,
    groups: [
      for (final g in json['groups'] as List)
        GroupCard.fromJson(g as Map<String, dynamic>),
    ],
  );

  final String matId;
  final int number;
  final String? referee;
  final bool disabled;

  /// Done on this mat; they are not listed.
  final int finishedGroups;
  final List<GroupCard> groups;
}

/// A group on the board: who is in it and how far it is. [inProgress]: a match is on, so it
/// cannot move.
class GroupCard {
  const GroupCard({
    required this.id,
    required this.number,
    required this.categoryName,
    required this.members,
    required this.played,
    required this.matches,
    this.inProgress = false,
  });

  factory GroupCard.fromJson(Map<String, dynamic> json) => GroupCard(
    id: json['id'] as String,
    number: json['number'] as int,
    categoryName: json['categoryName'] as String? ?? '',
    members: [
      for (final m in json['members'] as List)
        (
          name: (m as Map<String, dynamic>)['name'] as String,
          ghost: m['ghost'] as bool? ?? false,
        ),
    ],
    played: json['played'] as int,
    matches: json['matches'] as int,
    inProgress: json['inProgress'] as bool? ?? false,
  );

  final String id;
  final int number;
  final String categoryName;

  /// In group order; a wildcard fights but does not score.
  final List<({String name, bool ghost})> members;
  final int played;
  final int matches;
  final bool inProgress;
}

/// Live: a group made, moved or finished anywhere shows at once.
final matGroupsProvider = FutureProvider.autoDispose
    .family<List<MatGroups>, String>(
      (ref, eventId) => liveReload(
        ref,
        eventTopics(eventId),
        () => ref.watch(controlRepositoryProvider).matGroups(eventId),
      ),
    );
