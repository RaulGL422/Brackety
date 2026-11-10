import 'package:brackety_admin/features/users/data/users_api.dart';
import 'package:brackety_admin/features/users/state/users_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

AdminUserRow user(
  String id, {
  bool suspended = false,
  bool deleted = false,
  List<String> profiles = const ['HELPER'],
  String? organization,
}) => AdminUserRow(
  id: id,
  email: '$id@example.test',
  createdAt: DateTime.utc(2026, 11, 1),
  emailVerified: true,
  deleted: deleted,
  suspended: suspended,
  profiles: profiles,
  organization: organization,
);

class FakeUsersApi implements UsersApi {
  FakeUsersApi(this.users);

  List<AdminUserRow> users;
  final queries = <String>[];
  final calls = <String>[];
  DioException? deleteError;

  @override
  Future<AdminUserPage> list({
    required String query,
    required int page,
    int size = 20,
  }) async {
    queries.add(query);
    final matched = [
      for (final u in users)
        if (query.isEmpty || u.email.contains(query)) u,
    ];
    return AdminUserPage(
      items: matched,
      page: page,
      size: size,
      total: matched.length,
    );
  }

  @override
  Future<AdminUserDetail> detail(String accountId) async => AdminUserDetail(
    user: users.firstWhere((u) => u.id == accountId),
    signInMethods: const ['PASSWORD', 'GOOGLE'],
    ownedEvents: accountId == 'club1' ? 1 : 0,
    staffEvents: 1,
    lastSignIn: DateTime.utc(2026, 11, 9),
  );

  void _replace(String id, AdminUserRow Function(AdminUserRow) change) {
    users = [for (final u in users) u.id == id ? change(u) : u];
  }

  @override
  Future<void> suspend(String accountId, String reason) async {
    calls.add('suspend $accountId: $reason');
    _replace(
      accountId,
      (u) => user(u.id, suspended: true, profiles: u.profiles),
    );
  }

  @override
  Future<void> unsuspend(String accountId, String reason) async {
    calls.add('unsuspend $accountId: $reason');
    _replace(accountId, (u) => user(u.id, profiles: u.profiles));
  }

  @override
  Future<DateTime> delete(String accountId, String reason) async {
    if (deleteError case final e?) throw e;
    calls.add('delete $accountId: $reason');
    _replace(accountId, (u) => user(u.id, deleted: true, profiles: u.profiles));
    return DateTime(2026, 12, 10);
  }
}

void main() {
  Future<FakeUsersApi> open(WidgetTester tester) async {
    final api = FakeUsersApi([
      user('club1', profiles: ['CLUB'], organization: 'Club Deportivo Ejemplo'),
      user('arbitro1', profiles: ['HELPER', 'STUDENT']),
    ]);
    await pumpAdmin(
      tester,
      location: '/users',
      overrides: [usersApiProvider.overrideWithValue(api)],
    );
    return api;
  }

  Future<void> confirmWithReason(
    WidgetTester tester,
    String action, {
    String? typed,
  }) async {
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, 'Pedido por el club');
    if (typed != null) await tester.enterText(fields.last, typed);
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, action),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('users list and detail fit on $device', (tester) async {
      useSize(tester, size);
      await open(tester);

      expect(find.text('club1@example.test'), findsOneWidget);
      expect(find.text('Club Deportivo Ejemplo'), findsOneWidget);
      expect(find.text('Helper, Student'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('arbitro1@example.test'));
      await tester.pumpAndSettle();
      expect(find.text('Password, GOOGLE'), findsOneWidget);
      expect(find.text('Suspend'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a search goes to the server and starts on page one', (
    tester,
  ) async {
    useSize(tester, screenSizes['desktop']!);
    final api = await open(tester);

    await tester.enterText(find.byType(TextFormField), ' arbitro ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(api.queries.last, 'arbitro');
    expect(find.text('club1@example.test'), findsNothing);
    expect(find.text('arbitro1@example.test'), findsOneWidget);
  });

  testWidgets('suspending and lifting it ask a reason and change the state', (
    tester,
  ) async {
    useSize(tester, screenSizes['desktop']!);
    final api = await open(tester);
    await tester.tap(find.text('arbitro1@example.test'));
    await tester.pumpAndSettle();

    await tapText(tester, 'Suspend');
    await confirmWithReason(tester, 'Suspend');
    expect(find.text('Account suspended.'), findsOneWidget);
    expect(find.text('Suspended'), findsOneWidget);

    await tapText(tester, 'Lift the suspension');
    await confirmWithReason(tester, 'Lift the suspension');
    expect(api.calls, [
      'suspend arbitro1: Pedido por el club',
      'unsuspend arbitro1: Pedido por el club',
    ]);
    expect(find.text('Suspend'), findsOneWidget);
  });

  testWidgets(
    'deleting needs the email typed; an owner of events is told why',
    (tester) async {
      useSize(tester, screenSizes['desktop']!);
      final api = await open(tester);
      await tester.tap(find.text('club1@example.test'));
      await tester.pumpAndSettle();
      api.deleteError = dioError(409, data: {'code': 'OWNS_EVENTS'});

      await tapText(tester, 'Delete the account');
      await confirmWithReason(
        tester,
        'Delete the account',
        typed: 'club1@example.test',
      );

      expect(
        find.text(
          'This account owns events: hand them over or delete them first.',
        ),
        findsOneWidget,
      );
      expect(api.calls, isEmpty);
    },
  );

  testWidgets('a deleted account says when it goes and offers no actions', (
    tester,
  ) async {
    useSize(tester, screenSizes['desktop']!);
    final api = await open(tester);
    await tester.tap(find.text('arbitro1@example.test'));
    await tester.pumpAndSettle();

    await tapText(tester, 'Delete the account');
    await confirmWithReason(
      tester,
      'Delete the account',
      typed: 'arbitro1@example.test',
    );

    expect(api.calls, ['delete arbitro1: Pedido por el club']);
    expect(find.textContaining('It goes for good on'), findsOneWidget);
    expect(find.text('Deleted, awaiting purge'), findsOneWidget);
    expect(find.text('Suspend'), findsNothing);
  });
}
