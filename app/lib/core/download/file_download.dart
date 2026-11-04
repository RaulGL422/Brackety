import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart'
    if (dart.library.io) 'file_download_io.dart'
    as platform;

export 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart'
    if (dart.library.io) 'file_download_io.dart';

typedef SaveFile = Future<void> Function(
  String name,
  List<int> bytes,
  String mimeType,
);

/// The platform's way to hand a file to the user, as a provider so tests can catch it.
final saveFileProvider = Provider<SaveFile>((ref) => platform.saveFile);
