import 'package:brackety_admin/features/locks/data/locks_api.dart';
import 'package:brackety_admin/features/locks/ui/lock_tile.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  FakeLocksApi seeded() => FakeLocksApi([
    lock('L-EMAIL', LockType.email, email: 'bloqueada@example.test'),
    lock('L-IP', LockType.ip, ip: '198.51.100.66'),
    lock('L-ADMIN', LockType.admin),
  ]);

  Future<void> revoke(WidgetTester tester, String lockId) async {
    final row = find.ancestor(
      of: find.text(lockId),
      matching: find.byType(LockTile),
    );
    await tester.tap(
      find.descendant(
        of: row,
        matching: find.widgetWithText(TextButton, 'Revoke'),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('locks show type, who and time left on $device', (
      tester,
    ) async {
      useSize(tester, size);
      await pumpAdmin(tester, locks: seeded(), location: '/locks');

      expect(find.text('Active locks'), findsOneWidget);
      expect(find.text('bloqueada@example.test'), findsOneWidget);
      expect(find.text('198.51.100.66'), findsOneWidget);
      expect(find.text('Superadmin'), findsOneWidget);
      expect(find.textContaining('12 min left'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('revoking asks first and removes the lock on $device', (
      tester,
    ) async {
      useSize(tester, size);
      await pumpAdmin(tester, locks: seeded(), location: '/locks');

      await revoke(tester, 'L-IP');

      expect(find.text('Revoke lock L-IP?'), findsOneWidget);
      expect(
        tester
            .getSize(
              find.text(
                'Its failed attempts are cleared and signing in works again right away.',
              ),
            )
            .width,
        lessThanOrEqualTo(AppSizes.formMaxWidth),
      );
      await tapText(tester, 'Revoke');

      expect(find.text('198.51.100.66'), findsNothing);
      expect(find.text('Lock L-IP revoked.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cancelling keeps the lock', (tester) async {
    useSize(tester, screenSizes['phone']!);
    await pumpAdmin(tester, locks: seeded(), location: '/locks');

    await revoke(tester, 'L-IP');
    await tapText(tester, 'Cancel');

    expect(find.text('198.51.100.66'), findsOneWidget);
  });

  testWidgets('an already expired lock says so and refreshes', (tester) async {
    useSize(tester, screenSizes['desktop']!);
    final api = seeded()..revokeError = dioError(404);
    await pumpAdmin(tester, locks: api, location: '/locks');
    api.locks = [api.locks.first];

    await revoke(tester, 'L-IP');
    await tapText(tester, 'Revoke');

    expect(
      find.text('That lock had already expired. List refreshed.'),
      findsOneWidget,
    );
    expect(find.text('198.51.100.66'), findsNothing);
    expect(api.lists, 2);
  });

  testWidgets('no locks shows the empty state', (tester) async {
    useSize(tester, screenSizes['phone']!);
    await pumpAdmin(tester, locks: FakeLocksApi([]), location: '/locks');

    expect(find.text('No active locks.'), findsOneWidget);
  });

  testWidgets('a failed load can be retried, and refresh reloads', (
    tester,
  ) async {
    useSize(tester, screenSizes['tablet']!);
    final api = seeded()..listError = networkError();
    await pumpAdmin(tester, locks: api, location: '/locks');

    expect(find.text('Could not load the data.'), findsOneWidget);

    api.listError = null;
    await tapText(tester, 'Retry');
    expect(find.text('198.51.100.66'), findsOneWidget);

    api.locks = [];
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('No active locks.'), findsOneWidget);
  });
  for (final device in ['phone', 'desktop']) {
    testWidgets('locks lay out with text at 200 % on $device', (tester) async {
      useSize(tester, screenSizes[device]!);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpAdmin(tester, locks: seeded(), location: '/locks');

      expect(find.text('L-EMAIL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
