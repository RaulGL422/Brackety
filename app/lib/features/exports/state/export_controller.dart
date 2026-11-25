import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/export_models.dart';
import '../data/export_repository.dart';

/// The sheets the club can export, titled in the app's [language].
final exportSheetsProvider = FutureProvider.autoDispose
    .family<List<ExportSheet>, ({String eventId, String language})>(
      (ref, key) =>
          ref.watch(exportRepositoryProvider).sheets(key.eventId, key.language),
    );

/// The export being put together for an event; null until a sheet is chosen.
final exportDraftProvider = NotifierProvider.autoDispose
    .family<ExportDraftController, ExportDraft?, String>(
      ExportDraftController.new,
    );

/// How long the preview waits after a change, so typing a filter asks once.
const previewDelay = Duration(milliseconds: 400);

/// The first rows of the draft as the file will have them; asked again a moment after each change.
final exportPreviewProvider = FutureProvider.autoDispose
    .family<ExportPreview?, String>((ref, eventId) async {
      final draft = ref.watch(exportDraftProvider(eventId));
      if (draft == null || draft.columns.isEmpty) return null;
      var replaced = false;
      ref.onDispose(() => replaced = true);
      await Future<void>.delayed(previewDelay);
      if (replaced) return null;
      return ref.read(exportRepositoryProvider).preview(eventId, draft);
    });

class ExportDraftController extends Notifier<ExportDraft?> {
  ExportDraftController(this.eventId);

  final String eventId;

  @override
  ExportDraft? build() => null;

  ExportDraft get _draft => state!;

  /// Another sheet starts over: its columns and filters are its own.
  void pickSheet(ExportSheet sheet) {
    final keep = state;
    state = ExportDraft(
      sheet: sheet.key,
      columns: sheet.startingColumns,
      format: keep?.format ?? ExportFormat.csv,
      english: keep?.english ?? false,
    );
  }

  void addColumn(String key) =>
      state = _draft.copyWith(columns: [..._draft.columns, key]);

  /// Also out of the sort, the filters, the split and the titles that used it.
  void removeColumn(String key) {
    final titles = {..._draft.titles}..remove(key);
    state = _draft.copyWith(
      columns: [..._draft.columns]..remove(key),
      titles: titles,
      sort: [
        for (final s in _draft.sort)
          if (s.column != key) s,
      ],
      filters: [
        for (final f in _draft.filters)
          if (f.column != key) f,
      ],
      splitBy: () => _draft.splitBy == key ? null : _draft.splitBy,
    );
  }

  /// [to] counts as if [from] were already out of the list, as a drag reports it after Flutter's fix-up.
  void moveColumn(int from, int to) {
    final columns = [..._draft.columns];
    final key = columns.removeAt(from);
    columns.insert(to.clamp(0, columns.length), key);
    state = _draft.copyWith(columns: columns);
  }

  /// An empty title brings back the sheet's.
  void rename(String key, String title) {
    final titles = {..._draft.titles};
    if (title.trim().isEmpty) {
      titles.remove(key);
    } else {
      titles[key] = title.trim();
    }
    state = _draft.copyWith(titles: titles);
  }

  void addFilter(String column) => state = _draft.copyWith(
    filters: [
      ..._draft.filters,
      ExportFilter(column: column),
    ],
  );

  void setFilter(int index, ExportFilter filter) =>
      state = _draft.copyWith(filters: [..._draft.filters]..[index] = filter);

  void removeFilter(int index) =>
      state = _draft.copyWith(filters: [..._draft.filters]..removeAt(index));

  void addSort(String column) => state = _draft.copyWith(
    sort: [
      ..._draft.sort,
      ExportSort(column: column),
    ],
  );

  void flipSort(int index) {
    final sort = [..._draft.sort];
    sort[index] = ExportSort(
      column: sort[index].column,
      descending: !sort[index].descending,
    );
    state = _draft.copyWith(sort: sort);
  }

  /// One step up in priority.
  void raiseSort(int index) {
    if (index == 0) return;
    final sort = [..._draft.sort];
    sort.insert(index - 1, sort.removeAt(index));
    state = _draft.copyWith(sort: sort);
  }

  void removeSort(int index) =>
      state = _draft.copyWith(sort: [..._draft.sort]..removeAt(index));

  void splitBy(String? column) =>
      state = _draft.copyWith(splitBy: () => column);

  void format(ExportFormat format) => state = _draft.copyWith(format: format);

  void english(bool english) => state = _draft.copyWith(english: english);

  void pdfTitle(String title) => state = _draft.copyWith(pdfTitle: title);

  void landscape(bool? landscape) =>
      state = _draft.copyWith(landscape: () => landscape);
}
