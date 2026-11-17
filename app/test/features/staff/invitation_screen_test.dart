import 'package:brackety/features/staff/data/staff_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/staff_fakes.dart';
import '../auth/auth_app.dart';

void main() {
  InvitationOffer offer({bool forYou = true}) => InvitationOffer(
    eventName: 'Liga Yoseikan · Fase 2',
    eventDate: DateTime(2027, 1, 24),
    organizer: 'C.D. Artes Marciales Vejer',
    role: StaffRole.referee,
    email: 'ana@example.test',
    forYou: forYou,
  );

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('the invited account accepts on $device', (tester) async {
      useSize(tester, size);
      final staff = FakeStaffRepository(offered: offer());
      await pumpAuthApp(
        tester,
        FakeAuthApi(signedIn: true),
        location: '/invitation?token=t1',
        overrides: [staffRepositoryProvider.overrideWithValue(staff)],
      );

      expect(
        find.text('C.D. Artes Marciales Vejer invites you as a referee to:'),
        findsOneWidget,
      );
      expect(find.text('Liga Yoseikan · Fase 2'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
      await tester.pumpAndSettle();

      expect(staff.calls, ['accept t1']);
      expect(find.text('You are in the event'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('another account is told whose invitation it is', (tester) async {
    final staff = FakeStaffRepository(offered: offer(forYou: false));
    await pumpAuthApp(
      tester,
      FakeAuthApi(signedIn: true),
      location: '/invitation?token=t1',
      overrides: [staffRepositoryProvider.overrideWithValue(staff)],
    );

    expect(
      find.textContaining('This invitation is for ana@example.test'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Accept'), findsNothing);
    expect(find.text('Sign in with another account'), findsOneWidget);
  });

  testWidgets('a used or expired link says so', (tester) async {
    await pumpAuthApp(
      tester,
      FakeAuthApi(signedIn: true),
      location: '/invitation?token=bad',
      overrides: [
        staffRepositoryProvider.overrideWithValue(FakeStaffRepository()),
      ],
    );

    expect(find.textContaining('was used or has expired'), findsOneWidget);
  });

  testWidgets('signed out, the link waits for the sign-in', (tester) async {
    final router = await pumpAuthApp(
      tester,
      FakeAuthApi(),
      location: '/invitation?token=t1',
      overrides: [
        staffRepositoryProvider.overrideWithValue(
          FakeStaffRepository(offered: offer()),
        ),
      ],
    );

    expect(
      router.routeInformationProvider.value.uri.toString(),
      startsWith('/login?from='),
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['from'],
      '/invitation?token=t1',
    );
  });
}
