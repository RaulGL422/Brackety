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
  /// **'Brackety'**
  String get appTitle;

  /// No description provided for @navConnection.
  ///
  /// In es, this message translates to:
  /// **'Conexión'**
  String get navConnection;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @loadError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar. Comprueba la conexión.'**
  String get loadError;

  /// No description provided for @noServer.
  ///
  /// In es, this message translates to:
  /// **'No hay conexión con el servidor.'**
  String get noServer;

  /// No description provided for @unexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Algo ha ido mal. Inténtalo de nuevo.'**
  String get unexpectedError;

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

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @continueAction.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueAction;

  /// No description provided for @fieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio.'**
  String get fieldRequired;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe un email válido.'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 10 caracteres.'**
  String get passwordHint;

  /// No description provided for @passwordTooShort.
  ///
  /// In es, this message translates to:
  /// **'La contraseña necesita al menos 10 caracteres.'**
  String get passwordTooShort;

  /// No description provided for @passwordTooLong.
  ///
  /// In es, this message translates to:
  /// **'La contraseña admite como máximo 128 caracteres.'**
  String get passwordTooLong;

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

  /// No description provided for @goToLogin.
  ///
  /// In es, this message translates to:
  /// **'Ir a iniciar sesión'**
  String get goToLogin;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get loginTitle;

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
  /// **'Cuenta bloqueada 15 minutos por demasiados intentos fallidos. Si necesitas ayuda, indica el código {lockId}.'**
  String loginLocked(String lockId);

  /// No description provided for @loginForgot.
  ///
  /// In es, this message translates to:
  /// **'¿Has olvidado la contraseña?'**
  String get loginForgot;

  /// No description provided for @loginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get loginNoAccount;

  /// No description provided for @loginPasswordChanged.
  ///
  /// In es, this message translates to:
  /// **'Contraseña cambiada. Ya puedes entrar con la nueva.'**
  String get loginPasswordChanged;

  /// No description provided for @loginDemoAccounts.
  ///
  /// In es, this message translates to:
  /// **'Cuentas de prueba (solo en desarrollo)'**
  String get loginDemoAccounts;

  /// No description provided for @restoreTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta pendiente de borrado'**
  String get restoreTitle;

  /// No description provided for @restoreBody.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta se borrará el {date}. ¿Quieres recuperarla?'**
  String restoreBody(String date);

  /// No description provided for @restoreConfirm.
  ///
  /// In es, this message translates to:
  /// **'Recuperar cuenta'**
  String get restoreConfirm;

  /// No description provided for @restoreExpired.
  ///
  /// In es, this message translates to:
  /// **'Ha pasado demasiado tiempo. Vuelve a entrar para recuperar la cuenta.'**
  String get restoreExpired;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerTitle;

  /// No description provided for @registerSubmit.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerSubmit;

  /// No description provided for @registerBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get registerBirthDate;

  /// No description provided for @registerUnderage.
  ///
  /// In es, this message translates to:
  /// **'Los menores de 14 años no pueden crear su propia cuenta. Su padre, madre o tutor lo da de alta desde su cuenta añadiendo un perfil de menor (disponible próximamente).'**
  String get registerUnderage;

  /// No description provided for @registerProfile.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo vas a usar Brackety?'**
  String get registerProfile;

  /// No description provided for @registerProfileRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige un perfil.'**
  String get registerProfileRequired;

  /// No description provided for @profileClub.
  ///
  /// In es, this message translates to:
  /// **'Club'**
  String get profileClub;

  /// No description provided for @profileClubHint.
  ///
  /// In es, this message translates to:
  /// **'Organiza eventos e inscribe a sus deportistas.'**
  String get profileClubHint;

  /// No description provided for @profileExternalEntity.
  ///
  /// In es, this message translates to:
  /// **'Entidad externa'**
  String get profileExternalEntity;

  /// No description provided for @profileExternalEntityHint.
  ///
  /// In es, this message translates to:
  /// **'Federación, ayuntamiento u otra entidad que organiza eventos.'**
  String get profileExternalEntityHint;

  /// No description provided for @profileHelper.
  ///
  /// In es, this message translates to:
  /// **'Ayudante'**
  String get profileHelper;

  /// No description provided for @profileHelperHint.
  ///
  /// In es, this message translates to:
  /// **'Colabora en los eventos: grupos, mesa o arbitraje.'**
  String get profileHelperHint;

  /// No description provided for @profileExternal.
  ///
  /// In es, this message translates to:
  /// **'Externo'**
  String get profileExternal;

  /// No description provided for @profileExternalHint.
  ///
  /// In es, this message translates to:
  /// **'Sigue eventos y resultados sin pertenecer a un club.'**
  String get profileExternalHint;

  /// No description provided for @profileStudent.
  ///
  /// In es, this message translates to:
  /// **'Alumno'**
  String get profileStudent;

  /// No description provided for @profileStudentHint.
  ///
  /// In es, this message translates to:
  /// **'Deportista que compite con su club.'**
  String get profileStudentHint;

  /// No description provided for @registerAccept.
  ///
  /// In es, this message translates to:
  /// **'Acepto los términos de uso y la política de privacidad.'**
  String get registerAccept;

  /// No description provided for @registerAcceptRequired.
  ///
  /// In es, this message translates to:
  /// **'Debes aceptarlos para crear la cuenta.'**
  String get registerAcceptRequired;

  /// No description provided for @registerHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Entra'**
  String get registerHaveAccount;

  /// No description provided for @checkEmailTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu email'**
  String get checkEmailTitle;

  /// No description provided for @checkEmailBody.
  ///
  /// In es, this message translates to:
  /// **'Te hemos enviado un email. Abre su enlace para verificar la cuenta; caduca en 24 horas.'**
  String get checkEmailBody;

  /// No description provided for @resendEmail.
  ///
  /// In es, this message translates to:
  /// **'Reenviar email'**
  String get resendEmail;

  /// No description provided for @resendSent.
  ///
  /// In es, this message translates to:
  /// **'Email enviado.'**
  String get resendSent;

  /// No description provided for @verifyBanner.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu email: algunas acciones lo necesitan.'**
  String get verifyBanner;

  /// No description provided for @verifyTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificar email'**
  String get verifyTitle;

  /// No description provided for @verifySuccess.
  ///
  /// In es, this message translates to:
  /// **'Email verificado. ¡Gracias!'**
  String get verifySuccess;

  /// No description provided for @linkInvalid.
  ///
  /// In es, this message translates to:
  /// **'El enlace no es válido o ha caducado.'**
  String get linkInvalid;

  /// No description provided for @forgotTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get forgotTitle;

  /// No description provided for @forgotIntro.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu email y te enviaremos un enlace para elegir una contraseña nueva.'**
  String get forgotIntro;

  /// No description provided for @forgotSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get forgotSubmit;

  /// No description provided for @forgotSent.
  ///
  /// In es, this message translates to:
  /// **'Si hay una cuenta con ese email, te hemos enviado un enlace para cambiar la contraseña.'**
  String get forgotSent;

  /// No description provided for @resetTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get resetTitle;

  /// No description provided for @resetNewPassword.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get resetNewPassword;

  /// No description provided for @resetConfirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Repite la contraseña'**
  String get resetConfirmPassword;

  /// No description provided for @resetMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get resetMismatch;

  /// No description provided for @resetSubmit.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get resetSubmit;

  /// No description provided for @resetRequestNew.
  ///
  /// In es, this message translates to:
  /// **'Pedir otro enlace'**
  String get resetRequestNew;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get logout;

  /// No description provided for @eventsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis eventos'**
  String get eventsTitle;

  /// No description provided for @eventsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes eventos asignados.'**
  String get eventsEmpty;

  /// No description provided for @roleClub.
  ///
  /// In es, this message translates to:
  /// **'Club'**
  String get roleClub;

  /// No description provided for @roleGrouper.
  ///
  /// In es, this message translates to:
  /// **'Ayudante'**
  String get roleGrouper;

  /// No description provided for @roleReferee.
  ///
  /// In es, this message translates to:
  /// **'Árbitro'**
  String get roleReferee;

  /// No description provided for @eventMakeGroups.
  ///
  /// In es, this message translates to:
  /// **'Crear grupos'**
  String get eventMakeGroups;

  /// No description provided for @eventMyMat.
  ///
  /// In es, this message translates to:
  /// **'Tapiz {number}'**
  String eventMyMat(int number);

  /// No description provided for @eventClubPanel.
  ///
  /// In es, this message translates to:
  /// **'Panel del club'**
  String get eventClubPanel;

  /// No description provided for @categoriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categoriesTitle;

  /// No description provided for @categoriesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay inscritos.'**
  String get categoriesEmpty;

  /// No description provided for @categoryCounts.
  ///
  /// In es, this message translates to:
  /// **'{participants} inscritos · {grouped} en grupos'**
  String categoryCounts(int participants, int grouped);

  /// No description provided for @categoryAges.
  ///
  /// In es, this message translates to:
  /// **'{name} años'**
  String categoryAges(String name);

  /// No description provided for @sortByName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get sortByName;

  /// No description provided for @sortByHeight.
  ///
  /// In es, this message translates to:
  /// **'Estatura'**
  String get sortByHeight;

  /// No description provided for @participantDetails.
  ///
  /// In es, this message translates to:
  /// **'{age} años · {height}'**
  String participantDetails(int age, String height);

  /// No description provided for @heightCm.
  ///
  /// In es, this message translates to:
  /// **'{cm} cm'**
  String heightCm(int cm);

  /// No description provided for @heightUnknown.
  ///
  /// In es, this message translates to:
  /// **'sin estatura'**
  String get heightUnknown;

  /// No description provided for @participantGrouped.
  ///
  /// In es, this message translates to:
  /// **'Grupo {group} · Tapiz {mat}'**
  String participantGrouped(int group, int mat);

  /// No description provided for @draftGroup.
  ///
  /// In es, this message translates to:
  /// **'Grupo {number}'**
  String draftGroup(int number);

  /// No description provided for @draftCount.
  ///
  /// In es, this message translates to:
  /// **'{count}/4'**
  String draftCount(int count);

  /// No description provided for @draftGhost.
  ///
  /// In es, this message translates to:
  /// **'Competidor fantasma'**
  String get draftGhost;

  /// No description provided for @draftGhostHint.
  ///
  /// In es, this message translates to:
  /// **'Elige al fantasma: combate pero no puntúa.'**
  String get draftGhostHint;

  /// No description provided for @draftAddGroup.
  ///
  /// In es, this message translates to:
  /// **'Añadir grupo'**
  String get draftAddGroup;

  /// No description provided for @draftRemoveGroup.
  ///
  /// In es, this message translates to:
  /// **'Quitar grupo'**
  String get draftRemoveGroup;

  /// No description provided for @createGroup.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Crear grupo} other{Crear grupos}}'**
  String createGroup(int count);

  /// No description provided for @groupsCreatedTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Grupo creado} other{Grupos creados}}'**
  String groupsCreatedTitle(int count);

  /// No description provided for @groupsCreatedBody.
  ///
  /// In es, this message translates to:
  /// **'{groups} → Tapiz {mat}'**
  String groupsCreatedBody(String groups, int mat);

  /// No description provided for @groupsConflict.
  ///
  /// In es, this message translates to:
  /// **'Algún alumno ya está en un grupo. La lista se ha actualizado.'**
  String get groupsConflict;

  /// No description provided for @groupsError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido crear los grupos.'**
  String get groupsError;

  /// No description provided for @ok.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get ok;

  /// No description provided for @ghostBadge.
  ///
  /// In es, this message translates to:
  /// **'Fantasma'**
  String get ghostBadge;

  /// No description provided for @matTitle.
  ///
  /// In es, this message translates to:
  /// **'Tapiz {number}'**
  String matTitle(int number);

  /// No description provided for @matEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay grupos en este tapiz.'**
  String get matEmpty;

  /// No description provided for @matGroupHeader.
  ///
  /// In es, this message translates to:
  /// **'Grupo {number} · {category} años'**
  String matGroupHeader(int number, String category);

  /// No description provided for @matRecommended.
  ///
  /// In es, this message translates to:
  /// **'Siguiente recomendado'**
  String get matRecommended;

  /// No description provided for @matInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get matInProgress;

  /// No description provided for @matPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get matPending;

  /// No description provided for @matFinished.
  ///
  /// In es, this message translates to:
  /// **'Terminados'**
  String get matFinished;

  /// No description provided for @matWaiting.
  ///
  /// In es, this message translates to:
  /// **'Un luchador está combatiendo en otro tapiz'**
  String get matWaiting;

  /// No description provided for @matNoneAvailable.
  ///
  /// In es, this message translates to:
  /// **'Ningún combate puede empezar ahora.'**
  String get matNoneAvailable;

  /// No description provided for @versus.
  ///
  /// In es, this message translates to:
  /// **'vs'**
  String get versus;

  /// No description provided for @scoreboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Tapiz {mat} · Grupo {group}'**
  String scoreboardTitle(int mat, int group);

  /// No description provided for @cornerRed.
  ///
  /// In es, this message translates to:
  /// **'Rojo'**
  String get cornerRed;

  /// No description provided for @cornerBlue.
  ///
  /// In es, this message translates to:
  /// **'Azul'**
  String get cornerBlue;

  /// No description provided for @clockStart.
  ///
  /// In es, this message translates to:
  /// **'Iniciar'**
  String get clockStart;

  /// No description provided for @clockStop.
  ///
  /// In es, this message translates to:
  /// **'Parar'**
  String get clockStop;

  /// No description provided for @clockResume.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get clockResume;

  /// No description provided for @finishMatch.
  ///
  /// In es, this message translates to:
  /// **'Finalizar combate'**
  String get finishMatch;

  /// No description provided for @matchFinished.
  ///
  /// In es, this message translates to:
  /// **'Combate finalizado'**
  String get matchFinished;

  /// No description provided for @backToMat.
  ///
  /// In es, this message translates to:
  /// **'Volver al tapiz'**
  String get backToMat;

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @timeline.
  ///
  /// In es, this message translates to:
  /// **'Línea de tiempo'**
  String get timeline;

  /// No description provided for @addPoint.
  ///
  /// In es, this message translates to:
  /// **'+1'**
  String get addPoint;

  /// No description provided for @warningsCount.
  ///
  /// In es, this message translates to:
  /// **'Advertencias: {count}'**
  String warningsCount(int count);

  /// No description provided for @oneHandCount.
  ///
  /// In es, this message translates to:
  /// **'Una mano: {count}'**
  String oneHandCount(int count);

  /// No description provided for @disqualified.
  ///
  /// In es, this message translates to:
  /// **'Descalificado'**
  String get disqualified;

  /// No description provided for @actionWarning.
  ///
  /// In es, this message translates to:
  /// **'Advertencia'**
  String get actionWarning;

  /// No description provided for @actionOneHand.
  ///
  /// In es, this message translates to:
  /// **'Advertencia por golpear con una mano'**
  String get actionOneHand;

  /// No description provided for @actionDisqualify.
  ///
  /// In es, this message translates to:
  /// **'Descalificación'**
  String get actionDisqualify;

  /// No description provided for @reasonTitle.
  ///
  /// In es, this message translates to:
  /// **'{action} · {fighter}'**
  String reasonTitle(String action, String fighter);

  /// No description provided for @reasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo (obligatorio)'**
  String get reasonLabel;

  /// No description provided for @reasonConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro? Queda registrado.'**
  String get reasonConfirm;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @endPoints.
  ///
  /// In es, this message translates to:
  /// **'Fin por puntos'**
  String get endPoints;

  /// No description provided for @endTime.
  ///
  /// In es, this message translates to:
  /// **'Fin del tiempo'**
  String get endTime;

  /// No description provided for @endDisqualification.
  ///
  /// In es, this message translates to:
  /// **'Fin por descalificación'**
  String get endDisqualification;

  /// No description provided for @actionRefused.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido registrar. {detail}'**
  String actionRefused(String detail);

  /// No description provided for @tlStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio del tiempo'**
  String get tlStart;

  /// No description provided for @tlStop.
  ///
  /// In es, this message translates to:
  /// **'Parada'**
  String get tlStop;

  /// No description provided for @tlPoint.
  ///
  /// In es, this message translates to:
  /// **'Punto'**
  String get tlPoint;

  /// No description provided for @tlUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get tlUndo;

  /// No description provided for @tlFinish.
  ///
  /// In es, this message translates to:
  /// **'Fin del combate'**
  String get tlFinish;

  /// No description provided for @tlAutomatic.
  ///
  /// In es, this message translates to:
  /// **'automático'**
  String get tlAutomatic;

  /// No description provided for @tlUndone.
  ///
  /// In es, this message translates to:
  /// **'deshecho'**
  String get tlUndone;

  /// No description provided for @tlRivalPoint.
  ///
  /// In es, this message translates to:
  /// **'punto al rival'**
  String get tlRivalPoint;

  /// No description provided for @clubStandings.
  ///
  /// In es, this message translates to:
  /// **'Puntuaciones'**
  String get clubStandings;

  /// No description provided for @clubMats.
  ///
  /// In es, this message translates to:
  /// **'Tapices'**
  String get clubMats;

  /// No description provided for @clubParticipants.
  ///
  /// In es, this message translates to:
  /// **'Inscripciones'**
  String get clubParticipants;

  /// No description provided for @clubSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get clubSettings;

  /// No description provided for @allCategories.
  ///
  /// In es, this message translates to:
  /// **'Todas las categorías'**
  String get allCategories;

  /// No description provided for @noCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get noCategory;

  /// No description provided for @sortByPoints.
  ///
  /// In es, this message translates to:
  /// **'Puntos'**
  String get sortByPoints;

  /// No description provided for @standingsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay puntuaciones.'**
  String get standingsEmpty;

  /// No description provided for @standingsTotal.
  ///
  /// In es, this message translates to:
  /// **'{total} pts'**
  String standingsTotal(int total);

  /// No description provided for @standingsDetail.
  ///
  /// In es, this message translates to:
  /// **'Asistencia {attendance} · Combates {points} ({matches})'**
  String standingsDetail(int attendance, int points, int matches);

  /// No description provided for @matsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay tapices.'**
  String get matsEmpty;

  /// No description provided for @matSummary.
  ///
  /// In es, this message translates to:
  /// **'{groups} grupos · {pending} combates pendientes'**
  String matSummary(int groups, int pending);

  /// No description provided for @matNoReferee.
  ///
  /// In es, this message translates to:
  /// **'Sin árbitro'**
  String get matNoReferee;

  /// No description provided for @matEstimatedEnd.
  ///
  /// In es, this message translates to:
  /// **'Fin estimado {time}'**
  String matEstimatedEnd(String time);

  /// No description provided for @matFighting.
  ///
  /// In es, this message translates to:
  /// **'Combate en curso'**
  String get matFighting;

  /// No description provided for @matIdle.
  ///
  /// In es, this message translates to:
  /// **'Parado'**
  String get matIdle;

  /// No description provided for @participantAdd.
  ///
  /// In es, this message translates to:
  /// **'Inscribir alumno'**
  String get participantAdd;

  /// No description provided for @participantEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar alumno'**
  String get participantEdit;

  /// No description provided for @firstName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In es, this message translates to:
  /// **'Apellidos'**
  String get lastName;

  /// No description provided for @birthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get birthDate;

  /// No description provided for @heightOptional.
  ///
  /// In es, this message translates to:
  /// **'Estatura en cm (opcional)'**
  String get heightOptional;

  /// No description provided for @heightInvalid.
  ///
  /// In es, this message translates to:
  /// **'Entre 50 y 250 cm'**
  String get heightInvalid;

  /// No description provided for @guardianConsent.
  ///
  /// In es, this message translates to:
  /// **'El tutor legal está de acuerdo'**
  String get guardianConsent;

  /// No description provided for @guardianConsentRequired.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio para menores de 18 años.'**
  String get guardianConsentRequired;

  /// No description provided for @participantAgeCategory.
  ///
  /// In es, this message translates to:
  /// **'{age} años · {category}'**
  String participantAgeCategory(int age, String category);

  /// No description provided for @deleteParticipantTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar a {name}?'**
  String deleteParticipantTitle(String name);

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get delete;

  /// No description provided for @saved.
  ///
  /// In es, this message translates to:
  /// **'Guardado'**
  String get saved;

  /// No description provided for @saveConflict.
  ///
  /// In es, this message translates to:
  /// **'No se puede: ya hay grupos que dependen de esto.'**
  String get saveConflict;

  /// No description provided for @saveInvalid.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos.'**
  String get saveInvalid;

  /// No description provided for @saveError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar.'**
  String get saveError;

  /// No description provided for @settingsName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del evento'**
  String get settingsName;

  /// No description provided for @settingsDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get settingsDate;

  /// No description provided for @settingsMaxGroups.
  ///
  /// In es, this message translates to:
  /// **'Grupos por tapiz a la vez'**
  String get settingsMaxGroups;

  /// No description provided for @settingsMaxGroupsHint.
  ///
  /// In es, this message translates to:
  /// **'1 = sin multigrupo'**
  String get settingsMaxGroupsHint;

  /// No description provided for @settingsAddMat.
  ///
  /// In es, this message translates to:
  /// **'Añadir tapiz'**
  String get settingsAddMat;

  /// No description provided for @settingsRemoveMat.
  ///
  /// In es, this message translates to:
  /// **'Quitar el último tapiz'**
  String get settingsRemoveMat;

  /// No description provided for @settingsReferee.
  ///
  /// In es, this message translates to:
  /// **'Árbitro'**
  String get settingsReferee;

  /// No description provided for @categoryRange.
  ///
  /// In es, this message translates to:
  /// **'{name} · de {min} a {max} años'**
  String categoryRange(String name, int min, int max);

  /// No description provided for @exportCsv.
  ///
  /// In es, this message translates to:
  /// **'Exportar CSV'**
  String get exportCsv;

  /// No description provided for @exportStandings.
  ///
  /// In es, this message translates to:
  /// **'Clasificación'**
  String get exportStandings;

  /// No description provided for @exportMatches.
  ///
  /// In es, this message translates to:
  /// **'Combates'**
  String get exportMatches;

  /// No description provided for @exportTimeline.
  ///
  /// In es, this message translates to:
  /// **'Línea de tiempo'**
  String get exportTimeline;

  /// No description provided for @exportError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido exportar.'**
  String get exportError;

  /// No description provided for @matchLive.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get matchLive;

  /// No description provided for @matchNotStarted.
  ///
  /// In es, this message translates to:
  /// **'Sin empezar'**
  String get matchNotStarted;

  /// No description provided for @teamName.
  ///
  /// In es, this message translates to:
  /// **'Equipo {number}'**
  String teamName(int number);

  /// No description provided for @teamGhostName.
  ///
  /// In es, this message translates to:
  /// **'Equipo {number} (fantasma)'**
  String teamGhostName(int number);

  /// No description provided for @tabParticipants.
  ///
  /// In es, this message translates to:
  /// **'Alumnos'**
  String get tabParticipants;

  /// No description provided for @tabTeams.
  ///
  /// In es, this message translates to:
  /// **'Equipos'**
  String get tabTeams;

  /// No description provided for @individualGroup.
  ///
  /// In es, this message translates to:
  /// **'Grupo individual'**
  String get individualGroup;

  /// No description provided for @individualGroupHint.
  ///
  /// In es, this message translates to:
  /// **'Para quien se quede sin equipo: grupos de 4 alumnos.'**
  String get individualGroupHint;

  /// No description provided for @categoryTeamCounts.
  ///
  /// In es, this message translates to:
  /// **'{participants} inscritos · {inTeams} en {teams} equipos · {grouped} en grupos'**
  String categoryTeamCounts(
    int participants,
    int inTeams,
    int teams,
    int grouped,
  );

  /// No description provided for @newTeamCount.
  ///
  /// In es, this message translates to:
  /// **'Equipo nuevo · {count}/{size}'**
  String newTeamCount(int count, int size);

  /// No description provided for @createTeam.
  ///
  /// In es, this message translates to:
  /// **'Crear equipo'**
  String get createTeam;

  /// No description provided for @teamCreated.
  ///
  /// In es, this message translates to:
  /// **'Creado el {team}'**
  String teamCreated(String team);

  /// No description provided for @teamConflict.
  ///
  /// In es, this message translates to:
  /// **'Algún alumno ya está en un equipo o grupo. La lista se ha actualizado.'**
  String get teamConflict;

  /// No description provided for @teamError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido crear el equipo.'**
  String get teamError;

  /// No description provided for @teamsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay equipos: créalos en Alumnos.'**
  String get teamsEmpty;

  /// No description provided for @deleteTeam.
  ///
  /// In es, this message translates to:
  /// **'Deshacer equipo'**
  String get deleteTeam;

  /// No description provided for @deleteTeamConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Deshacer el {team}? Sus alumnos quedan libres.'**
  String deleteTeamConfirm(String team);

  /// No description provided for @deleteTeamError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido deshacer el equipo.'**
  String get deleteTeamError;

  /// No description provided for @draftGhostTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo fantasma'**
  String get draftGhostTeam;

  /// No description provided for @draftGhostTeamHint.
  ///
  /// In es, this message translates to:
  /// **'Elige {size} alumnos cualesquiera de la categoría: combaten pero no puntúan.'**
  String draftGhostTeamHint(int size);

  /// No description provided for @pickGhostTeam.
  ///
  /// In es, this message translates to:
  /// **'Elegir alumnos · {count}/{size}'**
  String pickGhostTeam(int count, int size);
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
