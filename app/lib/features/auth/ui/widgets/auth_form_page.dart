import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../legal/ui/legal_links.dart';

/// One centred column for the auth screens: full width on phones, a narrow card-free form on wide windows.
/// The legal links and the app's version close it.
class AuthFormPage extends StatelessWidget {
  const AuthFormPage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: l10n.navConnection,
            icon: const Icon(Icons.dns_outlined),
            onPressed: () => context.push('/connection'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.formMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...children,
                  const SizedBox(height: AppSpacing.xl),
                  const LegalFooter(),
                  const SizedBox(height: AppSpacing.s),
                  const AppVersionText(textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
