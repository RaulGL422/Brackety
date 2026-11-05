import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'offline_store.dart';

/// In the app's private support folder, which survives closing the app.
OfflineStore deviceOfflineStore() => FileOfflineStore(
  () async => Directory(
    '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}offline',
  ),
);

/// One `<name>.json` file per document in [folder].
class FileOfflineStore implements OfflineStore {
  FileOfflineStore(this.folder);

  final Future<Directory> Function() folder;

  // One write at a time, so two never share the temporary file.
  Future<void> _last = Future.value();

  Future<File> _file(String name) async =>
      File('${(await folder()).path}${Platform.pathSeparator}$name.json');

  @override
  Future<Object?> read(String name) async {
    await _last;
    try {
      final file = await _file(name);
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString());
    } on Exception {
      // A missing plugin or a broken file: start empty rather than not at all.
      return null;
    }
  }

  @override
  Future<void> write(String name, Object? json) => _serial(() async {
    final file = await _file(name);
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(json), flush: true);
    await temporary.rename(file.path);
  });

  @override
  Future<void> clear() => _serial(() async {
    final dir = await folder();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<void> _serial(Future<void> Function() job) {
    final next = _last.then((_) => job());
    // A failed write must not block the next ones.
    _last = next.catchError((_) {});
    return next;
  }
}
