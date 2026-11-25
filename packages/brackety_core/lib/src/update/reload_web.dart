import 'package:web/web.dart' as web;

/// Loads the page again: the browser asks for the new build (deploy/nginx/web.conf revalidates it).
void reloadPage() => web.window.location.reload();
