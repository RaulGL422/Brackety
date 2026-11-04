import 'file_upload.dart';

/// Only the web build picks files for now (the prototype runs in the browser).
Future<List<PickedFile>> pickFiles({
  required String accept,
  required bool multiple,
}) => throw UnsupportedError('Picking files is not available here.');
