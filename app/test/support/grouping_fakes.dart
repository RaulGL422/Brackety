import 'package:brackety/features/grouping/data/grouping_models.dart';
import 'package:brackety/features/grouping/data/grouping_repository.dart';
import 'package:brackety/features/grouping/state/group_draft.dart';

class FakeGroupingRepository implements GroupingRepository {
  FakeGroupingRepository(this.list, {this.teamList = const []});

  final List<CategoryParticipant> list;
  final List<Team> teamList;
  final created = <List<DraftGroup>>[];
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
    List<DraftGroup> groups,
  ) async {
    created.add(groups);
    return CreatedGroups(
      matNumber: 2,
      groupNumbers: [for (var i = 0; i < groups.length; i++) i + 1],
    );
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
