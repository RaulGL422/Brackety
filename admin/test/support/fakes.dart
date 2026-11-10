import 'dart:convert';
import 'dart:typed_data';

import 'package:brackety_admin/app.dart';
import 'package:brackety_admin/core/clock.dart';
import 'package:brackety_admin/core/router.dart';
import 'package:brackety_admin/features/auth/data/admin_auth_api.dart';
import 'package:brackety_admin/features/auth/state/admin_session.dart';
import 'package:brackety_admin/features/dashboard/data/metrics_api.dart';
import 'package:brackety_admin/features/dashboard/state/metrics_controller.dart';
import 'package:brackety_admin/features/locks/data/locks_api.dart';
import 'package:brackety_admin/features/locks/state/locks_controller.dart';
import 'package:brackety_admin/features/organizers/data/organizers_api.dart';
import 'package:brackety_admin/features/organizers/state/organizers_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const screenSizes = {
  'phone': Size(360, 800),
  'tablet': Size(800, 1280),
  'desktop': Size(1440, 900),
};

final now = DateTime.utc(2026, 11, 2, 10);

void useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

DioException dioError(
  int status, {
  Map<String, dynamic>? data,
  Map<String, List<String>> headers = const {},
}) {
  final request = RequestOptions(path: '/');
  return DioException(
    requestOptions: request,
    response: Response(
      requestOptions: request,
      statusCode: status,
      data: data,
      headers: Headers.fromMap(headers),
    ),
  );
}

DioException networkError() => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.connectionError,
);

class FakeAdminAuthApi implements AdminAuthApi {
  DioException? error;
  final logins = <(String, String)>[];

  @override
  Future<String> login(String email, String password) async {
    logins.add((email, password));
    if (error case final error?) throw error;
    return 'admin-token';
  }
}

class FakeLocksApi implements LocksApi {
  FakeLocksApi(this.locks);

  List<Lock> locks;
  DioException? listError;
  DioException? revokeError;
  int lists = 0;

  @override
  Future<List<Lock>> list() async {
    lists++;
    if (listError case final error?) throw error;
    return List.of(locks);
  }

  @override
  Future<void> revoke(String lockId) async {
    if (revokeError case final error?) throw error;
    locks = [
      for (final lock in locks)
        if (lock.lockId != lockId) lock,
    ];
  }
}

class FakeOrganizersApi implements OrganizersApi {
  FakeOrganizersApi(this.organizers);

  List<Organizer> organizers;
  final queries = <bool?>[];
  DioException? validateError;

  @override
  Future<List<Organizer>> list({bool? validated}) async {
    queries.add(validated);
    return [
      for (final o in organizers)
        if (validated == null || o.validated == validated) o,
    ];
  }

  @override
  Future<void> validate(String accountId) async {
    if (validateError case final error?) throw error;
    organizers = [
      for (final o in organizers)
        o.accountId == accountId ? o.asValidated() : o,
    ];
  }
}

AdminMetrics metrics({int inReview = 0, int serverErrors = 0}) => AdminMetrics(
  at: now,
  activeAccounts: 12,
  unverified: 2,
  newLast7Days: 5,
  pendingDeletion: 1,
  organizersPending: 3,
  activeSessions: 7,
  activeLocks: 0,
  byProfile: const {
    'CLUB': 1,
    'EXTERNAL_ENTITY': 0,
    'HELPER': 2,
    'STUDENT': 0,
    'EXTERNAL': 0,
  },
  events: 1,
  upcomingEvents: 1,
  entries: 75,
  importsLast7Days: 2,
  importedLast7Days: 40,
  matchesFinished24h: 18,
  scoreboardActions24h: 240,
  groupsCreated24h: 6,
  matchesInProgress: 3,
  matchesInReview: inReview,
  startedAt: now.subtract(const Duration(hours: 5)),
  serverErrors: serverErrors,
);

class FakeMetricsApi implements MetricsApi {
  FakeMetricsApi([AdminMetrics? value]) : value = value ?? metrics();

  AdminMetrics value;
  var reads = 0;

  @override
  Future<AdminMetrics> read() async {
    reads++;
    return value;
  }
}

Lock lock(String id, LockType type, {String? email, String? ip}) => Lock(
  lockId: id,
  type: type,
  lockedUntil: now.add(const Duration(minutes: 12)),
  email: email,
  ip: ip,
);

Organizer organizer(
  String id, {
  String? name,
  String? taxId,
  bool validated = false,
  OrganizerType type = OrganizerType.club,
}) => Organizer(
  accountId: id,
  email: '$id@example.test',
  type: type,
  validated: validated,
  createdAt: DateTime.utc(2026, 10, 30, 12),
  organizationName: name,
  taxId: taxId,
);

class SignedInSession extends AdminSessionController {
  @override
  AdminSession build() => const AdminSession(token: 'admin-token');
}

/// The admin on fakes, opened at [location] ([signedIn] skips the sign-in), with the clock at [now].
/// [realApis] keeps the real API clients, for a test that fakes the server under the Dio.
Future<GoRouter> pumpAdmin(
  WidgetTester tester, {
  bool signedIn = true,
  String? location,
  FakeAdminAuthApi? auth,
  FakeLocksApi? locks,
  FakeOrganizersApi? organizers,
  FakeMetricsApi? metrics,
  bool realApis = false,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        if (!realApis) ...[
          adminAuthApiProvider.overrideWithValue(auth ?? FakeAdminAuthApi()),
          locksApiProvider.overrideWithValue(locks ?? FakeLocksApi([])),
          organizersApiProvider.overrideWithValue(
            organizers ?? FakeOrganizersApi([]),
          ),
          metricsApiProvider.overrideWithValue(metrics ?? FakeMetricsApi()),
        ],
        if (signedIn) adminSessionProvider.overrideWith(SignedInSession.new),
        ...overrides,
      ],
      child: const AdminApp(),
    ),
  );
  await tester.pumpAndSettle();
  final router = ProviderScope.containerOf(
    tester.element(find.byType(AdminApp)),
  ).read(routerProvider);
  if (location != null) {
    router.go(location);
    await tester.pumpAndSettle();
  }
  return router;
}

/// Taps the button with [text] (a title may repeat it), or else the text itself.
Future<void> tapText(WidgetTester tester, String text) async {
  final button = find.ancestor(
    of: find.text(text),
    matching: find.bySubtype<ButtonStyleButton>(),
  );
  await tester.tap(
    button.evaluate().isEmpty ? find.text(text).last : button.last,
  );
  await tester.pumpAndSettle();
}

/// A fake server for the real Dio: answers every request with [handler].
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final (int, Object?) Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio fakeDio(FakeAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
