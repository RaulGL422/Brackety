import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/legal_repository.dart';

// No automatic retry: the screens offer a retry button.
final legalTextProvider = FutureProvider.autoDispose
    .family<LegalText, (LegalDocumentType, String)>(
      retry: (_, _) => null,
      (ref, key) => ref.watch(legalRepositoryProvider).text(key.$1, key.$2),
    );

final legalVersionsProvider = FutureProvider.autoDispose<LegalVersions>(
  retry: (_, _) => null,
  (ref) => ref.watch(legalRepositoryProvider).versions(),
);
