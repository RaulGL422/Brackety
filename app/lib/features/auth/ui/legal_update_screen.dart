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
import 'widgets/auth_form_page.dart';
import 'widgets/form_message.dart';

/// The terms or the privacy policy changed since this account accepted them: read and accept the
/// new ones, or sign out (docs/modulos/legal-paginas.md). The router keeps the account here.
class LegalUpdateScreen extends ConsumerStatefulWidget {
  const LegalUpdateScreen({super.key});

  @override
  ConsumerState<LegalUpdateScreen> createState() => _LegalUpdateScreenState();
}

class _LegalUpdateScreenState extends ConsumerState<LegalUpdateScreen> {
  final _form = GlobalKey<FormState>();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending =
        ref.watch(accountProvider.select((a) => a.value?.pendingConsents)) ??
        const <PendingConsent>[];
    final error = _error;
    return AuthFormPage(
      title: l10n.legalUpdateTitle,
      children: [
        Text(l10n.legalUpdateBody),
        const SizedBox(height: AppSpacing.m),
        for (final p in pending)
          if (LegalDocumentType.fromSlug(p.document) case final type?)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(legalTitle(l10n, type)),
              subtitle: Text(l10n.legalUpdateVersion(p.version)),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => openLegalPage(context, type),
            ),
        const SizedBox(height: AppSpacing.s),
        Form(
          key: _form,
          child: AcceptanceCheckbox(
            title: Text(l10n.legalUpdateAccept),
            requiredText: l10n.registerAcceptRequired,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.m),
          FormMessage.error(error),
        ],
        const SizedBox(height: AppSpacing.l),
        FilledButton(
          onPressed: _busy || pending.isEmpty ? null : () => _accept(pending),
          child: Text(l10n.legalUpdateSubmit),
        ),
        const SizedBox(height: AppSpacing.s),
        TextButton(
          onPressed: _busy
              ? null
              : () => ref.read(sessionProvider.notifier).logout(),
          child: Text(l10n.legalUpdateSignOut),
        ),
      ],
    );
  }
}
