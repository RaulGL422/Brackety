import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_upload_stub.dart'
    if (dart.library.js_interop) 'file_upload_web.dart'
    as platform;

/// A file the user picked, read into memory.
class PickedFile {
  const PickedFile({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

/// Lets the user pick files; [accept] as in an HTML input ("image/*,.csv"). Empty if cancelled.
typedef PickFiles = Future<List<PickedFile>> Function({
  required String accept,
  required bool multiple,
});

/// The platform's file picker, as a provider so tests can replace it.
final pickFilesProvider = Provider<PickFiles>((ref) => platform.pickFiles);
