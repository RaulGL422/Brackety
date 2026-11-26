import 'dart:math';

import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../events/data/my_event.dart';

/// The phases of a league in a row that scrolls sideways, about three in view with [current]
/// in the middle (Raul, 2026-11-26): a league of 35 rounds fits as well as one of three. Each
/// phase is a shortcut to it: the results of a finished one, the preparation of a coming one.
class PhaseRail extends StatefulWidget {
  const PhaseRail({
    super.key,
    required this.phases,
    required this.current,
    required this.onOpen,
  });

  final List<MyEvent> phases;
  final MyEvent current;

  /// Null for a phase this account cannot open.
  final VoidCallback? Function(MyEvent phase) onOpen;

  static const double tileWidth = 104;
  static const double gap = AppSpacing.s;

  @override
  State<PhaseRail> createState() => _PhaseRailState();
}

class _PhaseRailState extends State<PhaseRail> {
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  /// Created once the width is known, already scrolled so the current phase sits in the middle.
  ScrollController _controllerFor(double width) => _scroll ??= ScrollController(
    initialScrollOffset: max(
      0,
      widget.phases.indexOf(widget.current) *
              (PhaseRail.tileWidth + PhaseRail.gap) -
          (width - PhaseRail.tileWidth) / 2,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      container: true,
      label: l10n.homePhaseRail,
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          // Taller with large text, so the two lines of each phase still fit.
          height: AppSizes.touchTarget + 24 * scale,
          child: ListView.separated(
            controller: _controllerFor(constraints.maxWidth),
            scrollDirection: Axis.horizontal,
            itemCount: widget.phases.length,
            separatorBuilder: (_, _) => const SizedBox(width: PhaseRail.gap),
            itemBuilder: (context, i) {
              final phase = widget.phases[i];
              return _PhaseTile(
                phase: phase,
                current: phase.id == widget.current.id,
                onTap: widget.onOpen(phase),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PhaseTile extends StatelessWidget {
  const _PhaseTile({
    required this.phase,
    required this.current,
    required this.onTap,
  });

  final MyEvent phase;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Played: filled in ink. On now: a thick frame. To come: a thin one.
    final (background, foreground, border) = switch (phase.phaseState) {
      PhaseState.finished => (
        scheme.onSurface,
        scheme.surface,
        BorderSide.none,
      ),
      PhaseState.inProgress => (
        Colors.transparent,
        scheme.onSurface,
        BorderSide(color: scheme.onSurface, width: 3),
      ),
      PhaseState.notStarted => (
        Colors.transparent,
        scheme.onSurface,
        BorderSide(color: scheme.outline),
      ),
    };
    return SizedBox(
      width: PhaseRail.tileWidth,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          side: border,
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            selected: current,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: AppSpacing.xs,
              ),
              child: _TileText(phase: phase, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

/// «Fase 3» over «✓ Terminada», «En curso» or the day it is due.
class _TileText extends StatelessWidget {
  const _TileText({required this.phase, required this.color});

  final MyEvent phase;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final done = phase.phaseState == PhaseState.finished;
    final status = switch (phase.phaseState) {
      PhaseState.finished => l10n.homePhaseDone,
      PhaseState.inProgress => l10n.homePhaseLive,
      PhaseState.notStarted => DateFormat.MMMd(locale).format(phase.date),
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homePhase(phase.phaseNumber),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(color: color),
        ),
        Row(
          children: [
            if (done) ...[
              Icon(Icons.check, size: 14, color: color),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
