import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/core_localizations.dart';
import '../theme/tokens.dart';

/// Loading spinner, error with retry, or [data]. On a refresh it keeps showing the last data.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.onRetry,
    required this.data,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) data;

  @override
  Widget build(BuildContext context) {
    final l10n = CoreLocalizations.of(context);
    return switch (value) {
      AsyncValue(:final value?, hasValue: true) => data(value),
      AsyncError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.loadError, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.m),
              OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
      ),
      // Padded so a spinner inside a list does not sit on its neighbours.
      _ => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}
