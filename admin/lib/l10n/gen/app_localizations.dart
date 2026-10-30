import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Brackety Admin'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In es, this message translates to:
  /// **'Panel'**
  String get navDashboard;

  /// No description provided for @navConnection.
  ///
  /// In es, this message translates to:
  /// **'Conexión'**
  String get navConnection;

  /// No description provided for @dashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de superadmin'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión global de la plataforma.'**
  String get dashboardSubtitle;

  /// No description provided for @navDesignSystem.
  ///
  /// In es, this message translates to:
  /// **'Diseño'**
  String get navDesignSystem;

  /// No description provided for @dsTitle.
  ///
  /// In es, this message translates to:
  /// **'Sistema de diseño'**
  String get dsTitle;

  /// No description provided for @dsIntro.
  ///
  /// In es, this message translates to:
  /// **'Solo en builds debug. Todo lo de abajo usa el tema real en el modo elegido.'**
  String get dsIntro;

  /// No description provided for @dsModeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get dsModeLight;

  /// No description provided for @dsModeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get dsModeDark;

  /// No description provided for @dsTextScale.
  ///
  /// In es, this message translates to:
  /// **'Texto al {percent} %'**
  String dsTextScale(int percent);

  /// No description provided for @dsColors.
  ///
  /// In es, this message translates to:
  /// **'Colores'**
  String get dsColors;

  /// No description provided for @dsStatusColors.
  ///
  /// In es, this message translates to:
  /// **'Estados'**
  String get dsStatusColors;

  /// No description provided for @dsCompetitorColors.
  ///
  /// In es, this message translates to:
  /// **'Colores de competidor'**
  String get dsCompetitorColors;

  /// No description provided for @dsContrastHint.
  ///
  /// In es, this message translates to:
  /// **'AA: texto normal (≥ 4,5). AA grande: solo texto grande (≥ 3). ✗: no usar para texto.'**
  String get dsContrastHint;

  /// No description provided for @dsContrastLarge.
  ///
  /// In es, this message translates to:
  /// **'AA grande'**
  String get dsContrastLarge;

  /// No description provided for @dsTypography.
  ///
  /// In es, this message translates to:
  /// **'Tipografía'**
  String get dsTypography;

  /// No description provided for @dsTypeSample.
  ///
  /// In es, this message translates to:
  /// **'Liga de ejemplo 2027 · 0123456789'**
  String get dsTypeSample;

  /// No description provided for @dsSpacing.
  ///
  /// In es, this message translates to:
  /// **'Espaciado'**
  String get dsSpacing;

  /// No description provided for @dsRadius.
  ///
  /// In es, this message translates to:
  /// **'Radios'**
  String get dsRadius;

  /// No description provided for @dsComponents.
  ///
  /// In es, this message translates to:
  /// **'Componentes'**
  String get dsComponents;

  /// No description provided for @dsSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get dsSave;

  /// No description provided for @dsTonal.
  ///
  /// In es, this message translates to:
  /// **'Inscribirse'**
  String get dsTonal;

  /// No description provided for @dsCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get dsCancel;

  /// No description provided for @dsMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get dsMore;

  /// No description provided for @dsDisabled.
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get dsDisabled;

  /// No description provided for @dsFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del club'**
  String get dsFieldLabel;

  /// No description provided for @dsFieldHint.
  ///
  /// In es, this message translates to:
  /// **'Club Deportivo Ejemplo'**
  String get dsFieldHint;

  /// No description provided for @dsFieldError.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get dsFieldError;

  /// No description provided for @dsNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get dsNotifications;

  /// No description provided for @dsCategoryKids.
  ///
  /// In es, this message translates to:
  /// **'Infantil'**
  String get dsCategoryKids;

  /// No description provided for @dsCategoryCadet.
  ///
  /// In es, this message translates to:
  /// **'Cadete'**
  String get dsCategoryCadet;

  /// No description provided for @dsCategorySenior.
  ///
  /// In es, this message translates to:
  /// **'Sénior'**
  String get dsCategorySenior;

  /// No description provided for @dsCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Liga de ejemplo 2027'**
  String get dsCardTitle;

  /// No description provided for @dsCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'3 fases · 120 inscritos'**
  String get dsCardSubtitle;

  /// No description provided for @dsPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get dsPaid;

  /// No description provided for @dsPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get dsPending;

  /// No description provided for @dsRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get dsRejected;

  /// No description provided for @dsSamples.
  ///
  /// In es, this message translates to:
  /// **'Ejemplos'**
  String get dsSamples;

  /// No description provided for @dsScoreboard.
  ///
  /// In es, this message translates to:
  /// **'Marcador'**
  String get dsScoreboard;

  /// No description provided for @dsColorA.
  ///
  /// In es, this message translates to:
  /// **'Color A'**
  String get dsColorA;

  /// No description provided for @dsColorB.
  ///
  /// In es, this message translates to:
  /// **'Color B'**
  String get dsColorB;

  /// No description provided for @dsPenalties.
  ///
  /// In es, this message translates to:
  /// **'Amonestaciones: {count}'**
  String dsPenalties(int count);

  /// No description provided for @dsStandings.
  ///
  /// In es, this message translates to:
  /// **'Clasificación'**
  String get dsStandings;

  /// No description provided for @dsPosition.
  ///
  /// In es, this message translates to:
  /// **'Pos.'**
  String get dsPosition;

  /// No description provided for @dsCompetitor.
  ///
  /// In es, this message translates to:
  /// **'Competidor'**
  String get dsCompetitor;

  /// No description provided for @dsWins.
  ///
  /// In es, this message translates to:
  /// **'V'**
  String get dsWins;

  /// No description provided for @dsLosses.
  ///
  /// In es, this message translates to:
  /// **'D'**
  String get dsLosses;

  /// No description provided for @dsPoints.
  ///
  /// In es, this message translates to:
  /// **'Pts'**
  String get dsPoints;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
