import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../data/registration.dart';
import '../auth_texts.dart';

/// The type of the account in a dropdown (Raul, 2026-11-26); under it, what the chosen type is for.
class ProfileSelector extends StatelessWidget {
  const ProfileSelector({
    super.key,
    required this.profiles,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final List<ProfileType> profiles;
  final ProfileType? value;
  final ValueChanged<ProfileType> onChanged;
  final FormFieldValidator<ProfileType>? validator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = this.value;
    return DropdownButtonFormField<ProfileType>(
      initialValue: value,
      isExpanded: true,
      hint: Text(l10n.registerProfileHint),
      decoration: InputDecoration(
        labelText: l10n.registerProfile,
        helperText: value == null ? null : profileHint(l10n, value),
        helperMaxLines: 3,
      ),
      items: [
        for (final profile in profiles)
          DropdownMenuItem(
            value: profile,
            child: Text(profileName(l10n, profile)),
          ),
      ],
      onChanged: (profile) {
        if (profile != null) onChanged(profile);
      },
      validator: validator,
    );
  }
}
