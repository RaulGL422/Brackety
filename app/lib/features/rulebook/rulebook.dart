import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/data/api_error.dart';
import '../auth/state/session_controller.dart';

/// The phase's full rulebook (a PDF the club uploads; docs/modulos/prototipo-f1.md).
class RulebookRepository {
  RulebookRepository(this._dio);

  final Dio _dio;

  static String path(String eventId) => '/api/v1/events/$eventId/rulebook';

  /// Its file name, or null when the phase has none.
  Future<String?> fileName(String eventId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${path(eventId)}/info',
    );
    return response.data!['fileName'] as String?;
  }

  /// Null when the phase has none.
  Future<List<int>?> pdf(String eventId) async {
    try {
      final response = await _dio.get<List<int>>(
        path(eventId),
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (e) {
      if (ApiError.from(e).status == 404) return null;
      rethrow;
    }
  }

  Future<void> upload(String eventId, String name, List<int> bytes) =>
      _dio.put<void>(
        path(eventId),
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: name),
        }),
      );

  Future<void> delete(String eventId) => _dio.delete<void>(path(eventId));
}

final rulebookRepositoryProvider = Provider<RulebookRepository>(
  (ref) => RulebookRepository(ref.watch(apiProvider)),
);

final rulebookNameProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, eventId) => ref.watch(rulebookRepositoryProvider).fileName(eventId),
);

/// Loaded when the mat screen opens and kept: if the network drops later, the referee still
/// has it.
final rulebookPdfProvider = FutureProvider.family<List<int>?, String>(
  (ref, eventId) => ref.watch(rulebookRepositoryProvider).pdf(eventId),
);
