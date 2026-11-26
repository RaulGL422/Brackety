import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/up_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../state/account_controller.dart';
import 'settings/appearance_section.dart';
import 'settings/connection_tile.dart';
import 'settings/device_sections.dart';
import 'settings/language_section.dart';
import 'settings/settings_section.dart';

/// «Ajustes de la app» (Raul, 2026-11-26): how Brackety looks, speaks and rings on this device,
/// and what version it runs. The account's own matters are in «Mi cuenta».
class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // The language travels with the account (its emails use it too): shown once it is loaded.
    final locale = ref.watch(accountProvider.select((a) => a.value?.locale));
    return Scaffold(
      appBar: AppBar(
        leading: UpButton(label: l10n.eventsTitle, fallback: '/'),
        leadingWidth: UpButton.leadingWidth(context),
        title: Text(l10n.appSettingsTitle),
      ),
      body: SettingsList(
        children: [
          if (locale != null) LanguageSection(locale: locale),
          const SizedBox(height: AppSpacing.m),
          const AppearanceSection(),
          const SizedBox(height: AppSpacing.m),
          const TextContrastSection(),
          const SizedBox(height: AppSpacing.m),
          const MyEventsPrefsSection(),
          const SizedBox(height: AppSpacing.m),
          const ScoreboardPrefsSection(),
          const SizedBox(height: AppSpacing.xl),
          SettingsGroup(title: l10n.appGroupAbout, children: const [_About()]),
        ],
      ),
    );
  }
}

/// What this build is: its changes (only against the debug server), licenses and version.
class _About extends ConsumerWidget {
  const _About();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debug = ref.watch(debugStatusProvider).value != null;
    final core = CoreLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.s,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (debug)
              _Link(
                icon: Icons.history,
                title: core.changelogMenu,
                onTap: () => context.push('/changelog'),
              ),
            _Link(
              icon: Icons.description_outlined,
              title: core.licenses,
              onTap: () => showLicensePage(context: context),
            ),
            const ConnectionTile(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: AppVersionText(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
