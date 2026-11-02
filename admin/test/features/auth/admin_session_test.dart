import 'package:brackety_admin/features/auth/state/admin_session.dart';
import 'package:brackety_admin/features/locks/state/locks_controller.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  ProviderContainer containerWith(FakeAdapter adapter) {
    final container = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(fakeDio(adapter))],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('login keeps the token in memory and logout drops it', () async {
    final adapter = FakeAdapter(
      (_) => (200, {'accessToken': 'admin-token', 'expiresIn': 3600}),
    );
    final container = containerWith(adapter);
    final session = container.read(adminSessionProvider.notifier);

    await session.login(' superadmin@example.test ', 'brackety-demo');

    expect(container.read(adminSessionProvider).token, 'admin-token');
    expect(adapter.requests.single.path, '/api/v1/admin/auth/login');
    expect(adapter.requests.single.data, {
      'email': 'superadmin@example.test',
      'password': 'brackety-demo',
    });

    session.logout();

    final state = container.read(adminSessionProvider);
    expect(state.signedIn, isFalse);
    expect(state.expired, isFalse);
  });

  test('a wrong password fails without ending in "expired"', () async {
    final container = containerWith(FakeAdapter((_) => (401, null)));

    await expectLater(
      container.read(adminSessionProvider.notifier).login('a@b.c', 'x'),
      throwsA(isA<DioException>()),
    );

    final state = container.read(adminSessionProvider);
    expect(state.signedIn, isFalse);
    expect(state.expired, isFalse);
  });

  test('admin calls carry the token and a 401 signs out as expired', () async {
    final adapter = FakeAdapter(
      (options) => options.path.endsWith('/login')
          ? (200, {'accessToken': 'admin-token', 'expiresIn': 3600})
          : (401, null),
    );
    final container = containerWith(adapter);
    await container
        .read(adminSessionProvider.notifier)
        .login('superadmin@example.test', 'brackety-demo');

    await expectLater(
      container.read(locksApiProvider).list(),
      throwsA(isA<DioException>()),
    );

    expect(
      adapter.requests.last.headers['Authorization'],
      'Bearer admin-token',
    );
    final state = container.read(adminSessionProvider);
    expect(state.signedIn, isFalse);
    expect(state.expired, isTrue);
  });

  test('a late 401 for an old token keeps the new session', () {
    final container = containerWith(FakeAdapter((_) => (200, null)));
    container.read(adminSessionProvider.notifier).expired('old-token');

    expect(container.read(adminSessionProvider).expired, isFalse);
  });
}
