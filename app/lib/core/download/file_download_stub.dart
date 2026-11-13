/// Neither web nor Android: nothing to save to.
Future<void> saveFile(String name, List<int> bytes, String mimeType) =>
    throw UnsupportedError('Saving files is not available here.');

Future<void> openPdf(String name, Future<List<int>> bytes) =>
    throw UnsupportedError('Opening files is not available here.');
