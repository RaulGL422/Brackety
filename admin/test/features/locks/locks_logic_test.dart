import 'package:brackety_admin/features/locks/data/locks_api.dart';
import 'package:brackety_admin/features/locks/state/locks_controller.dart';
import 'package:brackety_admin/features/locks/ui/lock_texts.dart';
import 'package:brackety_admin/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fakes.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  setUpAll(() => initializeDateFormatting('en'));

  ProviderContainer containerWith(FakeLocksApi api) {
    final container = ProviderContainer(
      overrides: [locksApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    // autoDispose: keep it alive like the screen does.
    container.listen(locksProvider, (_, _) {});
    return container;
  }

  test('lock json with and without who', () {
    final email = Lock.fromJson({
      'lockId': 'L-1',
      'type': 'EMAIL',
      'lockedUntil': '2026-11-02T10:12:00Z',
      'email': 'bloqueada@example.test',
      'ip': null,
    });
    expect(email.type, LockType.email);
    expect(email.lockedUntil, now.add(const Duration(minutes: 12)));
    expect(lockTarget(l10n, email), 'bloqueada@example.test');

    final unknown = Lock.fromJson({
      'lockId': 'L-2',
      'type': 'EMAIL',
      'lockedUntil': '2026-11-02T10:12:00Z',
    });
    expect(lockTarget(l10n, unknown), l10n.lockUnknownEmail);
    expect(
      Lock.fromJson({...unknown.asJson, 'type': 'ADMIN'}).type,
      LockType.admin,
    );
  });

  test('time left rounds minutes up and says when it is over', () {
    final lock = Lock(
      lockId: 'L-1',
      type: LockType.ip,
      lockedUntil: now.add(const Duration(minutes: 11, seconds: 1)),
    );
    expect(lockTimeLeft(l10n, lock, now), startsWith('12 min left'));
    expect(
      lockTimeLeft(l10n, lock, now.add(const Duration(minutes: 11))),
      startsWith('1 min left'),
    );
    expect(
      lockTimeLeft(l10n, lock, now.add(const Duration(minutes: 12))),
      l10n.lockExpired,
    );
  });

  test('revoking removes the lock from the list', () async {
    final api = FakeLocksApi([
      lock('L-1', LockType.email, email: 'a@example.test'),
      lock('L-2', LockType.ip, ip: '198.51.100.66'),
    ]);
    final container = containerWith(api);
    await container.read(locksProvider.future);

    final result = await container.read(locksProvider.notifier).revoke('L-1');

    expect(result, RevokeResult.revoked);
    expect(container.read(locksProvider).value!.map((l) => l.lockId), ['L-2']);
  });

  test('an expired lock (404) reloads the list', () async {
    final api = FakeLocksApi([lock('L-1', LockType.admin)]);
    final container = containerWith(api);
    await container.read(locksProvider.future);
    api
      ..revokeError = dioError(404)
      ..locks = [];

    final result = await container.read(locksProvider.notifier).revoke('L-1');

    expect(result, RevokeResult.alreadyExpired);
    expect(await container.read(locksProvider.future), isEmpty);
    expect(api.lists, 2);
  });
}

extension on Lock {
  Map<String, dynamic> get asJson => {
    'lockId': lockId,
    'type': 'EMAIL',
    'lockedUntil': lockedUntil.toIso8601String(),
  };
}
