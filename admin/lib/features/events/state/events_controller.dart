import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/admin_session.dart';
import '../data/events_api.dart';

final eventsApiProvider = Provider<EventsApi>(
  (ref) => EventsApi(ref.watch(adminDioProvider)),
);

/// The page of the events list, from 0.
final eventsPageProvider = NotifierProvider<EventsPageController, int>(
  EventsPageController.new,
);

class EventsPageController extends Notifier<int> {
  @override
  int build() => 0;

  void go(int page) => state = page;
}

// No automatic retry: the screen shows the error with its own retry button.
final eventsProvider =
    AsyncNotifierProvider.autoDispose<EventsController, AdminEventPage>(
      EventsController.new,
      retry: (_, _) => null,
    );

class EventsController extends AsyncNotifier<AdminEventPage> {
  @override
  Future<AdminEventPage> build() =>
      ref.read(eventsApiProvider).list(page: ref.watch(eventsPageProvider));

  void refresh() => ref.invalidateSelf();
}

/// The event open in the tab; null shows the list.
final selectedEventProvider =
    NotifierProvider<SelectedEventController, String?>(
      SelectedEventController.new,
    );

class SelectedEventController extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String eventId) => state = eventId;

  void close() => state = null;
}

final eventDetailProvider = AsyncNotifierProvider.autoDispose
    .family<EventDetailController, AdminEventDetail, String>(
      EventDetailController.new,
      retry: (_, _) => null,
    );

/// An event's mats, groups and matches; every operation reloads it (and the list's counts).
class EventDetailController extends AsyncNotifier<AdminEventDetail> {
  EventDetailController(this.eventId);

  final String eventId;

  EventsApi get _api => ref.read(eventsApiProvider);

  @override
  Future<AdminEventDetail> build() => _api.detail(eventId);

  void refresh() => ref.invalidateSelf();

  Future<void> resetMatch(String matchId, String reason) =>
      _run(() => _api.resetMatch(matchId, reason));

  Future<void> dissolveGroup(String groupId, String reason) =>
      _run(() => _api.dissolveGroup(groupId, reason));

  Future<Cleared> clearCompetition(String reason) =>
      _run(() => _api.clearCompetition(eventId, reason));

  // Reloads after it, and after a 404 too: the match or group was already gone.
  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      _reload();
      return result;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) _reload();
      rethrow;
    }
  }

  void _reload() {
    if (!ref.mounted) return;
    ref
      ..invalidateSelf()
      ..invalidate(eventsProvider);
  }
}
