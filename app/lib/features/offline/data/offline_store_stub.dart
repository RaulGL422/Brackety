import 'offline_store.dart';

/// The web keeps nothing: it has no offline queue.
OfflineStore deviceOfflineStore() => const _NoStore();

class _NoStore implements OfflineStore {
  const _NoStore();

  @override
  Future<Object?> read(String name) async => null;

  @override
  Future<void> write(String name, Object? json) async {}

  @override
  Future<void> clear({Set<String> keep = const {}}) async {}
}
