import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

// Fictitious sample data, never real people.
const _standings = [
  ('Lucía M.', 4, 0, 12),
  ('Hugo R.', 3, 1, 9),
  ('Martina G.', 2, 2, 6),
  ('Daniel P.', 1, 3, 3),
  ('Sara L.', 0, 4, 0),
];

class SamplesSection extends StatelessWidget {
  const SamplesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dsScoreboard, style: text.titleMedium),
        const SizedBox(height: AppSpacing.s),
        const _Scoreboard(),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.dsStandings, style: text.titleMedium),
        const SizedBox(height: AppSpacing.s),
        const _Standings(),
      ],
    );
  }
}

class _Scoreboard extends StatefulWidget {
  const _Scoreboard();

  @override
  State<_Scoreboard> createState() => _ScoreboardState();
}

class _ScoreboardState extends State<_Scoreboard> {
  var _colorA = CompetitorColor.red;
  var _colorB = CompetitorColor.white;
  final _scores = [3, 1];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.l,
          runSpacing: AppSpacing.s,
          children: [
            _ColorPicker(
              label: l10n.dsColorA,
              value: _colorA,
              onChanged: (c) => setState(() => _colorA = c),
            ),
            _ColorPicker(
              label: l10n.dsColorB,
              value: _colorB,
              onChanged: (c) => setState(() => _colorB = c),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Center(child: Text('01:42', style: text.displayMedium)),
        const SizedBox(height: AppSpacing.s),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, color) in [_colorA, _colorB].indexed) ...[
              if (i == 1) const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _CompetitorPanel(
                  name: _standings[i].$1,
                  color: color,
                  score: _scores[i],
                  penalties: i,
                  onScore: (delta) => setState(
                    () => _scores[i] = (_scores[i] + delta).clamp(0, 99),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final CompetitorColor value;
  final ValueChanged<CompetitorColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<CompetitorColor>(
      label: Text(label),
      initialSelection: value,
      onSelected: (c) => c == null ? null : onChanged(c),
      dropdownMenuEntries: [
        for (final c in CompetitorColor.values)
          DropdownMenuEntry(
            value: c,
            label: c.name,
            leadingIcon: Icon(Icons.circle, color: c.color),
          ),
      ],
    );
  }
}

class _CompetitorPanel extends StatelessWidget {
  const _CompetitorPanel({
    required this.name,
    required this.color,
    required this.score,
    required this.penalties,
    required this.onScore,
  });

  final String name;
  final CompetitorColor color;
  final int score;
  final int penalties;
  final ValueChanged<int> onScore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final fg = color.onColor;
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: fg,
      foregroundColor: color.color,
      minimumSize: const Size(
        AppSizes.scoreTouchTarget,
        AppSizes.scoreTouchTarget,
      ),
      textStyle: text.headlineMedium,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: color.color,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: text.titleLarge!.copyWith(color: fg),
            overflow: TextOverflow.ellipsis,
          ),
          Text('$score', style: text.displayLarge!.copyWith(color: fg)),
          Text(
            l10n.dsPenalties(penalties),
            style: text.bodyMedium!.copyWith(color: fg),
          ),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                style: buttonStyle,
                onPressed: () => onScore(-1),
                child: const Text('−1'),
              ),
              FilledButton(
                style: buttonStyle,
                onPressed: () => onScore(1),
                child: const Text('+1'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Standings extends StatelessWidget {
  const _Standings();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: Theme.of(context).textTheme.titleSmall,
        columns: [
          DataColumn(label: Text(l10n.dsPosition), numeric: true),
          DataColumn(label: Text(l10n.dsCompetitor)),
          DataColumn(label: Text(l10n.dsWins), numeric: true),
          DataColumn(label: Text(l10n.dsLosses), numeric: true),
          DataColumn(label: Text(l10n.dsPoints), numeric: true),
        ],
        rows: [
          for (final (i, (name, wins, losses, points)) in _standings.indexed)
            DataRow(
              color: i == 0
                  ? WidgetStatePropertyAll(c.tertiaryContainer)
                  : null,
              cells: [
                for (final value in [
                  '${i + 1}',
                  name,
                  '$wins',
                  '$losses',
                  '$points',
                ])
                  DataCell(
                    Text(
                      value,
                      style: TextStyle(
                        color: i == 0 ? c.onTertiaryContainer : null,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
