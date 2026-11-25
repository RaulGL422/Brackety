import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_controller.dart';
import 'export_models.dart';

final exportRepositoryProvider = Provider<ExportRepository>(
  (ref) => ExportRepository(ref.watch(apiProvider)),
);

/// Custom exports (docs/producto/exportaciones.md): the sheets, a preview, the file and, for the club,
/// who downloaded personal data.
class ExportRepository {
  ExportRepository(this._dio);

  final Dio _dio;

  String _path(String eventId) => '/api/v1/events/$eventId/exports';

  /// [language]: the app's, for the titles ("es" or "en").
  Future<List<ExportSheet>> sheets(String eventId, String language) async {
    final response = await _dio.get<List<dynamic>>(
      '${_path(eventId)}/sheets',
      queryParameters: {'locale': language},
    );
    return [
      for (final s in response.data!)
        ExportSheet.fromJson(s as Map<String, dynamic>),
    ];
  }

  Future<List<ExportAuditEntry>> audit(String eventId) async {
    final response = await _dio.get<List<dynamic>>('${_path(eventId)}/audit');
    return [
      for (final a in response.data!)
        ExportAuditEntry.fromJson(a as Map<String, dynamic>),
    ];
  }

  Future<ExportPreview> preview(String eventId, ExportDraft draft) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${_path(eventId)}/preview',
      data: draft.toJson(),
    );
    return ExportPreview.fromJson(response.data!);
  }

  /// The file with the name the server gives (event and sheet), and its type.
  Future<({String name, List<int> bytes, String mimeType})> download(
    String eventId,
    ExportDraft draft,
  ) async {
    final response = await _dio.post<List<int>>(
      _path(eventId),
      data: draft.toJson(),
      options: Options(responseType: ResponseType.bytes),
    );
    final disposition = response.headers.value('content-disposition') ?? '';
    final name = RegExp(r'filename="([^"]+)"')
        .firstMatch(disposition)
        ?.group(1);
    final type =
        response.headers.value('content-type') ?? draft.format.mimeType;
    return (
      name: name ?? '${draft.sheet}.${draft.format.name}',
      bytes: response.data!,
      mimeType: type,
    );
  }
}
