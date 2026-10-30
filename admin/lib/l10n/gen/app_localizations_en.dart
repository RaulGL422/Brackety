// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Brackety Admin';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navConnection => 'Connection';

  @override
  String get dashboardTitle => 'Superadmin dashboard';

  @override
  String get dashboardSubtitle => 'Platform-wide management.';

  @override
  String get navDesignSystem => 'Design';

  @override
  String get dsTitle => 'Design system';

  @override
  String get dsIntro =>
      'Debug builds only. Everything below uses the real theme with the chosen palette and mode.';

  @override
  String get dsPalette => 'Palette';

  @override
  String get dsPaletteElectric => 'Electric';

  @override
  String get dsPaletteFire => 'Fire';

  @override
  String get dsPaletteNight => 'Night';

  @override
  String get dsMode => 'Mode';

  @override
  String get dsModeLight => 'Light';

  @override
  String get dsModeDark => 'Dark';

  @override
  String dsTextScale(int percent) {
    return 'Text at $percent %';
  }

  @override
  String get dsColors => 'Colors';

  @override
  String get dsStatusColors => 'Status';

  @override
  String get dsCompetitorColors => 'Competitor colors';

  @override
  String get dsContrastHint =>
      'AA: normal text (≥ 4.5). AA large: large text only (≥ 3). ✗: not for text.';

  @override
  String get dsContrastLarge => 'AA large';

  @override
  String get dsTypography => 'Typography';

  @override
  String get dsTypeSample => 'Sample league 2027 · 0123456789';

  @override
  String get dsSpacing => 'Spacing';

  @override
  String get dsRadius => 'Radius';

  @override
  String get dsComponents => 'Components';

  @override
  String get dsSave => 'Save';

  @override
  String get dsTonal => 'Sign up';

  @override
  String get dsCancel => 'Cancel';

  @override
  String get dsMore => 'See more';

  @override
  String get dsDisabled => 'Disabled';

  @override
  String get dsFieldLabel => 'Club name';

  @override
  String get dsFieldHint => 'Sample Sports Club';

  @override
  String get dsFieldError => 'Required field';

  @override
  String get dsNotifications => 'Notifications';

  @override
  String get dsCategoryKids => 'Kids';

  @override
  String get dsCategoryCadet => 'Cadet';

  @override
  String get dsCategorySenior => 'Senior';

  @override
  String get dsCardTitle => 'Sample league 2027';

  @override
  String get dsCardSubtitle => '3 phases · 120 entries';

  @override
  String get dsPaid => 'Paid';

  @override
  String get dsPending => 'Pending';

  @override
  String get dsRejected => 'Rejected';

  @override
  String get dsSamples => 'Samples';

  @override
  String get dsScoreboard => 'Scoreboard';

  @override
  String get dsColorA => 'Color A';

  @override
  String get dsColorB => 'Color B';

  @override
  String dsPenalties(int count) {
    return 'Penalties: $count';
  }

  @override
  String get dsStandings => 'Standings';

  @override
  String get dsPosition => 'Pos.';

  @override
  String get dsCompetitor => 'Competitor';

  @override
  String get dsWins => 'W';

  @override
  String get dsLosses => 'L';

  @override
  String get dsPoints => 'Pts';
}
