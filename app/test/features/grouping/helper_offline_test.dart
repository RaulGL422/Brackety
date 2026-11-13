import 'dart:convert';
import 'dart:typed_data';

import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:brackety/features/grouping/state/helper_queue.dart';
import 'package:brackety/features/offline/data/offline_get_cache.dart';
import 'package:brackety/features/offline/data/offline_store.dart';
import 'package:brackety/features/offline/state/offline_sync.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/offline_fakes.dart';

/// A server that can be unreachable, answers GETs with [lists] and POSTs with [postStatus].
class _Server implements HttpClientAdapter {
  var down = false;
  var postStatus = 201;
  final lists = <String, Object?>{};
  final posted = <String>[];
  var gets = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET') gets++;
    if (down) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'unreachable',
      );
    }
    if (options.method == 'POST') {
      posted.add(options.path);
      return ResponseBody.fromString(
        '{}',
        postStatus,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(lists[options.path] ?? {}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Server server;
  late MemoryOfflineStore store;

  ProviderContainer device() {
    final container = ProviderContainer(
      overrides: [
        ...sessionOverrides(FakeAuthApi(signedIn: true)),
        offlineStoreProvider.overrideWithValue(store),
        apiProvider.overrideWith((ref) {
          final dio = Dio(BaseOptions(baseUrl: 'http://hall'))
            ..httpClientAdapter = server;
          dio.interceptors.add(OfflineGetCache(ref));
          return dio;
        }),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    server = _Server();
    store = MemoryOfflineStore();
  });

  test('the lists a helper reads come from the device without network', () async {
    const path = '/api/v1/events/e1/categories/c1/participants';
    server.lists[path] = [
      {'id': 'p1'},
    ];
    final container = device();
    final api = container.read(apiProvider);

    expect((await api.get<Object?>(path)).data, [
      {'id': 'p1'},
    ]);
    server.down = true;
    final offline = await api.get<Object?>(path);
    expect(offline.data, [
      {'id': 'p1'},
    ]);
    expect(offline.extra['offline'], isTrue);
    expect(container.read(offlineSyncProvider).connected, isFalse);

    // Known to be offline: straight from the device, without asking the server.
    final before = server.gets;
    expect((await api.get<Object?>(path)).data, isNotNull);
    expect(server.gets, before);
  });

  test(
    'a group made without network goes when the server answers again',
    () async {
      final container = device();
      final queue = container.read(helperQueueProvider.notifier);
      container.read(offlineSyncProvider);
      server.down = true;

      await queue.add(
        path: '/api/v1/events/e1/groups',
        body: {'categoryId': 'c1'},
        label: 'el grupo de Ana',
        people: ['p1', 'p2'],
      );
      await queue.send();
      expect(container.read(helperQueueProvider).people, {'p1', 'p2'});
      expect(store.docs['helper-queue'], hasLength(1));

      server.down = false;
      container.read(offlineSyncProvider.notifier).reportResponse();
      await pumpEventQueue();

      expect(server.posted, ['/api/v1/events/e1/groups']);
      expect(container.read(helperQueueProvider).pending, isEmpty);
      expect(container.read(helperQueueProvider).results.single, (
        label: 'el grupo de Ana',
        created: true,
      ));
    },
  );

  test(
    'a queued group someone else took meanwhile is dropped and reported',
    () async {
      final container = device();
      final queue = container.read(helperQueueProvider.notifier);
      server.postStatus = 409;

      await queue.add(
        path: '/api/v1/events/e1/groups',
        body: {'categoryId': 'c1'},
        label: 'el grupo de Ana',
      );
      await queue.send();

      expect(container.read(helperQueueProvider).pending, isEmpty);
      expect(
        container.read(helperQueueProvider).results.single.created,
        isFalse,
      );
    },
  );
}
