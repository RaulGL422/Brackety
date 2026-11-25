import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'changelog.dart';

/// The changes of this build: the debug images carry `CHANGELOG.md` as `/changelog.md` next to the
/// app (deploy/web.Dockerfile). Null where it is not (production, local runs, Android).
final changelogProvider = FutureProvider.autoDispose<List<ChangelogEntry>?>((
  ref,
) async {
  if (!Uri.base.scheme.startsWith('http')) return null;
  try {
    final response = await Dio().getUri<String>(
      Uri.base.resolve('/changelog.md'),
      options: Options(responseType: ResponseType.plain),
    );
    final entries = parseChangelog(response.data ?? '');
    return entries.isEmpty ? null : entries;
  } on DioException {
    return null;
  }
});
