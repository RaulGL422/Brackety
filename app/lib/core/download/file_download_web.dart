import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Hands [bytes] to the browser as a download called [name].
Future<void> saveFile(String name, List<int> bytes, String mimeType) async {
  final url = _blobUrl(bytes, mimeType);
  web.HTMLAnchorElement()
    ..href = url
    ..download = name
    ..click();
  web.URL.revokeObjectURL(url);
}

/// Shows a PDF with the browser's own viewer in a new tab. The tab opens before [bytes] arrive,
/// while the tap still counts as the user's (pop-up blockers). Phone browsers without a viewer
/// get it as a download, which their notification opens in the phone's PDF app.
Future<void> openPdf(String name, Future<List<int>> bytes) async {
  if (!web.window.navigator.pdfViewerEnabled) {
    await saveFile(name, await bytes, 'application/pdf');
    return;
  }
  final tab = web.window.open('', '_blank');
  try {
    final url = _blobUrl(await bytes, 'application/pdf');
    if (tab == null) {
      web.window.open(url, '_blank');
    } else {
      tab.location.href = url;
    }
  } catch (_) {
    tab?.close();
    rethrow;
  }
}

String _blobUrl(List<int> bytes, String mimeType) => web.URL.createObjectURL(
  web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  ),
);
