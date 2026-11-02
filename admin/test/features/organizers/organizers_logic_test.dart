import 'package:brackety_admin/features/organizers/data/organizers_api.dart';
import 'package:brackety_admin/features/organizers/state/organizers_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  ProviderContainer containerWith(FakeOrganizersApi api) {
    final container = ProviderContainer(
      overrides: [organizersApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    // autoDispose: keep it alive like the screen does.
    container.listen(organizersProvider, (_, _) {});
    return container;
  }

  List<String> ids(ProviderContainer container) => [
    for (final o in container.read(organizersProvider).value!) o.accountId,
  ];

  test('organizer json, with name and CIF still missing', () {
    final o = Organizer.fromJson({
      'accountId': 'acc-1',
      'email': 'club@example.test',
      'profileType': 'EXTERNAL_ENTITY',
      'validated': false,
      'organizationName': null,
      'taxId': null,
      'createdAt': '2026-10-30T12:00:00Z',
    });
    expect(o.type, OrganizerType.externalEntity);
    expect(o.organizationName, isNull);
    expect(o.createdAt, DateTime.utc(2026, 10, 30, 12));
  });

  test('the filter picks the query, pending first', () async {
    final api = FakeOrganizersApi([]);
    final container = containerWith(api);
    await container.read(organizersProvider.future);

    for (final filter in [OrganizerFilter.validated, OrganizerFilter.all]) {
      container.read(organizerFilterProvider.notifier).select(filter);
      await container.read(organizersProvider.future);
    }

    expect(api.queries, [false, true, null]);
  });

  test('validating leaves the pending list', () async {
    final api = FakeOrganizersApi([organizer('a'), organizer('b')]);
    final container = containerWith(api);
    await container.read(organizersProvider.future);

    final result = await container
        .read(organizersProvider.notifier)
        .validate('a');

    expect(result, ValidateResult.validated);
    expect(ids(container), ['b']);
  });

  test('validating in "all" keeps the row, now validated', () async {
    final api = FakeOrganizersApi([organizer('a')]);
    final container = containerWith(api);
    container
        .read(organizerFilterProvider.notifier)
        .select(OrganizerFilter.all);
    await container.read(organizersProvider.future);

    await container.read(organizersProvider.notifier).validate('a');

    expect(container.read(organizersProvider).value!.single.validated, isTrue);
  });

  test('404 reloads the list', () async {
    final api = FakeOrganizersApi([organizer('a')]);
    final container = containerWith(api);
    await container.read(organizersProvider.future);
    api
      ..validateError = dioError(404)
      ..organizers = [];

    final result = await container
        .read(organizersProvider.notifier)
        .validate('a');

    expect(result, ValidateResult.notFound);
    expect(await container.read(organizersProvider.future), isEmpty);
  });
}
