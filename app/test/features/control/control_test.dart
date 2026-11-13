import 'package:brackety/features/club/data/club_models.dart';
import 'package:brackety/features/club/state/club_providers.dart';
import 'package:brackety/features/control/control_repository.dart';
import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/features/mat/state/mat_providers.dart';
import 'package:brackety/features/mat/ui/mat_board_screen.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeControl extends ControlRepository {
  _FakeControl() : super(Dio());

  final calls = <String>[];

  @override
  Future<void> moveMatch(String eventId, String matchId, String matId) async =>
      calls.add('moveMatch $eventId $matchId $matId');

  @override
  Future<void> moveGroup(String eventId, String groupId, String matId) async =>
      calls.add('moveGroup $eventId $groupId $matId');

  @override
  Future<void> reorder(
    String eventId,
    String groupId,
    List<String> matchIds,
  ) async => calls.add('reorder $groupId ${matchIds.join(',')}');

  @override
  Future<void> waiveRest(String eventId, String matchId) async =>
      calls.add('waiveRest $eventId $matchId');
}

void main() {
  late _FakeControl control;

  Fighter fighter(String name) =>
      Fighter(participantId: name, name: name, ghost: false);
  final ana = fighter('Ana');
  final bea = fighter('Bea');
  final carla = fighter('Carla');
  final dani = fighter('Dani');

  BoardMatch match(String id, Fighter red, Fighter blue, {bool ok = true}) =>
      BoardMatch(
        id: id,
        groupId: 'g1',
        groupNumber: 3,
        red: red,
        blue: blue,
        status: MatchStatus.pending,
        redScore: 0,
        blueScore: 0,
        available: ok,
        waitReason: ok ? null : WaitReason.resting,
      );

  final board = MatBoard(
    eventId: 'e1',
    matNumber: 2,
    groups: [
      BoardGroup(
        id: 'g1',
        number: 3,
        categoryName: '7-8',
        members: [ana, bea, carla, dani],
      ),
    ],
    matches: [
      match('m1', ana, bea),
      match('m2', carla, dani, ok: false),
      match('m3', ana, carla),
    ],
    recommendedMatchId: 'm1',
  );

  MatOverview mat(String id, int number, String? referee) => MatOverview(
    id: id,
    number: number,
    referee: referee,
    groups: 1,
    pendingMatches: 2,
    matchInProgress: false,
    remaining: Duration.zero,
    estimatedEnd: DateTime(2027, 3, 10, 12),
  );

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matBoardProvider.overrideWith((ref, matId) async => board),
          controlRepositoryProvider.overrideWithValue(control),
          matsOverviewProvider.overrideWith(
            (ref, eventId) async => [
              mat('mat1', 1, 'arbitro1'),
              mat('mat2', 2, 'arbitro2'),
              mat('mat3', 3, null),
            ],
          ),
        ],
        child: MaterialApp(
          builder: (_, child) => ToastHost(child: child!),
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MatBoardScreen(matId: 'mat2', readOnly: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => control = _FakeControl());

  // On screen: the recommended m1, then m3 (available), then m2 (resting).
  testWidgets('the club moves a pending match to a mat with a referee', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byTooltip('Change').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move this match to another mat'));
    await tester.pumpAndSettle();

    // Neither its own mat nor one without a referee.
    expect(find.textContaining('Mat 2 ·'), findsNothing);
    expect(find.textContaining('Mat 3 ·'), findsNothing);
    await tester.tap(find.textContaining('Mat 1 · arbitro1'));
    await tester.pumpAndSettle();

    expect(control.calls, ['moveMatch e1 m2 mat1']);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('letting a match skip the rest asks first', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Change').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let it start without waiting for the rest'));
    await tester.pumpAndSettle();
    expect(find.text('Start without the least rest?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(control.calls, isEmpty);

    await tester.tap(find.byTooltip('Change').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let it start without waiting for the rest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, allow'));
    await tester.pumpAndSettle();
    expect(control.calls, ['waiveRest e1 m2']);
  });

  testWidgets('the group moves and its pending matches can be reordered', (
    tester,
  ) async {
    await open(tester);
    final groupMenu = find.byTooltip('Change').last;
    await tester.ensureVisible(groupMenu);
    await tester.tap(groupMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change the order of the matches'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(control.calls, ['reorder g1 m1,m2,m3']);

    await tester.ensureVisible(groupMenu);
    await tester.tap(groupMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move the group to another mat'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Mat 1 · arbitro1'));
    await tester.pumpAndSettle();
    expect(control.calls.last, 'moveGroup e1 g1 mat1');
  });
}
