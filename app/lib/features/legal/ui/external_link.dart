import 'package:url_launcher/url_launcher.dart';

const _externalSchemes = {'http', 'https', 'mailto'};

/// The link to open outside the app, or null for any other scheme (javascript:, file:, intents…).
Uri? externalLink(String? href) {
  final uri = href == null ? null : Uri.tryParse(href);
  return uri != null && _externalSchemes.contains(uri.scheme) ? uri : null;
}

Future<void> openExternalLink(String? href) async {
  final uri = externalLink(href);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}
