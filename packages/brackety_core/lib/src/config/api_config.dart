import 'package:flutter/foundation.dart';

/// Special `API_BASE_URL` for a web build served by the API itself (the sports hall laptop,
/// docs/modulos/servidor-local.md): the API is wherever the page came from.
const sameOriginApiBaseUrl = 'same-origin';

/// Backend base URL as injected with `--dart-define-from-file=env/<target>.json`.
/// Debug builds fall back to the local backend; release builds must set it. See docs/08-ejecucion-local.md.
const _configuredApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kReleaseMode ? '' : 'http://localhost:8080',
);

/// The URL the app talks to, with [sameOriginApiBaseUrl] resolved to the page origin on web.
final String apiBaseUrl = resolveApiBaseUrl(
  _configuredApiBaseUrl,
  isWeb: kIsWeb,
  pageUrl: Uri.base,
);

@visibleForTesting
String resolveApiBaseUrl(
  String configured, {
  required bool isWeb,
  required Uri pageUrl,
}) {
  if (configured != sameOriginApiBaseUrl) return configured;
  // Outside the web there is no page origin: empty, so ensureApiConfigured fails loudly.
  return isWeb ? pageUrl.origin : '';
}

/// Call first in `main`: a release build without API_BASE_URL would otherwise talk to nothing silently.
void ensureApiConfigured() {
  if (apiBaseUrl.isEmpty) {
    throw StateError(
      'API_BASE_URL is not set (same-origin works only on web). '
      'Build with --dart-define-from-file=env/<target>.json',
    );
  }
}

/// Deployment environment, injected like `API_BASE_URL`; `dev` only in the local env files.
/// Unlike kDebugMode, a release build pointed at a local server can still be `dev`.
const appEnv = String.fromEnvironment('APP_ENV');

bool get isDevEnvironment => appEnv == 'dev';
