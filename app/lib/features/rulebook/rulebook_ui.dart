import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/download/file_download.dart';
import '../../core/upload/file_upload.dart';
import '../../l10n/gen/app_localizations.dart';
import 'rulebook.dart';

const _fileName = 'reglamento.pdf';

/// On the referee's mat: opens the phase's rulebook. Hidden when the phase has none.
class RulebookButton extends ConsumerWidget {
  const RulebookButton({super.key, required this.eventId, this.color});

  final String eventId;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdf = ref.watch(rulebookPdfProvider(eventId));
    if (pdf case AsyncData(value: null)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.menu_book_outlined),
      color: color,
      tooltip: l10n.rulebookOpen,
      onPressed: () => openRulebook(context, ref, eventId),
    );
  }
}

Future<void> openRulebook(
  BuildContext context,
  WidgetRef ref,
  String eventId,
) async {
  final l10n = AppLocalizations.of(context);
  final toasts = Toasts.of(context);
  final provider = rulebookPdfProvider(eventId);
  // A failed load (no network when the screen opened) is tried again.
  if (ref.read(provider).hasError) ref.invalidate(provider);
  try {
    await ref.read(openPdfProvider)(
      _fileName,
      ref
          .read(provider.future)
          .then((pdf) => pdf ?? (throw StateError('none'))),
    );
  } catch (_) {
    toasts.show(l10n.rulebookOpenError, kind: ToastKind.error);
  }
}

/// In the club's settings: upload, see, replace or remove the phase's rulebook.
class RulebookSection extends ConsumerStatefulWidget {
  const RulebookSection({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<RulebookSection> createState() => _RulebookSectionState();
}

class _RulebookSectionState extends ConsumerState<RulebookSection> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final name = ref.watch(rulebookNameProvider(widget.eventId));
    final current = name.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rulebookTitle, style: text.titleMedium),
        Text(l10n.rulebookHint, style: text.bodySmall),
        const SizedBox(height: AppSpacing.s),
        Text(
          name.isLoading ? '…' : (current ?? l10n.rulebookNone),
          style: text.bodyLarge,
        ),
        Wrap(
          spacing: AppSpacing.s,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                current == null ? l10n.rulebookUpload : l10n.rulebookReplace,
              ),
              onPressed: _busy ? null : _upload,
            ),
            if (current != null) ...[
              TextButton.icon(
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(l10n.rulebookOpen),
                onPressed: () => openRulebook(context, ref, widget.eventId),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.rulebookRemove),
                onPressed: _busy ? null : _remove,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final picked = await ref.read(pickFilesProvider)(
      accept: 'application/pdf,.pdf',
      multiple: false,
    );
    if (picked.isEmpty) return;
    await _run(
      () => ref
          .read(rulebookRepositoryProvider)
          .upload(widget.eventId, picked.single.name, picked.single.bytes),
      done: () => toasts.show(l10n.rulebookUploaded, kind: ToastKind.success),
      failed: () =>
          toasts.show(l10n.rulebookUploadError, kind: ToastKind.error),
    );
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    await _run(
      () => ref.read(rulebookRepositoryProvider).delete(widget.eventId),
      done: () {},
      failed: () =>
          toasts.show(l10n.rulebookRemoveError, kind: ToastKind.error),
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required VoidCallback done,
    required VoidCallback failed,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      done();
    } on DioException {
      failed();
    } finally {
      ref.invalidate(rulebookNameProvider(widget.eventId));
      ref.invalidate(rulebookPdfProvider(widget.eventId));
      if (mounted) setState(() => _busy = false);
    }
  }
}
