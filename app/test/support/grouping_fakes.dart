import 'package:brackety/features/club/data/club_models.dart';
import 'package:brackety/features/club/state/club_providers.dart';
import 'package:brackety/features/grouping/data/grouping_models.dart';
import 'package:brackety/features/grouping/data/grouping_repository.dart';
import 'package:brackety/features/grouping/state/group_draft.dart';

/// Mat 1 with a referee, mat 2 without one.
final fakeMatsOverride = matsOverviewProvider.overrideWith(
  (ref, _) async => [
    MatOverview(
      id: 'm1',
      number: 1,
      referee: 'arbitro1',
      groups: 0,
      pendingMatches: 0,
      matchInProgress: false,
      remaining: Duration.zero,
      estimatedEnd: DateTime(2027, 3, 10, 9),
    ),
    MatOverview(
      id: 'm2',
      number: 2,
      groups: 0,
      pendingMatches: 0,
      matchInProgress: false,
      remaining: Duration.zero,
      estimatedEnd: DateTime(2027, 3, 10, 9),
    ),
  ],
);

class FakeGroupingRepository implements GroupingRepository {
  FakeGroupingRepository(this.list, {this.teamList = const []});

  final List<CategoryParticipant> list;
  final List<Team> teamList;
  final created = <DraftGroup>[];
  final createdOnMat = <String?>[];
  final createdTeams = <List<String>>[];
  final deletedTeams = <String>[];

  @override
  Future<List<CategoryParticipant>> participants(
    String eventId,
    String categoryId,
  ) async => list;

  @override
  Future<List<CategorySummary>> categories(String eventId) async => [];

  @override
  Future<CreatedGroups> create(
    String eventId,
    String categoryId,
    DraftGroup group, {
    String? matId,
  }) async {
    created.add(group);
    createdOnMat.add(matId);
    return const CreatedGroups(matNumber: 2, groupNumbers: [1]);
  }

  @override
  Future<List<Team>> teams(String eventId, String categoryId) async => teamList;

  @override
  Future<Team> createTeam(
    String eventId,
    String categoryId,
    List<String> participantIds,
  ) async {
    createdTeams.add(participantIds);
    return Team(id: 'new', number: teamList.length + 1, members: const []);
  }

  @override
  Future<void> deleteTeam(String eventId, String teamId) async =>
      deletedTeams.add(teamId);
}
