// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'core_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CoreLocalizationsEn extends CoreLocalizations {
  CoreLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get connectionTitle => 'Connection';

  @override
  String get connectionServer => 'Server';

  @override
  String get connectionStatusOk => 'Connected';

  @override
  String get connectionStatusError => 'Cannot reach the server';

  @override
  String get connectionServerToday => 'Server date';

  @override
  String get retry => 'Retry';
}
