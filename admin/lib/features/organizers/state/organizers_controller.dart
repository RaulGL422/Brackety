import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/admin_session.dart';
import '../data/organizers_api.dart';

final organizersApiProvider = Provider<OrganizersApi>(
  (ref) => OrganizersApi(ref.watch(adminDioProvider)),
);

enum OrganizerFilter { pending, validated, all }

final organizerFilterProvider =
    NotifierProvider.autoDispose<OrganizerFilterController, OrganizerFilter>(
      OrganizerFilterController.new,
    );

class OrganizerFilterController extends Notifier<OrganizerFilter> {
  @override
  OrganizerFilter build() => OrganizerFilter.pending;

  void select(OrganizerFilter filter) => state = filter;
}

enum ValidateResult { validated, notFound }

// No automatic retry: the screen shows the error with its own retry button.
final organizersProvider =
    AsyncNotifierProvider.autoDispose<OrganizersController, List<Organizer>>(
      OrganizersController.new,
      retry: (_, _) => null,
    );

class OrganizersController extends AsyncNotifier<List<Organizer>> {
  @override
  Future<List<Organizer>> build() {
    final filter = ref.watch(organizerFilterProvider);
    return ref
        .read(organizersApiProvider)
        .list(
          validated: switch (filter) {
            OrganizerFilter.pending => false,
            OrganizerFilter.validated => true,
            OrganizerFilter.all => null,
          },
        );
  }

  void refresh() => ref.invalidateSelf();

  /// Validated rows leave the pending list and change state elsewhere. A 404 (no longer an
  /// organizer) reloads the list. Other failures are thrown.
  Future<ValidateResult> validate(String accountId) async {
    try {
      await ref.read(organizersApiProvider).validate(accountId);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      if (ref.mounted) ref.invalidateSelf();
      return ValidateResult.notFound;
    }
    final organizers = state.value;
    if (ref.mounted && organizers != null) {
      final pendingOnly =
          ref.read(organizerFilterProvider) == OrganizerFilter.pending;
      state = AsyncData([
        for (final organizer in organizers)
          if (organizer.accountId != accountId)
            organizer
          else if (!pendingOnly)
            organizer.asValidated(),
      ]);
    }
    return ValidateResult.validated;
  }
}
