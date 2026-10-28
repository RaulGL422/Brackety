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
}
