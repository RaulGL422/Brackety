import 'dart:math';

import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// A titled card of the settings. The [danger] one is outlined in the error colour.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.danger = false,
  });

  final String title;
  final List<Widget> children;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return Card(
      shape: danger
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.l),
              side: BorderSide(color: error),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: danger ? error : null,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// The settings pages' column: as wide as a form, centred on large windows.
class SettingsList extends StatelessWidget {
  const SettingsList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = max(
          AppSpacing.l,
          (constraints.maxWidth - AppSizes.formMaxWidth) / 2,
        );
        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: side,
            vertical: AppSpacing.l,
          ),
          children: children,
        );
      },
    );
  }
}

/// A group's title over its cards: «Acceso», «Privacidad y datos».
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.s),
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.m),
            child,
          ],
        ],
      ),
    );
  }
}
