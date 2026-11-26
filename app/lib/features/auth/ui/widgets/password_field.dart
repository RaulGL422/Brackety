import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../data/registration.dart';
import '../auth_texts.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.autofillHints,
    this.helperText,
    this.helper,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final Iterable<String> autofillHints;
  final String? helperText;

  /// Instead of [helperText]: what the password still needs, kept up to date as it is typed.
  final Widget? helper;
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
        helper: widget.helper,
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

/// A requirement under a new password: ticked once it holds.
class PasswordRule extends StatelessWidget {
  const PasswordRule({super.key, required this.met, required this.text});

  final bool met;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: met
          ? theme.colorScheme.onSurface
          : theme.colorScheme.onSurfaceVariant,
      fontWeight: met ? FontWeight.w700 : null,
    );
    return Row(
      children: [
        // Ticked or not, the words say it too: the icon is not the only signal.
        ExcludeSemantics(
          child: Icon(
            met ? Icons.check : Icons.circle_outlined,
            size: 16,
            color: style?.color,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}

/// The length rule of a new password, with how many characters it has so far.
class PasswordLengthRule extends StatelessWidget {
  const PasswordLengthRule({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        final count = value.text.length;
        final met = count >= passwordMinLength;
        return PasswordRule(
          met: met,
          text: met || count == 0
              ? l10n.passwordRuleLength(passwordMinLength)
              : l10n.passwordRuleProgress(passwordMinLength, count),
        );
      },
    );
  }
}

/// A password being chosen: the browser offers a new one, and the length rule ticks as it is typed.
class NewPasswordField extends StatelessWidget {
  const NewPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PasswordField(
      controller: controller,
      label: label,
      helper: PasswordLengthRule(controller: controller),
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      validator: (value) => validateNewPassword(l10n, value),
    );
  }
}
