import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';

/// The URL the app talks to: the build's [apiBaseUrl], unless the app lets the user pick another
/// (the Android app, docs/modulos/servidor-local.md) and overrides this.
final apiBaseUrlProvider = Provider<String>((ref) => apiBaseUrl);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(apiBaseUrlProvider),
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});
