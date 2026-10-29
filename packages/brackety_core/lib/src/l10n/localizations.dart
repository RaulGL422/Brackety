import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/gen/core_localizations.dart';

/// Delegates every Brackety app needs besides its own `AppLocalizations.delegate`.
const coreLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  CoreLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
