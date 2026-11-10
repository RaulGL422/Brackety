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

  /// No description provided for @navLocks.
  ///
  /// In es, this message translates to:
  /// **'Bloqueos'**
  String get navLocks;

  /// No description provided for @navOrganizers.
  ///
  /// In es, this message translates to:
  /// **'Organizadores'**
  String get navOrganizers;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get refresh;

  /// No description provided for @loadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los datos.'**
  String get loadError;

  /// No description provided for @noServer.
  ///
  /// In es, this message translates to:
  /// **'No se puede conectar con el servidor.'**
  String get noServer;

  /// No description provided for @unexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Algo ha fallado. Inténtalo de nuevo.'**
  String get unexpectedError;

  /// No description provided for @adminNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'El acceso de superadmin no está configurado en este servidor.'**
  String get adminNotConfigured;

  /// No description provided for @adminAccessDenied.
  ///
  /// In es, this message translates to:
  /// **'Acceso denegado: la administración solo funciona desde su dominio protegido (Cloudflare Access).'**
  String get adminAccessDenied;

  /// No description provided for @tooManyRequests.
  ///
  /// In es, this message translates to:
  /// **'Demasiadas peticiones. Espera {seconds} s y vuelve a intentarlo.'**
  String tooManyRequests(int seconds);

  /// No description provided for @tooManyRequestsWait.
  ///
  /// In es, this message translates to:
  /// **'Demasiadas peticiones. Espera un momento y vuelve a intentarlo.'**
  String get tooManyRequestsWait;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Acceso de superadmin'**
  String get loginTitle;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get hidePassword;

  /// No description provided for @fieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get fieldRequired;

  /// No description provided for @loginSubmit.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get loginSubmit;

  /// No description provided for @loginInvalid.
  ///
  /// In es, this message translates to:
  /// **'Email o contraseña incorrectos.'**
  String get loginInvalid;

  /// No description provided for @loginLocked.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos fallidos: acceso bloqueado 15 minutos (bloqueo {lockId}).'**
  String loginLocked(String lockId);

  /// No description provided for @sessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha caducado. Vuelve a entrar.'**
  String get sessionExpired;

  /// No description provided for @locksTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloqueos activos'**
  String get locksTitle;

  /// No description provided for @locksEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay bloqueos activos.'**
  String get locksEmpty;

  /// No description provided for @lockColumnId.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo'**
  String get lockColumnId;

  /// No description provided for @lockColumnType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get lockColumnType;

  /// No description provided for @lockColumnWho.
  ///
  /// In es, this message translates to:
  /// **'Quién'**
  String get lockColumnWho;

  /// No description provided for @lockColumnTimeLeft.
  ///
  /// In es, this message translates to:
  /// **'Tiempo restante'**
  String get lockColumnTimeLeft;

  /// No description provided for @lockTypeEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get lockTypeEmail;

  /// No description provided for @lockTypeIp.
  ///
  /// In es, this message translates to:
  /// **'IP'**
  String get lockTypeIp;

  /// No description provided for @lockTypeAdmin.
  ///
  /// In es, this message translates to:
  /// **'Superadmin'**
  String get lockTypeAdmin;

  /// No description provided for @lockUnknownEmail.
  ///
  /// In es, this message translates to:
  /// **'Email sin cuenta'**
  String get lockUnknownEmail;

  /// No description provided for @lockMinutesLeft.
  ///
  /// In es, this message translates to:
  /// **'{minutes, plural, =1{Queda 1 min} other{Quedan {minutes} min}}'**
  String lockMinutesLeft(int minutes);

  /// No description provided for @lockUntil.
  ///
  /// In es, this message translates to:
  /// **'hasta las {time}'**
  String lockUntil(DateTime time);

  /// No description provided for @lockExpired.
  ///
  /// In es, this message translates to:
  /// **'Caducado'**
  String get lockExpired;

  /// No description provided for @lockRevoke.
  ///
  /// In es, this message translates to:
  /// **'Revocar'**
  String get lockRevoke;

  /// No description provided for @lockRevokeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Revocar el bloqueo {lockId}?'**
  String lockRevokeTitle(String lockId);

  /// No description provided for @lockRevokeBody.
  ///
  /// In es, this message translates to:
  /// **'Se borran sus intentos fallidos y se podrá volver a entrar al momento.'**
  String get lockRevokeBody;

  /// No description provided for @lockRevoked.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo {lockId} revocado.'**
  String lockRevoked(String lockId);

  /// No description provided for @lockAlreadyExpired.
  ///
  /// In es, this message translates to:
  /// **'Ese bloqueo ya había caducado. Lista actualizada.'**
  String get lockAlreadyExpired;

  /// No description provided for @organizersTitle.
  ///
  /// In es, this message translates to:
  /// **'Organizadores'**
  String get organizersTitle;

  /// No description provided for @organizerFilterPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get organizerFilterPending;

  /// No description provided for @organizerFilterValidated.
  ///
  /// In es, this message translates to:
  /// **'Validados'**
  String get organizerFilterValidated;

  /// No description provided for @organizerFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get organizerFilterAll;

  /// No description provided for @organizersEmptyPending.
  ///
  /// In es, this message translates to:
  /// **'No hay organizadores pendientes de validar.'**
  String get organizersEmptyPending;

  /// No description provided for @organizersEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay organizadores.'**
  String get organizersEmpty;

  /// No description provided for @organizerColumnName.
  ///
  /// In es, this message translates to:
  /// **'Organización'**
  String get organizerColumnName;

  /// No description provided for @organizerColumnTaxId.
  ///
  /// In es, this message translates to:
  /// **'CIF'**
  String get organizerColumnTaxId;

  /// No description provided for @organizerColumnType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get organizerColumnType;

  /// No description provided for @organizerColumnEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get organizerColumnEmail;

  /// No description provided for @organizerColumnCreated.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get organizerColumnCreated;

  /// No description provided for @organizerColumnState.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get organizerColumnState;

  /// No description provided for @organizerNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get organizerNoData;

  /// No description provided for @organizerNoTaxId.
  ///
  /// In es, this message translates to:
  /// **'—'**
  String get organizerNoTaxId;

  /// No description provided for @organizerTaxId.
  ///
  /// In es, this message translates to:
  /// **'CIF: {taxId}'**
  String organizerTaxId(String taxId);

  /// No description provided for @organizerDate.
  ///
  /// In es, this message translates to:
  /// **'{date}'**
  String organizerDate(DateTime date);

  /// No description provided for @organizerCreated.
  ///
  /// In es, this message translates to:
  /// **'Alta: {date}'**
  String organizerCreated(DateTime date);

  /// No description provided for @organizerClub.
  ///
  /// In es, this message translates to:
  /// **'Club'**
  String get organizerClub;

  /// No description provided for @organizerExternalEntity.
  ///
  /// In es, this message translates to:
  /// **'Entidad externa'**
  String get organizerExternalEntity;

  /// No description provided for @organizerPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get organizerPending;

  /// No description provided for @organizerValidated.
  ///
  /// In es, this message translates to:
  /// **'Validado'**
  String get organizerValidated;

  /// No description provided for @organizerValidate.
  ///
  /// In es, this message translates to:
  /// **'Validar'**
  String get organizerValidate;

  /// No description provided for @organizerValidateTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Validar {name}?'**
  String organizerValidateTitle(String name);

  /// No description provided for @organizerValidateBody.
  ///
  /// In es, this message translates to:
  /// **'Podrá publicar eventos. Si es la primera vez que se valida, recibirá un email avisándole.'**
  String get organizerValidateBody;

  /// No description provided for @organizerValidatedDone.
  ///
  /// In es, this message translates to:
  /// **'{name} validado.'**
  String organizerValidatedDone(String name);

  /// No description provided for @organizerNotFound.
  ///
  /// In es, this message translates to:
  /// **'Ese organizador ya no existe o ya no es organizador. Lista actualizada.'**
  String get organizerNotFound;

  /// No description provided for @navEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get navEvents;

  /// No description provided for @eventsTitle.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get eventsTitle;

  /// No description provided for @eventsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay eventos.'**
  String get eventsEmpty;

  /// No description provided for @eventColumnName.
  ///
  /// In es, this message translates to:
  /// **'Evento'**
  String get eventColumnName;

  /// No description provided for @eventColumnDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get eventColumnDate;

  /// No description provided for @eventColumnOwner.
  ///
  /// In es, this message translates to:
  /// **'Organizador'**
  String get eventColumnOwner;

  /// No description provided for @eventColumnMats.
  ///
  /// In es, this message translates to:
  /// **'Tapices'**
  String get eventColumnMats;

  /// No description provided for @eventColumnEntries.
  ///
  /// In es, this message translates to:
  /// **'Inscritos'**
  String get eventColumnEntries;

  /// No description provided for @eventColumnGroups.
  ///
  /// In es, this message translates to:
  /// **'Grupos'**
  String get eventColumnGroups;

  /// No description provided for @eventColumnMatches.
  ///
  /// In es, this message translates to:
  /// **'Combates disputados'**
  String get eventColumnMatches;

  /// No description provided for @eventDate.
  ///
  /// In es, this message translates to:
  /// **'{date}'**
  String eventDate(DateTime date);

  /// No description provided for @eventMatchesProgress.
  ///
  /// In es, this message translates to:
  /// **'{finished} de {total}'**
  String eventMatchesProgress(int finished, int total);

  /// No description provided for @eventCounts.
  ///
  /// In es, this message translates to:
  /// **'{entries, plural, =1{1 inscrito} other{{entries} inscritos}}, {groups, plural, =1{1 grupo} other{{groups} grupos}}, {finished} de {total} combates disputados'**
  String eventCounts(int entries, int groups, int finished, int total);

  /// No description provided for @eventsPageOf.
  ///
  /// In es, this message translates to:
  /// **'Página {page} de {pages}'**
  String eventsPageOf(int page, int pages);

  /// No description provided for @eventsPrevious.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get eventsPrevious;

  /// No description provided for @eventsNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get eventsNext;

  /// No description provided for @eventBack.
  ///
  /// In es, this message translates to:
  /// **'Volver a los eventos'**
  String get eventBack;

  /// No description provided for @eventEntries.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 inscrito} other{{count} inscritos}}'**
  String eventEntries(int count);

  /// No description provided for @eventMats.
  ///
  /// In es, this message translates to:
  /// **'Tapices'**
  String get eventMats;

  /// No description provided for @eventMatNoReferee.
  ///
  /// In es, this message translates to:
  /// **'Tapiz {number}: sin árbitro'**
  String eventMatNoReferee(int number);

  /// No description provided for @eventMatReferee.
  ///
  /// In es, this message translates to:
  /// **'Tapiz {number}: {referee}'**
  String eventMatReferee(int number, String referee);

  /// No description provided for @eventGroups.
  ///
  /// In es, this message translates to:
  /// **'Grupos'**
  String get eventGroups;

  /// No description provided for @eventNoGroups.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay grupos.'**
  String get eventNoGroups;

  /// No description provided for @groupTitle.
  ///
  /// In es, this message translates to:
  /// **'Grupo {number}, {category}'**
  String groupTitle(int number, String category);

  /// No description provided for @groupMat.
  ///
  /// In es, this message translates to:
  /// **'Tapiz {number}'**
  String groupMat(int number);

  /// No description provided for @matchTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo {number}'**
  String matchTeam(int number);

  /// No description provided for @matchPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get matchPending;

  /// No description provided for @matchInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get matchInProgress;

  /// No description provided for @matchFinished.
  ///
  /// In es, this message translates to:
  /// **'Terminado'**
  String get matchFinished;

  /// No description provided for @matchInReview.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get matchInReview;

  /// No description provided for @matchReset.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar'**
  String get matchReset;

  /// No description provided for @matchResetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Reiniciar el combate {order}?'**
  String matchResetTitle(int order);

  /// No description provided for @matchResetBody.
  ///
  /// In es, this message translates to:
  /// **'Se borran todas sus acciones y vuelve a estar pendiente, como si no hubiera empezado. El árbitro lo verá al actualizarse su tablero.'**
  String get matchResetBody;

  /// No description provided for @matchResetDone.
  ///
  /// In es, this message translates to:
  /// **'Combate reiniciado.'**
  String get matchResetDone;

  /// No description provided for @groupDissolve.
  ///
  /// In es, this message translates to:
  /// **'Deshacer grupo'**
  String get groupDissolve;

  /// No description provided for @groupDissolveTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Deshacer el grupo {number}?'**
  String groupDissolveTitle(int number);

  /// No description provided for @groupDissolveBody.
  ///
  /// In es, this message translates to:
  /// **'Se borran el grupo y sus combates, también los ya disputados. Sus alumnos vuelven a estar sin grupo y el ayudante puede agruparlos otra vez.'**
  String get groupDissolveBody;

  /// No description provided for @groupDissolved.
  ///
  /// In es, this message translates to:
  /// **'Grupo {number} deshecho.'**
  String groupDissolved(int number);

  /// No description provided for @competitionClear.
  ///
  /// In es, this message translates to:
  /// **'Vaciar la competición'**
  String get competitionClear;

  /// No description provided for @competitionClearTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Vaciar la competición de {name}?'**
  String competitionClearTitle(String name);

  /// No description provided for @competitionClearBody.
  ///
  /// In es, this message translates to:
  /// **'Se borran todos los grupos, combates, puntuaciones y equipos. Se conservan la configuración, los tapices, los árbitros y los inscritos. No se puede deshacer.'**
  String get competitionClearBody;

  /// No description provided for @competitionCleared.
  ///
  /// In es, this message translates to:
  /// **'Competición vaciada: {groups, plural, =1{1 grupo} other{{groups} grupos}} y {teams, plural, =1{1 equipo} other{{teams} equipos}} borrados.'**
  String competitionCleared(int groups, int teams);

  /// No description provided for @reasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get reasonLabel;

  /// No description provided for @reasonHelper.
  ///
  /// In es, this message translates to:
  /// **'Queda guardado en la auditoría.'**
  String get reasonHelper;

  /// No description provided for @typeToConfirm.
  ///
  /// In es, this message translates to:
  /// **'Escribe «{name}» para confirmar'**
  String typeToConfirm(String name);

  /// No description provided for @eventChanged.
  ///
  /// In es, this message translates to:
  /// **'El evento ha cambiado mientras tanto; se ha recargado.'**
  String get eventChanged;
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
