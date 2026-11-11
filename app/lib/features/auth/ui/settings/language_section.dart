import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/account_controller.dart';
import 'settings_section.dart';

class LanguageSection extends ConsumerWidget {
  const LanguageSection({super.key, required this.locale});

  final String locale;

  Future<void> _select(BuildContext context, WidgetRef ref, String code) async {
    final toasts = Toasts.of(context);
    final error = AppLocalizations.of(context).settingsLanguageError;
    try {
      await ref.read(accountProvider.notifier).setLocale(code);
    } on DioException {
      toasts.show(error, kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsLanguage,
      children: [
        Text(l10n.settingsLanguageHint),
        const SizedBox(height: AppSpacing.m),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'es', label: Text(l10n.languageSpanish)),
            ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
          ],
          selected: {locale},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              _select(context, ref, selection.single),
        ),
      ],
    );
  }
}
