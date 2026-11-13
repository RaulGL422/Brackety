import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/api_error.dart';
import '../state/offline_sync.dart';
import 'offline_store.dart';

/// The lists helpers and the club read (events, categories, participants, teams, mats, settings,
/// standings) are kept on the device: without network they come from there at once, and the
/// screens keep working (Raul, 2026-11-13). The referee's board and matches have their own cache.
final _cached = RegExp(
  r'^/api/v1/(me/events|events/[^/]+/(categories(/[^/]+/(participants|teams))?|mats|settings|standings|participants))$',
);

bool isOfflineCached(RequestOptions options) =>
    options.method == 'GET' && _cached.hasMatch(options.path);

String _key(String path) =>
    'get${path.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}';

/// Known to be offline: the saved answer at once (the background check finds the server again).
/// Online: every answer is saved; a request without answer gets the saved one if there is.
class OfflineGetCache extends Interceptor {
  OfflineGetCache(this._ref);

  final Ref _ref;

  OfflineStore get _store => _ref.read(offlineStoreProvider);
  OfflineSync get _sync => _ref.read(offlineSyncProvider.notifier);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (isOfflineCached(options) && !_ref.read(offlineSyncProvider).connected) {
      final saved = await _read(options);
      if (saved != null) return handler.resolve(saved);
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (isOfflineCached(response.requestOptions)) {
      _sync.reportResponse();
      unawaited(_write(response.requestOptions.path, response.data));
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (isOfflineCached(err.requestOptions) && ApiError.from(err).noResponse) {
      _sync.reportNoResponse();
      final saved = await _read(err.requestOptions);
      if (saved != null) return handler.resolve(saved);
    }
    handler.next(err);
  }

  Future<Response<dynamic>?> _read(RequestOptions options) async {
    final data = await _store.read(_key(options.path));
    if (data == null) return null;
    return Response<dynamic>(
      requestOptions: options,
      data: data,
      statusCode: 200,
      extra: {'offline': true},
    );
  }

  Future<void> _write(String path, Object? data) async {
    try {
      await _store.write(_key(path), data);
    } on OfflineStoreException {
      // Full or blocked storage: the screen still has the answer, only the copy is missing.
    }
  }
}
