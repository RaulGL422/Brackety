import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'file_upload.dart';

/// Opens the browser's file picker and reads what the user chose.
Future<List<PickedFile>> pickFiles({
  required String accept,
  required bool multiple,
}) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept
    ..multiple = multiple;
  final chosen = Completer<List<web.File>>();
  input.onchange = (web.Event _) {
    final files = input.files;
    chosen.complete([
      for (var i = 0; i < (files?.length ?? 0); i++) files!.item(i)!,
    ]);
  }.toJS;
  // Closing the picker without choosing fires "cancel" in current browsers.
  input.oncancel = (web.Event _) {
    if (!chosen.isCompleted) chosen.complete([]);
  }.toJS;
  input.click();
  final files = await chosen.future;
  return [
    for (final file in files)
      PickedFile(
        name: file.name,
        bytes: (await file.arrayBuffer().toDart).toDart.asUint8List(),
      ),
  ];
}
