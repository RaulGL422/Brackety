import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../data/registration.dart';
import '../auth_texts.dart';

/// The first profile of the account, each with a one-line description.
class ProfileSelector extends FormField<ProfileType> {
  ProfileSelector({super.key, super.validator, super.onSaved})
    : super(builder: (field) => _ProfileOptions(field: field));
}

class _ProfileOptions extends StatelessWidget {
  const _ProfileOptions({required this.field});

  final FormFieldState<ProfileType> field;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final error = field.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.registerProfile, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        RadioGroup<ProfileType>(
          groupValue: field.value,
          onChanged: field.didChange,
          child: Column(
            children: [
              for (final profile in ProfileType.values)
                RadioListTile<ProfileType>(
                  value: profile,
                  contentPadding: EdgeInsets.zero,
                  title: Text(profileName(l10n, profile)),
                  subtitle: Text(profileHint(l10n, profile)),
                ),
            ],
          ),
        ),
        if (error != null)
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}
