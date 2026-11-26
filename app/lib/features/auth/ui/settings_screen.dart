import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/up_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/account.dart';
import '../data/api_error.dart';
import '../state/account_controller.dart';
import 'settings/account_section.dart';
import 'settings/data_sections.dart';
import 'settings/legal_section.dart';
import 'settings/profiles_section.dart';
import 'settings/settings_section.dart';
import 'settings/sign_in_methods_section.dart';
import 'widgets/form_message.dart';

/// «Mi cuenta»: what belongs to the account. It needs the server (Offline rule): without it, an error and a retry.
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
      appBar: AppBar(
        leading: UpButton(label: l10n.eventsTitle, fallback: '/'),
        leadingWidth: UpButton.leadingWidth(context),
        title: Text(l10n.settingsTitle),
      ),
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

/// What belongs to the account wherever it signs in; the device's own choices are in
/// «Ajustes de la app» (Raul, 2026-11-26).
class _Sections extends StatelessWidget {
  const _Sections({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsList(
      children: [
        SettingsGroup(
          title: l10n.accountGroupAccess,
          children: [
            AccountSection(account: account),
            SignInMethodsSection(account: account),
          ],
        ),
        SettingsGroup(
          title: l10n.accountGroupWho,
          children: [ProfilesSection(account: account)],
        ),
        SettingsGroup(
          title: l10n.accountGroupPrivacy,
          children: const [
            ExportSection(),
            LegalSection(),
            DangerZoneSection(),
          ],
        ),
        const LogoutButton(),
      ],
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
              FormMessage.error(
                noServer
                    ? l10n.noServer
                    : CoreLocalizations.of(context).loadError,
              ),
              const SizedBox(height: AppSpacing.l),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(CoreLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
