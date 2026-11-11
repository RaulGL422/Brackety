import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n/gen/core_localizations.dart';
import '../theme/brackety_colors.dart';
import '../theme/tokens.dart';

enum ToastKind { info, success, error }

/// Short notices at the top of the screen: the bottom is where the scoreboard and the main
/// actions live, so a notice there covers what the user is about to press. One at a time
/// (a new one replaces the old), always closable, gone on its own after a few seconds.
class Toasts {
  Toasts._(this._host);

  final _ToastHostState? _host;

  static const short = Duration(seconds: 3);
  static const normal = Duration(seconds: 5);
  static const long = Duration(seconds: 8);

  /// Without a [ToastHost] above (some widget tests), notices are dropped.
  static Toasts of(BuildContext context) =>
      Toasts._(context.dependOnInheritedWidgetOfExactType<_ToastScope>()?.host);

  void show(
    String message, {
    ToastKind kind = ToastKind.info,
    Duration? duration,
  }) => _host?._show(
    message,
    kind,
    duration ?? (kind == ToastKind.error ? long : normal),
  );

  void hide() => _host?._hide();
}

/// Goes in `MaterialApp.builder`, above the navigator: notices stay on top of dialogs and
/// survive a change of screen.
class ToastHost extends StatefulWidget {
  const ToastHost({super.key, required this.child});

  final Widget child;

  @override
  State<ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<ToastHost> {
  _Notice? _notice;
  Timer? _timer;
  int _serial = 0;

  void _show(String message, ToastKind kind, Duration duration) {
    _timer?.cancel();
    setState(() => _notice = _Notice(++_serial, message, kind));
    _timer = Timer(duration, _hide);
    final view = View.maybeOf(context);
    if (view != null) {
      SemanticsService.sendAnnouncement(
        view,
        message,
        Directionality.of(context),
      );
    }
  }

  void _hide() {
    _timer?.cancel();
    if (mounted && _notice != null) setState(() => _notice = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    return _ToastScope(
      host: this,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, -0.4),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: notice == null
                    ? const SizedBox.shrink()
                    : _ToastCard(
                        key: ValueKey(notice.serial),
                        notice: notice,
                        onClose: _hide,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToastScope extends InheritedWidget {
  const _ToastScope({required this.host, required super.child});

  final _ToastHostState host;

  @override
  bool updateShouldNotify(_ToastScope oldWidget) => host != oldWidget.host;
}

class _Notice {
  const _Notice(this.serial, this.message, this.kind);

  final int serial;
  final String message;
  final ToastKind kind;
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({super.key, required this.notice, required this.onClose});

  final _Notice notice;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BracketyColors.of(context);
    final scheme = theme.colorScheme;
    final (icon, stripe) = switch (notice.kind) {
      ToastKind.info => (Icons.info_outline, scheme.primary),
      ToastKind.success => (Icons.check_circle_outline, colors.success),
      ToastKind.error => (Icons.error_outline, scheme.error),
    };
    // The band colours are dark in both themes: the notice stands out from any screen.
    final onBand = colors.onBand;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Dismissible(
            key: ValueKey(notice.serial),
            direction: DismissDirection.up,
            onDismissed: (_) => onClose(),
            child: Material(
              color: colors.band,
              elevation: 8,
              shadowColor: Colors.black54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.l),
              ),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 6,
                      color: stripe == scheme.primary ? onBand : stripe,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.m),
                      child: Icon(icon, color: onBand, size: 26),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.m,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            notice.message,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: onBand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: CoreLocalizations.of(context).closeNotice,
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: onClose,
                        child: SizedBox(
                          width: AppSizes.touchTarget + 4,
                          child: Icon(Icons.close, color: onBand),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
