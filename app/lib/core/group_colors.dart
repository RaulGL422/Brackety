import 'package:brackety_core/brackety_core.dart';

/// Tells groups apart when several share a mat. Never red or blue: those are the corners.
const _groupColors = [
  CompetitorColor.green,
  CompetitorColor.orange,
  CompetitorColor.purple,
  CompetitorColor.sky,
  CompetitorColor.yellow,
  CompetitorColor.pink,
];

CompetitorColor groupColor(int index) =>
    _groupColors[index % _groupColors.length];
