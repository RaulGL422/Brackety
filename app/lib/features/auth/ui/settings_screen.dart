import 'dart:math';

import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/account.dart';
import '../data/api_error.dart';
import '../state/account_controller.dart';
import 'settings/account_section.dart';
import 'settings/data_sections.dart';
import 'settings/language_section.dart';
import 'settings/legal_section.dart';
import 'settings/profiles_section.dart';
import 'settings/sign_in_methods_section.dart';
import 'widgets/form_message.dart';

/// Account settings. They need the server (Offline rule): without it, an error and a retry.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // The account loaded at sign-in may be old (a validation, a verification elsewhere).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(accountProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(accountProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: switch (account) {
        AsyncValue(isLoading: true, hasValue: false) ||
        AsyncValue(
          isLoading: true,
          hasError: true,
        ) => const Center(child: CircularProgressIndicator()),
        AsyncValue(:final error?) => _LoadError(
          noServer: error is DioException && ApiError.from(error).noResponse,
          onRetry: () => ref.invalidate(accountProvider),
        ),
        AsyncValue(:final value?) => _Sections(account: value),
        // Signed out: the router is already leaving.
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.l);
    return LayoutBuilder(
      builder: (context, constraints) {
        // One column, as wide as a form, centred on large windows.
        final side = max(
          AppSpacing.l,
          (constraints.maxWidth - AppSizes.formMaxWidth) / 2,
        );
        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: side,
            vertical: AppSpacing.l,
          ),
          children: [
            AccountSection(account: account),
            gap,
            LanguageSection(locale: account.locale),
            gap,
            ProfilesSection(account: account),
            gap,
            SignInMethodsSection(account: account),
            gap,
            const ExportSection(),
            gap,
            const LegalSection(),
            gap,
            const DangerZoneSection(),
            gap,
            const LogoutButton(),
          ],
        );
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.noServer, required this.onRetry});

  final bool noServer;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormMessage.error(noServer ? l10n.noServer : l10n.loadError),
              const SizedBox(height: AppSpacing.l),
              OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
      ),
    );
  }
}
