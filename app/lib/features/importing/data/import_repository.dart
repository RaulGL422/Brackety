import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/upload/file_upload.dart';
import '../../auth/state/session_controller.dart';
import 'import_models.dart';

final importRepositoryProvider = Provider<ImportRepository>(
  (ref) => ImportRepository(ref.watch(apiProvider)),
);

/// Whether this server can read lists (it has an Anthropic key).
final importAvailableProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, eventId) => ref.watch(importRepositoryProvider).isAvailable(eventId),
);

/// The consent text shown in the app; the server only takes this version.
const importConsentVersion = 'v1';

/// All registered ([registered] > 0), or none with the rows that stopped it.
typedef RegisterResult = ({int registered, List<CheckedRow> rows});

class ImportRepository {
  ImportRepository(this._dio);

  final Dio _dio;

  String _path(String eventId) => '/api/v1/events/$eventId/participants/import';

  Future<bool> isAvailable(String eventId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_path(eventId)}/available',
    );
    return response.data!['available'] as bool;
  }

  /// Sends the photos or files (and pasted text) to be read; nothing is kept on the server.
  Future<List<CheckedRow>> read(
    String eventId, {
    required List<PickedFile> files,
    required String text,
  }) async {
    final form = FormData.fromMap({
      'consentVersion': importConsentVersion,
      if (text.trim().isNotEmpty) 'text': text,
      'files': [
        for (final f in files)
          MultipartFile.fromBytes(f.bytes, filename: f.name),
      ],
    });
    final response = await _dio.post<List<dynamic>>(
      '${_path(eventId)}/read',
      data: form,
      // The server may take up to 90 s per try, and tries twice.
      options: Options(receiveTimeout: const Duration(seconds: 200)),
    );
    return _rows(response.data!);
  }

  Future<List<CheckedRow>> check(String eventId, List<ImportRow> rows) async {
    final response = await _dio.post<List<dynamic>>(
      '${_path(eventId)}/check',
      data: _body(rows),
    );
    return _rows(response.data!);
  }

  Future<RegisterResult> register(String eventId, List<ImportRow> rows) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path(eventId),
      data: _body(rows),
      // A 422 is an answer here: the rows that stopped the registration.
      options: Options(validateStatus: (s) => s == 201 || s == 422),
    );
    final data = response.data!;
    return (
      registered: data['registered'] as int,
      rows: _rows(data['rows'] as List),
    );
  }

  static Map<String, dynamic> _body(List<ImportRow> rows) => {
    'rows': [for (final r in rows) r.toJson()],
    'consentVersion': importConsentVersion,
  };

  static List<CheckedRow> _rows(List<dynamic> json) => [
    for (final r in json) CheckedRow.fromJson(r as Map<String, dynamic>),
  ];
}
