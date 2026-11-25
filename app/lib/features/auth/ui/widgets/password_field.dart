import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.autofillHints,
    this.helperText,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final Iterable<String> autofillHints;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// Ready to type on arrival: the only field left to fill (GR-2, a QR referee back in).
  final bool autofocus;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      obscureText: _hidden,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        // Out of the Tab order (field to field, then the buttons); still tappable.
        suffixIcon: ExcludeFocus(
          child: IconButton(
            tooltip: _hidden ? l10n.showPassword : l10n.hidePassword,
            icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _hidden = !_hidden),
          ),
        ),
      ),
    );
  }
}
