import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../data/registration.dart';
import '../auth_texts.dart';

/// The first profile of the account, each with a one-line description.
class ProfileSelector extends FormField<ProfileType> {
  ProfileSelector({
    super.key,
    required List<ProfileType> profiles,
    super.validator,
    super.initialValue,
    ValueChanged<ProfileType>? onChanged,
  }) : super(
         builder: (field) => _ProfileOptions(
           field: field,
           profiles: profiles,
           onChanged: onChanged,
         ),
       );
}

class _ProfileOptions extends StatelessWidget {
  const _ProfileOptions({
    required this.field,
    required this.profiles,
    this.onChanged,
  });

  final FormFieldState<ProfileType> field;
  final List<ProfileType> profiles;
  final ValueChanged<ProfileType>? onChanged;

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
          onChanged: (profile) {
            field.didChange(profile);
            if (profile != null) onChanged?.call(profile);
          },
          child: Column(
            children: [
              for (final profile in profiles)
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
