import 'package:brackety/features/legal/data/legal_repository.dart';
import 'package:dio/dio.dart';

/// `/api/v1/legal` without a server. Each text is "# `slug` (`lang`)" plus [markdown], unless
/// [textError] makes it fail; [versions] answers the index, unless [versionsError].
class FakeLegalRepository implements LegalRepository {
  FakeLegalRepository({
    this.versionsAnswer = const LegalVersions(
      terms: '2026-11-04',
      privacy: '2026-11-04',
    ),
  });

  LegalVersions versionsAnswer;
  DioException? versionsError;
  DioException? textError;
  String markdown = 'Some text.';

  int versionsCalls = 0;
  final texts = <(LegalDocumentType, String)>[];

  @override
  Future<LegalText> text(LegalDocumentType type, String lang) async {
    texts.add((type, lang));
    if (textError case final error?) throw error;
    return LegalText(
      version: '2026-11-04',
      markdown: '# ${type.slug} ($lang)\n\n$markdown',
    );
  }

  @override
  Future<LegalVersions> versions() async {
    versionsCalls++;
    if (versionsError case final error?) throw error;
    return versionsAnswer;
  }
}
