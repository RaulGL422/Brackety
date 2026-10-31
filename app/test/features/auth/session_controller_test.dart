import 'dart:async';
import 'dart:typed_data';

import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  ProviderContainer containerFor(
    FakeAuthApi api,
    FakeRefreshTokenStore store, {
    Dio? dio,
  }) {
    final container = ProviderContainer(
      overrides: [
        ...sessionOverrides(api, store: store),
        if (dio != null) dioProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<SessionState> restore(ProviderContainer container) async {
    container.read(sessionProvider);
    await pumpEventQueue();
    return container.read(sessionProvider);
  }

  group('startup restore', () {
    test('the web tries its cookie', () async {
      final api = FakeAuthApi(signedIn: true);
      final container = containerFor(
        api,
        FakeRefreshTokenStore(inCookie: true),
      );

      final state = await restore(container);

      expect(state.status, SessionStatus.signedIn);
      expect(state.accessToken, 'access-1');
      expect(api.refreshes, [null]);
    });

    test('the web without a valid cookie is signed out', () async {
      final container = containerFor(
        FakeAuthApi(),
        FakeRefreshTokenStore(inCookie: true),
      );

      expect((await restore(container)).status, SessionStatus.signedOut);
    });

    test('the web without network is signed out', () async {
      final api = FakeAuthApi(signedIn: true)..refreshError = networkError();
      final container = containerFor(
        api,
        FakeRefreshTokenStore(inCookie: true),
      );

      expect((await restore(container)).status, SessionStatus.signedOut);
    });

    test('Android without a stored token asks nothing', () async {
      final api = FakeAuthApi(signedIn: true, issueRefreshTokens: true);
      final container = containerFor(api, FakeRefreshTokenStore());

      expect((await restore(container)).status, SessionStatus.signedOut);
      expect(api.refreshes, isEmpty);
    });

    test(
      'Android refreshes with its stored token and keeps the rotated one',
      () async {
        final api = FakeAuthApi(signedIn: true, issueRefreshTokens: true);
        final store = FakeRefreshTokenStore(token: 'stored');
        final container = containerFor(api, store);

        final state = await restore(container);

        expect(api.refreshes, ['stored']);
        expect(store.token, 'refresh-1');
        expect(state.status, SessionStatus.signedIn);
        expect(state.accessToken, 'access-1');
      },
    );

    test(
      'Android without network stays signed in, without an access token',
      () async {
        final api = FakeAuthApi(signedIn: true, issueRefreshTokens: true)
          ..refreshError = networkError();
        final store = FakeRefreshTokenStore(token: 'stored');
        final container = containerFor(api, store);

        final state = await restore(container);

        expect(state.status, SessionStatus.signedIn);
        expect(state.accessToken, isNull);
        expect(store.token, 'stored');
      },
    );
  });

  group('refresh', () {
    test('concurrent calls share one request', () async {
      final api = FakeAuthApi(signedIn: true);
      final container = containerFor(
        api,
        FakeRefreshTokenStore(inCookie: true),
      );
      await restore(container);
      api.refreshGate = Completer();

      final controller = container.read(sessionProvider.notifier);
      final first = controller.refresh();
      final second = controller.refresh();
      api.refreshGate!.complete();

      expect(await first, 'access-2');
      expect(await second, 'access-2');
      expect(api.refreshes, [null, null]);
    });

    test('a 401 from the server signs out and clears the storage', () async {
      final api = FakeAuthApi(signedIn: true, issueRefreshTokens: true);
      final store = FakeRefreshTokenStore(token: 'stored');
      final container = containerFor(api, store);
      await restore(container);
      api.refreshError = httpError(401);

      expect(await container.read(sessionProvider.notifier).refresh(), isNull);
      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(store.token, isNull);
    });

    test('a network error keeps the session and the stored token', () async {
      final api = FakeAuthApi(signedIn: true, issueRefreshTokens: true);
      final store = FakeRefreshTokenStore(token: 'stored');
      final container = containerFor(api, store);
      await restore(container);
      api.refreshError = networkError();

      expect(await container.read(sessionProvider.notifier).refresh(), isNull);
      expect(container.read(sessionProvider).status, SessionStatus.signedIn);
      expect(store.token, 'refresh-1');
    });
  });

  test(
    'login on Android stores the refresh token and tracks the verification',
    () async {
      final api = FakeAuthApi(issueRefreshTokens: true)..emailVerified = false;
      final store = FakeRefreshTokenStore();
      final container = containerFor(api, store);
      await restore(container);

      await container.read(sessionProvider.notifier).login(' club1 ', 'club1');

      final state = container.read(sessionProvider);
      expect(state.status, SessionStatus.signedIn);
      expect(state.emailVerified, isFalse);
      expect(store.token, 'refresh-1');
    },
  );

  test(
    'logout clears the storage and revokes the token on the server',
    () async {
      final api = FakeAuthApi(signedIn: true, issueRefreshTokens: true);
      final store = FakeRefreshTokenStore(token: 'stored');
      final container = containerFor(api, store);
      await restore(container);

      await container.read(sessionProvider.notifier).logout();

      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(store.token, isNull);
      expect(api.logouts, ['refresh-1']);
    },
  );

  test(
    'logout during a refresh waits for it and revokes the rotated token',
    () async {
      final api = FakeAuthApi(signedIn: true, issueRefreshTokens: true);
      final store = FakeRefreshTokenStore(token: 'stored');
      final container = containerFor(api, store);
      await restore(container);
      final gate = api.refreshGate = Completer<void>();
      final notifier = container.read(sessionProvider.notifier);

      final refreshing = notifier.refresh();
      final loggingOut = notifier.logout();
      gate.complete();
      await Future.wait([refreshing, loggingOut]);

      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(store.token, isNull);
      expect(api.logouts, ['refresh-2']);
    },
  );

  test('a password reset signs this device out too', () async {
    final api = FakeAuthApi(signedIn: true, issueRefreshTokens: true);
    final store = FakeRefreshTokenStore(token: 'stored');
    final container = containerFor(api, store);
    await restore(container);

    await container
        .read(sessionProvider.notifier)
        .resetPassword('t', 'new password');

    expect(container.read(sessionProvider).status, SessionStatus.signedOut);
    expect(store.token, isNull);
  });

  test('a verified email renews the session with a verified token', () async {
    final api = FakeAuthApi(signedIn: true)..emailVerified = false;
    final container = containerFor(api, FakeRefreshTokenStore(inCookie: true));
    expect((await restore(container)).emailVerified, isFalse);
    api.emailVerified = true;

    await container.read(sessionProvider.notifier).emailVerified();

    final state = container.read(sessionProvider);
    expect(state.emailVerified, isTrue);
    expect(state.accessToken, 'access-2');
  });

  test('apiProvider: concurrent 401s share one refresh and each request is retried once', () async {
    final api = FakeAuthApi(signedIn: true);
    final adapter = _TokenCheckingAdapter('Bearer access-2');
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    final container = containerFor(
      api,
      FakeRefreshTokenStore(inCookie: true),
      dio: dio,
    );
    await restore(container);
    final client = container.read(apiProvider);

    api.refreshGate = Completer();

    final requests = Future.wait([
      client.get<Map<String, dynamic>>('/a'),
      client.get<Map<String, dynamic>>('/b'),
    ]);
    await pumpEventQueue();
    api.refreshGate!.complete();
    final responses = await requests;

    expect(responses.map((r) => r.statusCode), [200, 200]);
    expect(api.refreshes, [null, null]);
    expect(adapter.seen, [
      'Bearer access-1',
      'Bearer access-1',
      'Bearer access-2',
      'Bearer access-2',
    ]);
  });
}

/// Answers 200 only to [valid]; any other token gets a 401.
class _TokenCheckingAdapter implements HttpClientAdapter {
  _TokenCheckingAdapter(this.valid);

  final String valid;
  final seen = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization'] as String?;
    seen.add(auth);
    return auth == valid
        ? ResponseBody.fromString(
            '{"ok":true}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          )
        : ResponseBody.fromString('', 401);
  }

  @override
  void close({bool force = false}) {}
}
