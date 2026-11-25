import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../legal/ui/legal_links.dart';

/// The frame of the screens before signing in (Raul, 2026-11-25): the product's name instead of an
/// app bar, the screen's title as its heading, the form in one centred column, and at the foot the
/// legal texts and the app's version. Labels always show above their field.
class AuthFormPage extends ConsumerWidget {
  const AuthFormPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;

  /// One line under the title saying what this screen asks for.
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            // At least the screen's height: the name at the top, the footer at the bottom and the
            // form centred in between (Raul, 2026-11-25). A taller form just scrolls.
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Header(),
                  _Form(title: title, subtitle: subtitle, children: children),
                  const LegalFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The screen's heading, its line of explanation and its form, in one centred column.
class _Form extends StatelessWidget {
  const _Form({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    // A label that floats into the field hides as soon as there is text: always above it here.
    final fields = theme.copyWith(
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Theme(
            data: fields,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.displaySmall),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.l),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The product's name; back when there is a screen to go back to; Connection only in debug.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s,
        AppSpacing.s,
        AppSpacing.s,
        0,
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            const BackButton()
          else
            // In line with the form on a phone, with the foot's texts on a desktop.
            SizedBox(
              width: MediaQuery.sizeOf(context).width >= LegalFooter.desktop
                  ? AppSpacing.xl
                  : AppSpacing.s,
            ),
          // The name works as a logo: with large text it shrinks to fit instead of pushing out.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'BRACKETY',
                style: theme.textTheme.headlineSmall?.copyWith(
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Connection is for support: before signing in, only against the debug server.
          if (ref.watch(debugStatusProvider).value != null)
            IconButton(
              tooltip: l10n.navConnection,
              icon: const Icon(Icons.dns_outlined),
              onPressed: () => context.push('/connection'),
            ),
        ],
      ),
    );
  }
}
