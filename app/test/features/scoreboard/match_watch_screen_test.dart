import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/features/offline/state/offline_sync.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/scoreboard/state/match_review.dart';
import 'package:brackety/features/scoreboard/ui/match_watch_screen.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/match_fakes.dart';

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  // The device's clock, moved by hand: the club's clock counts from it.
  var now = DateTime(2027, 3, 10, 10);

  Future<void> open(WidgetTester tester, Size size, MatchView view) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchedMatchProvider.overrideWith((ref, _) async => view),
          deviceClockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          builder: (_, child) => ToastHost(child: child!),
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MatchWatchScreen(matchId: 'm1'),
        ),
      ),
    );
    await tester.pump();
  }

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('the club sees the time left run down on $device', (
      tester,
    ) async {
      await open(
        tester,
        size,
        matchView(
          status: MatchStatus.inProgress,
          running: true,
          remaining: const Duration(minutes: 2, seconds: 41),
        ),
      );

      expect(find.text('2:41'), findsOneWidget);
      expect(find.text('Clock running'), findsOneWidget);
      now = now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2:39'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a stopped clock stays put and says so', (tester) async {
    await open(
      tester,
      sizes['phone']!,
      matchView(
        status: MatchStatus.inProgress,
        remaining: const Duration(seconds: 75),
      ),
    );

    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1:15'), findsOneWidget);
    expect(find.text('Clock stopped'), findsOneWidget);
  });

  testWidgets('a pending match shows no clock', (tester) async {
    await open(tester, sizes['phone']!, matchView());

    expect(find.text('2:00'), findsNothing);
    expect(find.text('Clock stopped'), findsNothing);
  });
}
