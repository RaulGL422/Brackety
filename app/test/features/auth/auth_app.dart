import 'package:brackety/app.dart';
import 'package:brackety/core/router.dart';
import 'package:brackety/features/auth/state/auth_providers.dart';
import 'package:brackety/features/events/state/events_providers.dart';
import 'package:brackety/features/legal/data/legal_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fakes.dart';
import '../../support/legal_fakes.dart';

const screenSizes = {
  'phone': Size(360, 800),
  'tablet': Size(800, 1280),
  'desktop': Size(1440, 900),
};

void useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The whole app on [api] (and [account] for `/me`, [legal] for the legal texts), opened at
/// [location]; "today" is 2026-10-31 and `APP_ENV` is not dev unless [devEnvironment].
Future<GoRouter> pumpAuthApp(
  WidgetTester tester,
  FakeAuthApi api, {
  String? location,
  bool devEnvironment = false,
  FakeAccountApi? account,
  FakeLegalRepository? legal,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...sessionOverrides(api, account: account),
        ...overrides,
        todayProvider.overrideWithValue(DateTime(2026, 10, 31)),
        devEnvironmentProvider.overrideWithValue(devEnvironment),
        myEventsProvider.overrideWith((ref) async => []),
        legalRepositoryProvider.overrideWithValue(
          legal ?? FakeLegalRepository(),
        ),
      ],
      child: const BracketyApp(),
    ),
  );
  await tester.pumpAndSettle();
  final router = ProviderScope.containerOf(
    tester.element(find.byType(BracketyApp)),
  ).read(routerProvider);
  if (location != null) {
    router.go(location);
    await tester.pumpAndSettle();
  }
  return router;
}

/// Taps the button with [text] (titles often repeat it), or else the text itself.
Future<void> tapText(WidgetTester tester, String text) async {
  final button = find.ancestor(
    of: find.text(text),
    matching: find.bySubtype<ButtonStyleButton>(),
  );
  final target = button.evaluate().isNotEmpty
      ? button.last
      : find.text(text).last;
  await tester.ensureVisible(target);
  // A ListView lays the jump out on the next frame, and a focused field may still be scrolling
  // itself into view (the scroll ignores taps until it stops).
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}
