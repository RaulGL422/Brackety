import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:brackety/features/mat/ui/mat_board_screen.dart';
import 'package:brackety/features/offline/data/offline_op.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/scoreboard/state/bell.dart';
import 'package:brackety/features/scoreboard/ui/match_watch_screen.dart';
import 'package:brackety/features/scoreboard/ui/scoreboard_screen.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/board_finders.dart';
import '../../support/match_fakes.dart';
import '../../support/offline_fakes.dart';

/// Every request fails as without network.
class _NoNetwork implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) => throw DioException.connectionError(
    requestOptions: options,
    reason: 'offline',
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  late TestClock clock;
  late MemoryOfflineStore store;
  late FakeMatchServer server;

  setUp(() {
    clock = TestClock();
    store = MemoryOfflineStore();
    server = FakeMatchServer([
      serverMatch('m1'),
      serverMatch('m2'),
      serverMatch('m3'),
    ], clock);
  });

  // The clock and the polls repaint all the time, so these tests pump time instead of settling.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpScreen(WidgetTester tester, Size size, Widget home) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...offlineOverrides(store: store, clock: clock, repository: server),
          bellProvider.overrideWithValue(FakeBell()),
          apiProvider.overrideWithValue(
            Dio()..httpClientAdapter = _NoNetwork(),
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
          home: home,
        ),
      ),
    );
    await settle(tester);
  }

  Map<String, dynamic> fighter(String name) => {
    'participantId': name,
    'name': name,
    'ghost': false,
    'members': [name],
  };

  Map<String, dynamic> boardMatch(
    String id,
    String red,
    String blue, {
    bool inReview = false,
  }) => {
    'id': id,
    'groupId': 'g1',
    'groupNumber': 1,
    'red': fighter(red),
    'blue': fighter(blue),
    'status': 'PENDING',
    'redScore': 0,
    'blueScore': 0,
    'available': !inReview,
    'inReview': inReview,
  };

  /// What the phone saved before the network went: the board, the views and [ops].
  void saved({List<OfflineOp> ops = const []}) {
    store.docs['board-mat1'] = {
      'matNumber': 1,
      'groups': [
        {
          'id': 'g1',
          'number': 1,
          'categoryName': '7-8',
          'members': [
            fighter('Ana'),
            fighter('Bea'),
            fighter('Carla'),
            fighter('Diana'),
          ],
        },
      ],
      'matches': [
        boardMatch('m1', 'Ana', 'Bea'),
        boardMatch('m2', 'Carla', 'Diana'),
        boardMatch('m3', 'Ana', 'Carla', inReview: true),
      ],
      'recommendedMatchId': 'm2',
    };
    store.docs['views'] = {
      'clockOffsetMs': 0,
      'views': {
        for (final id in ['m1', 'm2', 'm3']) id: serverMatch(id).toJson(),
      },
    };
    store.docs['queue'] = {
      'ops': [for (final op in ops) op.toJson()],
      'heldForReview': [],
    };
  }

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('without network the board comes from the phone on $device', (
      tester,
    ) async {
      server.down = true;
      saved(
        ops: [
          OfflineOp(
            opId: 'op1',
            matchId: 'm1',
            action: MatchAction.start,
            at: t0,
            knownEvents: 0,
          ),
        ],
      );

      await pumpScreen(tester, size, const MatBoardScreen(matId: 'mat1'));

      expect(find.byTooltip('Offline · 1 action waiting'), findsOneWidget);
      expect(find.textContaining('board saved on this device'), findsOneWidget);
      expect(find.text('Next match'), findsNothing);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text("Under the club's review"), findsOneWidget);
      ListTile tile(String red, String blue) =>
          tester.widget<ListTile>(matchTile(red, blue));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Back to the scoreboard'),
            )
            .onPressed,
        isNotNull,
      );
      // One match at a time on the mat, and none in review.
      expect(tile('Carla', 'Diana').onTap, isNull);
      expect(tile('Ana', 'Carla').onTap, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'the referee scores offline and the queue goes out on $device',
      (tester) async {
        server.down = true;
        saved();
        await pumpScreen(tester, size, const ScoreboardScreen(matchId: 'm1'));

        expect(find.byTooltip('Offline'), findsOneWidget);
        await tester.tap(find.text('Start'));
        await settle(tester);
        await tester.tap(find.text('+1').first);
        await settle(tester);

        expect(find.byTooltip('Offline · 2 actions waiting'), findsOneWidget);
        expect(find.text('Stop'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(server.received, isEmpty);

        // The status is an app bar icon: when it goes, no button moves under the thumb.
        final plus = tester.getTopLeft(find.text('+1').first);
        final stop = tester.getTopLeft(find.text('Stop'));

        server.down = false;
        // The next poll gets an answer, and the queue goes with it.
        await tester.pump(const Duration(seconds: 2));
        await settle(tester);

        expect(server.received.map((o) => o.action), [
          MatchAction.start,
          MatchAction.point,
        ]);
        // All sent: the icon goes away.
        expect(find.byIcon(Icons.cloud_off), findsNothing);
        expect(find.text('1'), findsOneWidget);
        expect(tester.getTopLeft(find.text('+1').first), plus);
        expect(tester.getTopLeft(find.text('Stop')), stop);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('the club applies what the phone sent on $device', (
      tester,
    ) async {
      server.views['m1'] = stamped(
        serverMatch('m1'),
        t0,
        review: MatchReview(
          reason: ReviewReason.knownEvents,
          ops: [
            ReviewOp(
              opId: 'op1',
              action: MatchAction.point,
              side: Side.red,
              actor: 'arbitro1',
              at: t0,
              receivedAt: t0,
              cause: 'KNOWN_EVENTS',
            ),
            ReviewOp(
              opId: 'op2',
              action: MatchAction.warning,
              side: Side.blue,
              reason: 'Salida del tapiz',
              actor: 'arbitro1',
              at: t0,
              receivedAt: t0,
              cause: 'IN_REVIEW',
            ),
          ],
        ),
      );
      await pumpScreen(tester, size, const MatchWatchScreen(matchId: 'm1'));

      expect(
        find.text(
          'Another device wrote in the match while the phone was offline.',
        ),
        findsOneWidget,
      );
      expect(find.text('Red · Ana Prueba · arbitro1'), findsOneWidget);
      expect(
        find.text('Blue · Bea Prueba · Salida del tapiz · arbitro1'),
        findsOneWidget,
      );

      await tester.tap(find.text('Apply'));
      await settle(tester);
      expect(find.textContaining('in order and at their time'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Apply').last);
      await settle(tester);

      expect(server.reviews, [('m1', ReviewDecision.apply)]);
      expect(find.text('Applied: 2 · Skipped: 1'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Phone actions under review'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a match in review is locked for the referee', (tester) async {
    saved();
    server.writeElsewhere('m1', MatchAction.start);
    server.views['m1'] = stamped(
      server.views['m1']!,
      t0,
      review: const MatchReview(reason: ReviewReason.knownEvents, ops: []),
    );
    await pumpScreen(
      tester,
      sizes['phone']!,
      const ScoreboardScreen(matchId: 'm1'),
    );

    expect(find.textContaining("Under the club's review:"), findsOneWidget);
    final stop = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Stop'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(stop.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
