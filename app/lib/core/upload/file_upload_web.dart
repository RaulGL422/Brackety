import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'file_upload.dart';

/// Opens the browser's file picker and reads what the user chose.
///
/// The input lives in the page while the picker is open: a detached one may never report the
/// choice (Safari), and the upload of the rulebook did nothing (Raul, 2026-11-23).
Future<List<PickedFile>> pickFiles({
  required String accept,
  required bool multiple,
}) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept
    ..multiple = multiple;
  input.style.display = 'none';
  web.document.body!.append(input);
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
  final List<web.File> files;
  try {
    files = await chosen.future;
  } finally {
    input.remove();
  }
  return [
    for (final file in files)
      PickedFile(
        name: file.name,
        bytes: (await file.arrayBuffer().toDart).toDart.asUint8List(),
      ),
  ];
}
