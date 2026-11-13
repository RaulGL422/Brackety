import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Android has no downloads folder to drop the file in: the share sheet lets the user save it
/// (Files, Drive) or send it on. share_plus writes it to a temporary file first.
Future<void> saveFile(String name, List<int> bytes, String mimeType) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: mimeType,
          name: name,
        ),
      ],
      fileNameOverrides: [name],
    ),
  );
}

/// No viewer of our own: the share sheet opens it in the phone's PDF app.
Future<void> openPdf(String name, Future<List<int>> bytes) async =>
    saveFile(name, await bytes, 'application/pdf');
