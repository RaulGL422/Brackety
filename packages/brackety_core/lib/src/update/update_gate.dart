import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/core_localizations.dart';
import '../theme/tokens.dart';
import 'reload_stub.dart' if (dart.library.js_interop) 'reload_web.dart';
import 'update_check.dart';

/// Above the whole app: once a new release is out, nothing can be done but update (Raul,
/// 2026-11-25). While [hold] (actions not yet sent, which a reload would put at risk) only a strip
/// says so; the notice comes as soon as they are out.
class UpdateGate extends ConsumerWidget {
  const UpdateGate({
    super.key,
    required this.child,
    this.hold = false,
    this.reload = reloadPage,
  });

  final Widget child;
  final bool hold;

  /// Tests replace it; on the web it loads the page again.
  final VoidCallback reload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(updateAvailableProvider)) return child;
    final l10n = CoreLocalizations.of(context);
    if (hold) {
      return Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s),
                child: Row(
                  spacing: AppSpacing.s,
                  children: [
                    const Icon(Icons.system_update_alt),
                    Expanded(child: Text(l10n.updateWaiting)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      );
    }
    return Stack(
      children: [
        ExcludeSemantics(child: child),
        const ModalBarrier(dismissible: false, color: Colors.black54),
        Center(child: _UpdateNotice(reload: reload)),
      ],
    );
  }
}

class _UpdateNotice extends StatelessWidget {
  const _UpdateNotice({required this.reload});

  final VoidCallback reload;

  @override
  Widget build(BuildContext context) {
    final l10n = CoreLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
        child: Material(
          borderRadius: BorderRadius.circular(AppRadius.l),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.m,
              children: [
                Semantics(
                  header: true,
                  child: Text(l10n.updateTitle, style: text.titleLarge),
                ),
                Text(l10n.updateBody),
                FilledButton.icon(
                  autofocus: true,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.updateButton),
                  onPressed: reload,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
