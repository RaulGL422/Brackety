import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// An AppBar action with its label; on a phone only the icon (label as tooltip), so it never
/// covers the labelled back button on the left.
class AppBarAction extends StatelessWidget {
  const AppBarAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (WindowSize.of(context) == WindowSize.compact) {
      return IconButton(tooltip: label, icon: Icon(icon), onPressed: onPressed);
    }
    return TextButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
