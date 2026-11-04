import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Public endpoints: the plain client, no session needed.
final legalRepositoryProvider = Provider<LegalRepository>(
  (ref) => LegalRepository(ref.watch(dioProvider)),
);

enum LegalDocumentType {
  privacy('privacy'),
  terms('terms'),
  cookies('cookies'),
  legalNotice('legal-notice');

  const LegalDocumentType(this.slug);

  /// The name in the API and in the `/legal/<slug>` route.
  final String slug;

  /// Null for a slug this version of the app does not know.
  static LegalDocumentType? fromSlug(String slug) {
    for (final type in values) {
      if (type.slug == slug) return type;
    }
    return null;
  }
}

class LegalText {
  const LegalText({required this.version, required this.markdown});

  factory LegalText.fromJson(Map<String, dynamic> json) => LegalText(
    version: json['version'] as String,
    markdown: json['markdown'] as String,
  );

  final String version;
  final String markdown;
}

/// The versions a sign-up has to accept, as the server has them now.
class LegalVersions {
  const LegalVersions({required this.terms, required this.privacy});

  factory LegalVersions.fromJson(Map<String, dynamic> json) {
    final versions = {
      for (final document in json['documents'] as List<dynamic>)
        document['type'] as String: document['version'] as String,
    };
    return LegalVersions(
      terms: versions[LegalDocumentType.terms.slug]!,
      privacy: versions[LegalDocumentType.privacy.slug]!,
    );
  }

  final String terms;
  final String privacy;
}

class LegalRepository {
  LegalRepository(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/legal';

  Future<LegalText> text(LegalDocumentType type, String lang) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/${type.slug}',
      queryParameters: {'lang': lang},
    );
    return LegalText.fromJson(response.data!);
  }

  Future<LegalVersions> versions() async {
    // The server lets browsers cache it for 5 min; a sign-up needs the versions of right now.
    final response = await _dio.get<Map<String, dynamic>>(
      _base,
      options: Options(headers: const {'Cache-Control': 'no-cache'}),
    );
    return LegalVersions.fromJson(response.data!);
  }
}
