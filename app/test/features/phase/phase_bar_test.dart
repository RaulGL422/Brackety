import 'package:brackety/features/phase/data/phase_repository.dart';
import 'package:brackety/features/phase/ui/phase_bar.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/auth_app.dart';

/// The server's phase as it changes with each action.
class FakePhaseRepository extends PhaseRepository {
  FakePhaseRepository(this.current) : super(Dio());

  Phase current;
  final calls = <String>[];

  @override
  Future<Phase> phase(String eventId) async => current;

  @override
  Future<Phase> start(String eventId) async {
    calls.add('start');
    // A group was created meanwhile: three matches would stay unplayed.
    return current = const Phase(
      state: PhaseState.inProgress,
      pendingMatches: 3,
    );
  }

  @override
  Future<Phase> finish(String eventId) async {
    calls.add('finish');
    return current = const Phase(state: PhaseState.finished);
  }

  @override
  Future<Phase> reopen(String eventId, String reason) async {
    calls.add('reopen $reason');
    return current = const Phase(state: PhaseState.inProgress);
  }
}

Future<void> pumpBar(
  WidgetTester tester,
  FakePhaseRepository phases, {
  bool isClub = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [phaseRepositoryProvider.overrideWithValue(phases)],
      child: MaterialApp(
        builder: (_, child) => ToastHost(child: child!),
        theme: lightTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...coreLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PhaseBar(eventId: 'e1', isClub: isClub),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('the club starts, finishes and reopens the phase on $device', (
      tester,
    ) async {
      useSize(tester, size);
      final phases = FakePhaseRepository(
        const Phase(state: PhaseState.notStarted),
      );
      await pumpBar(tester, phases);

      expect(find.textContaining('has not started yet'), findsOneWidget);
      await tester.tap(find.text('Start phase'));
      await tester.pumpAndSettle();
      expect(find.text('Phase in progress'), findsOneWidget);

      await tester.tap(find.text('Finish phase'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 matches are left to play'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Finish phase'));
      await tester.pumpAndSettle();
      expect(find.text('Phase finished: read only'), findsOneWidget);

      await tester.tap(find.text('Reopen phase'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Falta un combate');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Reopen phase'));
      await tester.pumpAndSettle();

      expect(phases.calls, ['start', 'finish', 'reopen Falta un combate']);
      expect(find.text('Phase in progress'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a helper sees the state but cannot change it', (tester) async {
    await pumpBar(
      tester,
      FakePhaseRepository(const Phase(state: PhaseState.finished)),
      isClub: false,
    );

    expect(find.text('Phase finished: read only'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });
}
