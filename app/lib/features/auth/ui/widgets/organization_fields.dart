import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../auth_texts.dart';
import 'acceptance_checkbox.dart';

/// What an organizer gives instead of a birth date: the organization, its CIF and the declaration.
class OrganizationFields extends StatelessWidget {
  const OrganizationFields({
    super.key,
    required this.name,
    required this.taxId,
    required this.declared,
    required this.onDeclaredChanged,
    required this.onTaxIdChanged,
    this.taxIdError,
  });

  final TextEditingController name;
  final TextEditingController taxId;
  final bool declared;
  final ValueChanged<bool> onDeclaredChanged;
  final ValueChanged<String> onTaxIdChanged;

  /// The server's verdict on the CIF, shown until the user edits it.
  final String? taxIdError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.organizationName],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.registerOrganizationName),
          validator: (value) => validateOrganizationName(l10n, value),
        ),
        const SizedBox(height: AppSpacing.m),
        TextFormField(
          controller: taxId,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          forceErrorText: taxIdError,
          onChanged: onTaxIdChanged,
          decoration: InputDecoration(
            labelText: l10n.registerTaxId,
            helperText: l10n.registerTaxIdHelper,
            helperMaxLines: 3,
          ),
          validator: (value) => validateTaxId(l10n, value),
        ),
        const SizedBox(height: AppSpacing.s),
        AcceptanceCheckbox(
          title: Text(l10n.registerRepresentative),
          requiredText: l10n.registerRepresentativeRequired,
          initialValue: declared,
          onChanged: onDeclaredChanged,
        ),
      ],
    );
  }
}
