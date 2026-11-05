/// The sports hall laptop: Windows' mobile hotspot always takes this IP (docs/modulos/servidor-local.md).
const hallServerHost = '192.168.137.1';
const hallServerUrl = 'http://$hallServerHost:8080';
const internetServerUrl = 'https://brackety-api.rgal.dev';

enum ServerOption { hall, internet, other }

ServerOption optionOf(String url) => switch (url) {
  hallServerUrl => ServerOption.hall,
  internetServerUrl => ServerOption.internet,
  _ => ServerOption.other,
};

/// The typed URL as the app stores it: trimmed and without a trailing slash; null if it is not
/// an http(s) URL with a host.
String? parseServerUrl(String input) {
  final text = input.trim().replaceFirst(RegExp(r'/+$'), '');
  final uri = text.contains(RegExp(r'\s')) ? null : Uri.tryParse(text);
  if (uri == null || !const {'http', 'https'}.contains(uri.scheme)) {
    return null;
  }
  if (uri.host.isEmpty || uri.hasQuery || uri.hasFragment) return null;
  return text;
}

/// Android release builds only allow plain http to the hall laptop (network_security_config.xml).
bool isBlockedCleartext(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null && uri.scheme == 'http' && uri.host != hallServerHost;
}
