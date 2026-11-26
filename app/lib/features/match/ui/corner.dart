import 'package:brackety_core/brackety_core.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/match_view.dart';

CompetitorColor cornerColor(Side side) =>
    side == Side.red ? CompetitorColor.red : CompetitorColor.blue;

String cornerName(AppLocalizations l10n, Side side) =>
    side == Side.red ? l10n.cornerRed : l10n.cornerBlue;
