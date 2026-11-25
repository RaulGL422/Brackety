import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// A result of a form as a notice on its own tinted ground: an error, or a success. The icon
/// says which as well as the colour does.
class FormMessage extends StatelessWidget {
  const FormMessage.error(this.text, {super.key}) : success = false;

  const FormMessage.success(this.text, {super.key}) : success = true;

  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final colors = BracketyColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (ground, ink) = success
        ? (colors.successContainer, colors.onSuccessContainer)
        : (scheme.errorContainer, scheme.onErrorContainer);
    // A live region: a screen reader reads the result out as it appears, without moving there.
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ground,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: _row(ink),
        ),
      ),
    );
  }

  Widget _row(Color ink) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          success ? Icons.check_circle_outline : Icons.error_outline,
          color: ink,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(text, style: TextStyle(color: ink)),
        ),
      ],
    );
  }
}
