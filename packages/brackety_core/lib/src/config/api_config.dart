import 'package:flutter/foundation.dart';

/// Backend base URL, injected with `--dart-define-from-file=env/<target>.json`.
/// Debug builds fall back to the local backend; release builds must set it. See docs/08-ejecucion-local.md.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kReleaseMode ? '' : 'http://localhost:8080',
);

/// Call first in `main`: a release build without API_BASE_URL would otherwise talk to nothing silently.
void ensureApiConfigured() {
  if (apiBaseUrl.isEmpty) {
    throw StateError(
      'API_BASE_URL is not set. Build with --dart-define-from-file=env/<target>.json',
    );
  }
}
