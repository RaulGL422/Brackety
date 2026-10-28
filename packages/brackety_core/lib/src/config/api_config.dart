/// Backend base URL, injected with `--dart-define-from-file=env/<target>.json`.
/// See docs/08-ejecucion-local.md.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);
