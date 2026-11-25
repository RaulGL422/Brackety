import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../legal/data/legal_repository.dart';
import '../../legal/ui/legal_links.dart';
import '../data/account.dart';
import '../state/account_controller.dart';
import '../state/session_controller.dart';
import 'widgets/acceptance_checkbox.dart';
import 'widgets/auth_alternative.dart';
import 'widgets/auth_form_page.dart';
import 'widgets/form_message.dart';

/// The terms or the privacy policy changed since this account accepted them: read and accept the
/// new ones, or sign out (docs/modulos/legal-paginas.md). The router keeps the account here.
/// Each text says «Leído» once opened, as a help: accepting does not wait for it (Raul, 2026-11-25).
class LegalUpdateScreen extends ConsumerStatefulWidget {
  const LegalUpdateScreen({super.key});

  @override
  ConsumerState<LegalUpdateScreen> createState() => _LegalUpdateScreenState();
}

class _LegalUpdateScreenState extends ConsumerState<LegalUpdateScreen> {
  final _form = GlobalKey<FormState>();
  final _read = <LegalDocumentType>{};
  bool _busy = false;
  String? _error;

  Future<void> _accept(List<PendingConsent> pending) async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountProvider.notifier).acceptConsents(pending);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.response?.statusCode == 409
            ? l10n.legalUpdateChangedAgain
            : l10n.saveError;
      });
    }
  }

  Future<void> _open(LegalDocumentType type) async {
    await openLegalPage(context, type);
    if (mounted) setState(() => _read.add(type));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending =
        ref.watch(accountProvider.select((a) => a.value?.pendingConsents)) ??
        const <PendingConsent>[];
    final documents = [
      for (final p in pending)
        if (LegalDocumentType.fromSlug(p.document) case final type?)
          (type: type, version: p.version),
    ];
    final error = _error;
    return AuthFormPage(
      title: l10n.legalUpdateTitle(documents.length),
      subtitle: l10n.legalUpdateBody(documents.length),
      children: [
        if (error != null) ...[
          FormMessage.error(error),
          const SizedBox(height: AppSpacing.l),
        ],
        _Documents(documents: documents, read: _read, onOpen: _open),
        const SizedBox(height: AppSpacing.m),
        Form(
          key: _form,
          child: AcceptanceCheckbox(
            title: Text(
              l10n.legalUpdateAcceptDocuments(
                _names(l10n, [for (final d in documents) d.type]),
              ),
            ),
            requiredText: l10n.registerAcceptRequired,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        FilledButton(
          onPressed: _busy || pending.isEmpty ? null : () => _accept(pending),
          child: Text(l10n.legalUpdateSubmit),
        ),
        AuthAlternative(
          question: l10n.legalUpdateDisagree,
          action: l10n.legalUpdateSignOut,
          onPressed: _busy
              ? null
              : () => ref.read(sessionProvider.notifier).logout(),
        ),
      ],
    );
  }

  /// «la política de privacidad y los términos de uso»: the texts named, not «the texts above».
  static String _names(AppLocalizations l10n, List<LegalDocumentType> types) {
    final names = [
      for (final type in types)
        switch (type) {
          LegalDocumentType.privacy => l10n.legalAcceptPrivacy,
          LegalDocumentType.terms => l10n.legalAcceptTerms,
          LegalDocumentType.cookies => l10n.legalAcceptCookies,
          LegalDocumentType.legalNotice => l10n.legalAcceptNotice,
        },
    ];
    if (names.length < 2) return names.join();
    return l10n.legalListAnd(
      names.sublist(0, names.length - 1).join(', '),
      names.last,
    );
  }
}

/// The changed texts in one box, each row opening its text.
class _Documents extends StatelessWidget {
  const _Documents({
    required this.documents,
    required this.read,
    required this.onOpen,
  });

  final List<({LegalDocumentType type, String version})> documents;
  final Set<LegalDocumentType> read;
  final ValueChanged<LegalDocumentType> onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          for (var i = 0; i < documents.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _DocumentRow(
              type: documents[i].type,
              version: documents[i].version,
              read: read.contains(documents[i].type),
              onPressed: () => onOpen(documents[i].type),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.type,
    required this.version,
    required this.read,
    required this.onPressed,
  });

  final LegalDocumentType type;
  final String version;
  final bool read;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final quiet = Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      legalTitle(l10n, type),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      legalVersionText(context, version),
                      style: text.bodyMedium?.copyWith(color: quiet),
                    ),
                    if (read) const _Read(),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                l10n.legalUpdateRead,
                style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Read extends StatelessWidget {
  const _Read();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontWeight: FontWeight.w700);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        const Icon(Icons.check, size: 16),
        Text(AppLocalizations.of(context).legalUpdateWasRead, style: style),
      ],
    );
  }
}
