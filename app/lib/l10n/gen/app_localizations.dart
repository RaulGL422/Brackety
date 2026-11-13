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

  /// No description provided for @matReservedElsewhere.
  ///
  /// In es, this message translates to:
  /// **'Alguien de este combate lo espera ahora el tapiz {mat}'**
  String matReservedElsewhere(int mat);

  /// No description provided for @matAfterIndividual.
  ///
  /// In es, this message translates to:
  /// **'Después de tu grupo individual'**
  String get matAfterIndividual;

  /// No description provided for @matPlannedAt.
  ///
  /// In es, this message translates to:
  /// **'Previsto hacia las {time}'**
  String matPlannedAt(String time);

  /// No description provided for @controlMenu.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get controlMenu;

  /// No description provided for @controlDone.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get controlDone;

  /// No description provided for @controlError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo hacer el cambio. Recarga y vuelve a intentarlo.'**
  String get controlError;

  /// No description provided for @controlMatchInProgress.
  ///
  /// In es, this message translates to:
  /// **'Hay un combate de este grupo en curso: espera a que acabe.'**
  String get controlMatchInProgress;

  /// No description provided for @controlMatchNotPending.
  ///
  /// In es, this message translates to:
  /// **'Ese combate ya ha empezado: no se puede cambiar.'**
  String get controlMatchNotPending;

  /// No description provided for @controlMatWithoutReferee.
  ///
  /// In es, this message translates to:
  /// **'Ese tapiz no tiene árbitro.'**
  String get controlMatWithoutReferee;

  /// No description provided for @controlOrderChanged.
  ///
  /// In es, this message translates to:
  /// **'Los combates han cambiado mientras tanto: recarga y vuelve a ordenarlos.'**
  String get controlOrderChanged;

  /// No description provided for @controlTeamSize.
  ///
  /// In es, this message translates to:
  /// **'Los equipos tienen que quedar de 2 o 3.'**
  String get controlTeamSize;

  /// No description provided for @controlGroupStarted.
  ///
  /// In es, this message translates to:
  /// **'El grupo de esos equipos ya ha empezado: sus equipos ya no cambian.'**
  String get controlGroupStarted;

  /// No description provided for @controlSameFighter.
  ///
  /// In es, this message translates to:
  /// **'Esa persona ya lucha en el grupo del otro equipo (como comodín).'**
  String get controlSameFighter;

  /// No description provided for @controlPickMat.
  ///
  /// In es, this message translates to:
  /// **'¿A qué tapiz?'**
  String get controlPickMat;

  /// No description provided for @controlNoOtherMat.
  ///
  /// In es, this message translates to:
  /// **'No hay otro tapiz con árbitro.'**
  String get controlNoOtherMat;

  /// No description provided for @controlMatOption.
  ///
  /// In es, this message translates to:
  /// **'Tapiz {number} · {referee} · {pending, plural, =0{sin combates pendientes} =1{1 pendiente} other{{pending} pendientes}}'**
  String controlMatOption(int number, String referee, int pending);

  /// No description provided for @controlMoveMatch.
  ///
  /// In es, this message translates to:
  /// **'Mover este combate a otro tapiz'**
  String get controlMoveMatch;

  /// No description provided for @controlWaiveRest.
  ///
  /// In es, this message translates to:
  /// **'Dejar empezar sin esperar el descanso'**
  String get controlWaiveRest;

  /// No description provided for @controlWaiveRestTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Empezar sin el descanso mínimo?'**
  String get controlWaiveRestTitle;

  /// No description provided for @controlWaiveRestBody.
  ///
  /// In es, this message translates to:
  /// **'{red} contra {blue} podrá empezar aunque alguien no haya descansado. Queda registrado quién lo permitió.'**
  String controlWaiveRestBody(String red, String blue);

  /// No description provided for @controlConfirm.
  ///
  /// In es, this message translates to:
  /// **'Sí, permitir'**
  String get controlConfirm;

  /// No description provided for @controlMoveGroup.
  ///
  /// In es, this message translates to:
  /// **'Mover el grupo a otro tapiz'**
  String get controlMoveGroup;

  /// No description provided for @controlReorder.
  ///
  /// In es, this message translates to:
  /// **'Cambiar el orden de los combates'**
  String get controlReorder;

  /// No description provided for @controlReorderHint.
  ///
  /// In es, this message translates to:
  /// **'Arrastra para ordenar los combates pendientes. Los jugados no cambian.'**
  String get controlReorderHint;

  /// No description provided for @controlMoveMember.
  ///
  /// In es, this message translates to:
  /// **'Mover un alumno a otro equipo'**
  String get controlMoveMember;

  /// No description provided for @controlMoveMemberWho.
  ///
  /// In es, this message translates to:
  /// **'¿Quién se cambia?'**
  String get controlMoveMemberWho;

  /// No description provided for @controlMoveMemberTo.
  ///
  /// In es, this message translates to:
  /// **'¿A qué equipo?'**
  String get controlMoveMemberTo;

  /// No description provided for @settingsMatNeedsReferee.
  ///
  /// In es, this message translates to:
  /// **'Ese tapiz tiene combates por jugar: no puede quedarse sin árbitro. Pon otro árbitro o espera a que acaben.'**
  String get settingsMatNeedsReferee;

  /// No description provided for @refusalResting.
  ///
  /// In es, this message translates to:
  /// **'Todavía no: alguien de este combate no ha cumplido el descanso mínimo desde su último combate. Espera a que se desbloquee en el tablero.'**
  String get refusalResting;

  /// No description provided for @cornerFightingNow.
  ///
  /// In es, this message translates to:
  /// **'Luchando en el tapiz {mat}'**
  String cornerFightingNow(int mat);

  /// No description provided for @cornerFighting.
  ///
  /// In es, this message translates to:
  /// **'Luchando en el tapiz {mat} · libre hacia las {time}'**
  String cornerFighting(int mat, String time);

  /// No description provided for @cornerResting.
  ///
  /// In es, this message translates to:
  /// **'Descansando hasta las {time}'**
  String cornerResting(String time);

  /// No description provided for @cornerPending.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Le queda otro combate} other{Le quedan {count} combates}} en tapiz {mats}'**
  String cornerPending(int count, String mats);

  /// No description provided for @rulebookTitle.
  ///
  /// In es, this message translates to:
  /// **'Reglamento de la fase'**
  String get rulebookTitle;

  /// No description provided for @rulebookHint.
  ///
  /// In es, this message translates to:
  /// **'El PDF con el reglamento completo. Los árbitros lo abren desde la pantalla de su tapiz, también en el portátil del pabellón (va dentro del paquete del evento).'**
  String get rulebookHint;

  /// No description provided for @rulebookNone.
  ///
  /// In es, this message translates to:
  /// **'Sin reglamento'**
  String get rulebookNone;

  /// No description provided for @rulebookUpload.
  ///
  /// In es, this message translates to:
  /// **'Subir PDF'**
  String get rulebookUpload;

  /// No description provided for @rulebookReplace.
  ///
  /// In es, this message translates to:
  /// **'Cambiar PDF'**
  String get rulebookReplace;

  /// No description provided for @rulebookOpen.
  ///
  /// In es, this message translates to:
  /// **'Ver reglamento'**
  String get rulebookOpen;

  /// No description provided for @rulebookRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get rulebookRemove;

  /// No description provided for @rulebookUploaded.
  ///
  /// In es, this message translates to:
  /// **'Reglamento subido'**
  String get rulebookUploaded;

  /// No description provided for @rulebookUploadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo subir: tiene que ser un PDF de hasta 10 MB.'**
  String get rulebookUploadError;

  /// No description provided for @rulebookRemoveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo quitar el reglamento.'**
  String get rulebookRemoveError;

  /// No description provided for @rulebookOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el reglamento. Comprueba la conexión.'**
  String get rulebookOpenError;

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
  /// **'Acepto los {terms} y la {privacy}.'**
  String registerAccept(String terms, String privacy);

  /// No description provided for @registerAcceptRequired.
  ///
  /// In es, this message translates to:
  /// **'Debes aceptarlos para crear la cuenta.'**
  String get registerAcceptRequired;

  /// No description provided for @registerOrganizationName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la organización'**
  String get registerOrganizationName;

  /// No description provided for @registerOrganizationNameLength.
  ///
  /// In es, this message translates to:
  /// **'Entre 2 y 200 caracteres.'**
  String get registerOrganizationNameLength;

  /// No description provided for @registerTaxId.
  ///
  /// In es, this message translates to:
  /// **'CIF'**
  String get registerTaxId;

  /// No description provided for @registerTaxIdHelper.
  ///
  /// In es, this message translates to:
  /// **'La plataforma lo usa para verificar la organización antes de que pueda publicar eventos.'**
  String get registerTaxIdHelper;

  /// No description provided for @registerTaxIdInvalid.
  ///
  /// In es, this message translates to:
  /// **'CIF no válido.'**
  String get registerTaxIdInvalid;

  /// No description provided for @registerRepresentative.
  ///
  /// In es, this message translates to:
  /// **'Soy mayor de edad y represento a esta organización.'**
  String get registerRepresentative;

  /// No description provided for @registerRepresentativeRequired.
  ///
  /// In es, this message translates to:
  /// **'Debes confirmarlo para registrar la organización.'**
  String get registerRepresentativeRequired;

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
  /// **'Grupo {group} · {mat}'**
  String participantGrouped(int group, String mat);

  /// No description provided for @draftGroup.
  ///
  /// In es, this message translates to:
  /// **'Grupo {number}'**
  String draftGroup(int number);

  /// No description provided for @draftGhost.
  ///
  /// In es, this message translates to:
  /// **'Comodín'**
  String get draftGhost;

  /// No description provided for @draftGhostHint.
  ///
  /// In es, this message translates to:
  /// **'Comodines (hasta 3): quien ya tiene grupo, o el 4.º que elijas. Combaten pero no puntúan.'**
  String get draftGhostHint;

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

  /// No description provided for @groupsConflict.
  ///
  /// In es, this message translates to:
  /// **'Algún alumno ya está en un grupo o el tapiz se ha quedado sin árbitro. La lista se ha actualizado.'**
  String get groupsConflict;

  /// No description provided for @groupsError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido crear el grupo.'**
  String get groupsError;

  /// No description provided for @ok.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get ok;

  /// No description provided for @ghostBadge.
  ///
  /// In es, this message translates to:
  /// **'Comodín'**
  String get ghostBadge;

  /// No description provided for @matTitle.
  ///
  /// In es, this message translates to:
  /// **'Tapiz {number}'**
  String matTitle(int number);

  /// No description provided for @matPool.
  ///
  /// In es, this message translates to:
  /// **'Tapices libres'**
  String get matPool;

  /// No description provided for @queuedOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: {what} se enviará al volver la red. Mientras, sus alumnos salen como pendientes.'**
  String queuedOffline(String what);

  /// No description provided for @queuedSent.
  ///
  /// In es, this message translates to:
  /// **'Enviado: {what}'**
  String queuedSent(String what);

  /// No description provided for @queuedRefused.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear {what}: alguien ya estaba en otro grupo o equipo. Revisa la lista.'**
  String queuedRefused(String what);

  /// No description provided for @queuedPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de enviar (sin conexión)'**
  String get queuedPending;

  /// No description provided for @queuedGroupLabel.
  ///
  /// In es, this message translates to:
  /// **'el grupo de {names}'**
  String queuedGroupLabel(String names);

  /// No description provided for @queuedTeamLabel.
  ///
  /// In es, this message translates to:
  /// **'el equipo de {names}'**
  String queuedTeamLabel(String names);

  /// No description provided for @matEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay grupos en este tapiz.'**
  String get matEmpty;

  /// No description provided for @matGroupHeader.
  ///
  /// In es, this message translates to:
  /// **'Grupo {number}, de {category} años'**
  String matGroupHeader(int number, String category);

  /// No description provided for @matRecommended.
  ///
  /// In es, this message translates to:
  /// **'Combate recomendado'**
  String get matRecommended;

  /// No description provided for @matInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get matInProgress;

  /// No description provided for @matPending.
  ///
  /// In es, this message translates to:
  /// **'Otros combates disponibles'**
  String get matPending;

  /// No description provided for @matYours.
  ///
  /// In es, this message translates to:
  /// **'Tu tapiz'**
  String get matYours;

  /// No description provided for @matToPlay.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 por disputar} other{{count} por disputar}}'**
  String matToPlay(int count);

  /// No description provided for @matOpenScoreboard.
  ///
  /// In es, this message translates to:
  /// **'Abrir el marcador'**
  String get matOpenScoreboard;

  /// No description provided for @matBackToScoreboard.
  ///
  /// In es, this message translates to:
  /// **'Volver al marcador'**
  String get matBackToScoreboard;

  /// No description provided for @matWatch.
  ///
  /// In es, this message translates to:
  /// **'Ver el combate'**
  String get matWatch;

  /// No description provided for @matGroups.
  ///
  /// In es, this message translates to:
  /// **'Grupos en este tapiz'**
  String get matGroups;

  /// No description provided for @matFinished.
  ///
  /// In es, this message translates to:
  /// **'Disputados'**
  String get matFinished;

  /// No description provided for @matWaiting.
  ///
  /// In es, this message translates to:
  /// **'Un luchador está combatiendo ahora'**
  String get matWaiting;

  /// No description provided for @matResting.
  ///
  /// In es, this message translates to:
  /// **'Descansando hasta las {time}'**
  String matResting(String time);

  /// No description provided for @matProposedElsewhere.
  ///
  /// In es, this message translates to:
  /// **'Propuesto en el tapiz {number}'**
  String matProposedElsewhere(int number);

  /// No description provided for @matPoolOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: otro tapiz puede estar haciéndolo'**
  String get matPoolOffline;

  /// No description provided for @matTeamPoolNotice.
  ///
  /// In es, this message translates to:
  /// **'Sin grupos individuales pendientes: este tapiz coge los combates de equipos del bote común, repartidos entre los tapices libres. Primero los que más han descansado.'**
  String get matTeamPoolNotice;

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
  /// **'{mat}, grupo {group}'**
  String scoreboardTitle(String mat, int group);

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

  /// No description provided for @addPointFor.
  ///
  /// In es, this message translates to:
  /// **'+1 {corner}'**
  String addPointFor(String corner);

  /// No description provided for @sanctionsFor.
  ///
  /// In es, this message translates to:
  /// **'Avisos: {corner}'**
  String sanctionsFor(String corner);

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
  /// **'{action}: {fighter}'**
  String reasonTitle(String action, String fighter);

  /// No description provided for @reasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get reasonLabel;

  /// No description provided for @reasonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Escribe el motivo. Queda en el historial del combate.'**
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

  /// No description provided for @removePoint.
  ///
  /// In es, this message translates to:
  /// **'−1'**
  String get removePoint;

  /// No description provided for @removePointFor.
  ///
  /// In es, this message translates to:
  /// **'Quitar un punto a {corner}'**
  String removePointFor(String corner);

  /// No description provided for @whatPointRemoved.
  ///
  /// In es, this message translates to:
  /// **'−1 {corner}'**
  String whatPointRemoved(String corner);

  /// No description provided for @whatClockAdjust.
  ///
  /// In es, this message translates to:
  /// **'{delta} s al reloj'**
  String whatClockAdjust(String delta);

  /// No description provided for @clockAdjustBy.
  ///
  /// In es, this message translates to:
  /// **'{delta} s'**
  String clockAdjustBy(String delta);

  /// No description provided for @clockAdjustTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ajustar el reloj {delta} s'**
  String clockAdjustTooltip(String delta);

  /// No description provided for @clockAdjustHint.
  ///
  /// In es, this message translates to:
  /// **'Ajustar el reloj (parado)'**
  String get clockAdjustHint;

  /// No description provided for @tlPointRemoved.
  ///
  /// In es, this message translates to:
  /// **'Punto quitado'**
  String get tlPointRemoved;

  /// No description provided for @tlClockAdjust.
  ///
  /// In es, this message translates to:
  /// **'Ajuste del reloj'**
  String get tlClockAdjust;

  /// No description provided for @tlNextUndo.
  ///
  /// In es, this message translates to:
  /// **'lo siguiente que deshace Deshacer'**
  String get tlNextUndo;

  /// No description provided for @undoDetail.
  ///
  /// In es, this message translates to:
  /// **'{what} · {clock}'**
  String undoDetail(String what, String clock);

  /// No description provided for @recentActions.
  ///
  /// In es, this message translates to:
  /// **'Últimas acciones'**
  String get recentActions;

  /// No description provided for @refusalNoPoints.
  ///
  /// In es, this message translates to:
  /// **'No tiene puntos que quitar.'**
  String get refusalNoPoints;

  /// No description provided for @refusalClockRunning.
  ///
  /// In es, this message translates to:
  /// **'Para el reloj antes de ajustarlo.'**
  String get refusalClockRunning;

  /// No description provided for @refusalClockLimit.
  ///
  /// In es, this message translates to:
  /// **'El reloj no puede ir más allá.'**
  String get refusalClockLimit;

  /// No description provided for @settingsMatchRules.
  ///
  /// In es, this message translates to:
  /// **'Combates'**
  String get settingsMatchRules;

  /// No description provided for @settingsMatchLength.
  ///
  /// In es, this message translates to:
  /// **'Individual: duración del combate (min:s)'**
  String get settingsMatchLength;

  /// No description provided for @settingsTeamMatchLength.
  ///
  /// In es, this message translates to:
  /// **'Equipos: duración del combate (min:s)'**
  String get settingsTeamMatchLength;

  /// No description provided for @settingsTeamPointsLimit.
  ///
  /// In es, this message translates to:
  /// **'Equipos: puntos para acabar el combate'**
  String get settingsTeamPointsLimit;

  /// No description provided for @settingsTeamPointsLimitHint.
  ///
  /// In es, this message translates to:
  /// **'Vacío = sin límite: acaba por tiempo. Descalificar da al rival 15 puntos, o los suyos si lleva más.'**
  String get settingsTeamPointsLimitHint;

  /// No description provided for @settingsMinRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso mínimo entre combates (segundos)'**
  String get settingsMinRest;

  /// No description provided for @settingsMinRestHint.
  ///
  /// In es, this message translates to:
  /// **'Nadie empieza un combate sin este descanso desde el anterior, en cualquier tapiz. Hasta entonces el combate sale en espera.'**
  String get settingsMinRestHint;

  /// No description provided for @settingsMinRestInvalid.
  ///
  /// In es, this message translates to:
  /// **'Entre 0 y 600 segundos.'**
  String get settingsMinRestInvalid;

  /// No description provided for @settingsMatchLengthHint.
  ///
  /// In es, this message translates to:
  /// **'De 0:30 a 20:00. No cambia con un combate en curso.'**
  String get settingsMatchLengthHint;

  /// No description provided for @settingsMatchLengthInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe minutos y segundos entre 0:30 y 20:00, por ejemplo 3:00.'**
  String get settingsMatchLengthInvalid;

  /// No description provided for @settingsPointsLimit.
  ///
  /// In es, this message translates to:
  /// **'Individual: puntos para acabar el combate'**
  String get settingsPointsLimit;

  /// No description provided for @settingsPointsLimitHint.
  ///
  /// In es, this message translates to:
  /// **'Al llegar uno, acaba. La descalificación da estos puntos al rival. No cambia una vez empezado un combate.'**
  String get settingsPointsLimitHint;

  /// No description provided for @settingsMatchRulesConflict.
  ///
  /// In es, this message translates to:
  /// **'No se puede cambiar ahora: hay un combate en curso o ya empezado.'**
  String get settingsMatchRulesConflict;

  /// No description provided for @settingsPointsLimitInvalid.
  ///
  /// In es, this message translates to:
  /// **'Entre 1 y 99.'**
  String get settingsPointsLimitInvalid;

  /// No description provided for @matWaitingTitle.
  ///
  /// In es, this message translates to:
  /// **'En espera'**
  String get matWaitingTitle;

  /// No description provided for @matStartRecommended.
  ///
  /// In es, this message translates to:
  /// **'Empezar este combate'**
  String get matStartRecommended;

  /// No description provided for @matRecommendedWhy.
  ///
  /// In es, this message translates to:
  /// **'Sus luchadores son los que más han descansado y ninguno acaba de combatir.'**
  String get matRecommendedWhy;

  /// No description provided for @matAfterCurrent.
  ///
  /// In es, this message translates to:
  /// **'Cuando acabe el combate en curso.'**
  String get matAfterCurrent;

  /// No description provided for @undoGroup.
  ///
  /// In es, this message translates to:
  /// **'Deshacer grupo'**
  String get undoGroup;

  /// No description provided for @undoGroupNumber.
  ///
  /// In es, this message translates to:
  /// **'Deshacer el Grupo {number}'**
  String undoGroupNumber(int number);

  /// No description provided for @undoGroupConfirm.
  ///
  /// In es, this message translates to:
  /// **'Se deshace el Grupo {number} y sus combates. Sus alumnos vuelven a la lista para agruparlos de nuevo.'**
  String undoGroupConfirm(int number);

  /// No description provided for @undoGroupDone.
  ///
  /// In es, this message translates to:
  /// **'Grupo {number} deshecho'**
  String undoGroupDone(int number);

  /// No description provided for @undoGroupStarted.
  ///
  /// In es, this message translates to:
  /// **'Ya ha empezado un combate de este grupo: solo el administrador puede deshacerlo.'**
  String get undoGroupStarted;

  /// No description provided for @undoGroupError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido deshacer el grupo.'**
  String get undoGroupError;

  /// No description provided for @clubStandings.
  ///
  /// In es, this message translates to:
  /// **'Puntos'**
  String get clubStandings;

  /// No description provided for @clubMats.
  ///
  /// In es, this message translates to:
  /// **'Tapices'**
  String get clubMats;

  /// No description provided for @clubParticipants.
  ///
  /// In es, this message translates to:
  /// **'Inscritos'**
  String get clubParticipants;

  /// No description provided for @clubSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
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
  /// **'{groups, plural, =1{1 grupo} other{{groups} grupos}} · {pending, plural, =1{1 combate pendiente} other{{pending} combates pendientes}}'**
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

  /// No description provided for @exportMenu.
  ///
  /// In es, this message translates to:
  /// **'Exportar'**
  String get exportMenu;

  /// No description provided for @exportStandings.
  ///
  /// In es, this message translates to:
  /// **'Clasificación (CSV)'**
  String get exportStandings;

  /// No description provided for @exportMatches.
  ///
  /// In es, this message translates to:
  /// **'Combates (CSV)'**
  String get exportMatches;

  /// No description provided for @exportTimeline.
  ///
  /// In es, this message translates to:
  /// **'Línea de tiempo (CSV)'**
  String get exportTimeline;

  /// No description provided for @organizationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Clubes participantes'**
  String get organizationsTitle;

  /// No description provided for @organizationsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay clubes. Añádelos para indicar el de cada inscrito.'**
  String get organizationsEmpty;

  /// No description provided for @organizationAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir club'**
  String get organizationAdd;

  /// No description provided for @organizationEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar club'**
  String get organizationEdit;

  /// No description provided for @organizationRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar club'**
  String get organizationRemove;

  /// No description provided for @organizationName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del club'**
  String get organizationName;

  /// No description provided for @organizationShortName.
  ///
  /// In es, this message translates to:
  /// **'Abreviatura (opcional)'**
  String get organizationShortName;

  /// No description provided for @organizationLabel.
  ///
  /// In es, this message translates to:
  /// **'Club'**
  String get organizationLabel;

  /// No description provided for @organizationNone.
  ///
  /// In es, this message translates to:
  /// **'Sin club'**
  String get organizationNone;

  /// No description provided for @organizationsConflict.
  ///
  /// In es, this message translates to:
  /// **'No se puede: ese club tiene inscritos o ya hay otro con el mismo nombre.'**
  String get organizationsConflict;

  /// No description provided for @exportParticipants.
  ///
  /// In es, this message translates to:
  /// **'Inscritos (CSV)'**
  String get exportParticipants;

  /// No description provided for @exportFull.
  ///
  /// In es, this message translates to:
  /// **'Todo el evento (.zip)'**
  String get exportFull;

  /// No description provided for @importResults.
  ///
  /// In es, this message translates to:
  /// **'Importar resultados del pabellón'**
  String get importResults;

  /// No description provided for @importResultsTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Importar estos resultados?'**
  String get importResultsTitle;

  /// No description provided for @importResultsBody.
  ///
  /// In es, this message translates to:
  /// **'Se añadirán {groups} grupos, {matches} combates y {actions} acciones del marcador, y {participants} inscritos que aquí no estaban. No se puede deshacer.'**
  String importResultsBody(
    int groups,
    int matches,
    int actions,
    int participants,
  );

  /// No description provided for @importResultsConfirm.
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get importResultsConfirm;

  /// No description provided for @importResultsDone.
  ///
  /// In es, this message translates to:
  /// **'Resultados importados.'**
  String get importResultsDone;

  /// No description provided for @importResultsAlready.
  ///
  /// In es, this message translates to:
  /// **'Estos resultados ya estaban importados: no cambia nada.'**
  String get importResultsAlready;

  /// No description provided for @importResultsOtherEvent.
  ///
  /// In es, this message translates to:
  /// **'El fichero es de otro evento (otro nombre o fecha).'**
  String get importResultsOtherEvent;

  /// No description provided for @importResultsConflict.
  ///
  /// In es, this message translates to:
  /// **'Este evento ya tiene grupos propios: los resultados solo se importan en un evento sin competición.'**
  String get importResultsConflict;

  /// No description provided for @importResultsInvalid.
  ///
  /// In es, this message translates to:
  /// **'El fichero no es una exportación de Brackety (.zip o .brackety) con resultados.'**
  String get importResultsInvalid;

  /// No description provided for @importResultsError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido importar los resultados.'**
  String get importResultsError;

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
  /// **'Equipo {number} (comodín)'**
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

  /// No description provided for @teamGroup.
  ///
  /// In es, this message translates to:
  /// **'Grupo por equipos'**
  String get teamGroup;

  /// No description provided for @matPickerLabel.
  ///
  /// In es, this message translates to:
  /// **'Tapiz'**
  String get matPickerLabel;

  /// No description provided for @matAuto.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get matAuto;

  /// No description provided for @matAutoOption.
  ///
  /// In es, this message translates to:
  /// **'El que antes quede libre'**
  String get matAutoOption;

  /// No description provided for @matAutoHint.
  ///
  /// In es, this message translates to:
  /// **'Se asignará automáticamente al tapiz que antes quede libre.'**
  String get matAutoHint;

  /// No description provided for @matManualHint.
  ///
  /// In es, this message translates to:
  /// **'Irá al {mat}, elegido a mano.'**
  String matManualHint(String mat);

  /// No description provided for @individualGroupHint.
  ///
  /// In es, this message translates to:
  /// **'Para quien se quede sin equipo: grupos de 4 alumnos.'**
  String get individualGroupHint;

  /// No description provided for @categoryTeamCounts.
  ///
  /// In es, this message translates to:
  /// **'{participants} inscritos · {teams} equipos · {grouped} en grupos'**
  String categoryTeamCounts(int participants, int teams, int grouped);

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
  /// **'Equipo comodín'**
  String get draftGhostTeam;

  /// No description provided for @draftGhostTeamHint.
  ///
  /// In es, this message translates to:
  /// **'Equipos comodín (hasta 3): de 2 o hasta {size} alumnos cualesquiera de la categoría que no estén ya en el grupo. Combaten pero no puntúan.'**
  String draftGhostTeamHint(int size);

  /// No description provided for @addGhostTeam.
  ///
  /// In es, this message translates to:
  /// **'Añadir equipo comodín'**
  String get addGhostTeam;

  /// No description provided for @teamGroupPoolHint.
  ///
  /// In es, this message translates to:
  /// **'Sin tapiz: sus combates se reparten entre los tapices sin grupos individuales.'**
  String get teamGroupPoolHint;

  /// No description provided for @pickGhostTeam.
  ///
  /// In es, this message translates to:
  /// **'Elegir alumnos · {count}/{size}'**
  String pickGhostTeam(int count, int size);

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes de la cuenta'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get settingsAccount;

  /// No description provided for @settingsEmailVerified.
  ///
  /// In es, this message translates to:
  /// **'Verificado'**
  String get settingsEmailVerified;

  /// No description provided for @settingsEmailUnverified.
  ///
  /// In es, this message translates to:
  /// **'Sin verificar'**
  String get settingsEmailUnverified;

  /// No description provided for @settingsChangeEmail.
  ///
  /// In es, this message translates to:
  /// **'Cambiar email'**
  String get settingsChangeEmail;

  /// No description provided for @changeEmailNew.
  ///
  /// In es, this message translates to:
  /// **'Email nuevo'**
  String get changeEmailNew;

  /// No description provided for @changeEmailSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get changeEmailSubmit;

  /// No description provided for @changeEmailSent.
  ///
  /// In es, this message translates to:
  /// **'Hemos enviado un email a {email}. Abre su enlace para terminar el cambio (caduca en 24 horas).'**
  String changeEmailSent(String email);

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageHint.
  ///
  /// In es, this message translates to:
  /// **'También es el de los emails que te enviamos.'**
  String get settingsLanguageHint;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsLanguageError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cambiar el idioma.'**
  String get settingsLanguageError;

  /// No description provided for @settingsProfiles.
  ///
  /// In es, this message translates to:
  /// **'Perfiles'**
  String get settingsProfiles;

  /// No description provided for @profileValidated.
  ///
  /// In es, this message translates to:
  /// **'Validado'**
  String get profileValidated;

  /// No description provided for @profilePendingValidation.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de validación'**
  String get profilePendingValidation;

  /// No description provided for @profileTaxId.
  ///
  /// In es, this message translates to:
  /// **'CIF: {taxId}'**
  String profileTaxId(String taxId);

  /// No description provided for @profileAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir perfil'**
  String get profileAdd;

  /// No description provided for @profileAdded.
  ///
  /// In es, this message translates to:
  /// **'Perfil añadido.'**
  String get profileAdded;

  /// No description provided for @profileRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar perfil'**
  String get profileRemove;

  /// No description provided for @profileRemoveConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar el perfil {profile}?'**
  String profileRemoveConfirm(String profile);

  /// No description provided for @profileRemoved.
  ///
  /// In es, this message translates to:
  /// **'Perfil quitado.'**
  String get profileRemoved;

  /// No description provided for @removeAction.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get removeAction;

  /// No description provided for @profileLast.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta necesita al menos un perfil.'**
  String get profileLast;

  /// No description provided for @profileCombination.
  ///
  /// In es, this message translates to:
  /// **'Ese perfil no se puede combinar con los que ya tienes.'**
  String get profileCombination;

  /// No description provided for @profileNeedsVerifiedEmail.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu email antes de añadir perfiles.'**
  String get profileNeedsVerifiedEmail;

  /// No description provided for @settingsSignInMethods.
  ///
  /// In es, this message translates to:
  /// **'Métodos de acceso'**
  String get settingsSignInMethods;

  /// No description provided for @signInPassword.
  ///
  /// In es, this message translates to:
  /// **'Email y contraseña'**
  String get signInPassword;

  /// No description provided for @signInGoogle.
  ///
  /// In es, this message translates to:
  /// **'Google'**
  String get signInGoogle;

  /// No description provided for @googleUnlink.
  ///
  /// In es, this message translates to:
  /// **'Desvincular'**
  String get googleUnlink;

  /// No description provided for @googleUnlinkConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Desvincular tu cuenta de Google? Solo podrás entrar con email y contraseña.'**
  String get googleUnlinkConfirm;

  /// No description provided for @googleUnlinked.
  ///
  /// In es, this message translates to:
  /// **'Google desvinculado.'**
  String get googleUnlinked;

  /// No description provided for @passwordRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar contraseña'**
  String get passwordRemove;

  /// No description provided for @passwordRemoveConfirm.
  ///
  /// In es, this message translates to:
  /// **'Solo podrás entrar con Google y se cerrarán todas tus sesiones, también esta. Para volver a tener contraseña, usa «¿Has olvidado la contraseña?».'**
  String get passwordRemoveConfirm;

  /// No description provided for @lastSignInMethod.
  ///
  /// In es, this message translates to:
  /// **'Es tu único método de acceso. Añade otro antes.'**
  String get lastSignInMethod;

  /// No description provided for @needsGoogle.
  ///
  /// In es, this message translates to:
  /// **'Esta acción pide confirmar con Google, que llegará pronto a la app.'**
  String get needsGoogle;

  /// No description provided for @settingsData.
  ///
  /// In es, this message translates to:
  /// **'Tus datos'**
  String get settingsData;

  /// No description provided for @settingsDataHint.
  ///
  /// In es, this message translates to:
  /// **'Descarga una copia de los datos de tu cuenta (JSON).'**
  String get settingsDataHint;

  /// No description provided for @settingsExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar mis datos'**
  String get settingsExport;

  /// No description provided for @settingsDanger.
  ///
  /// In es, this message translates to:
  /// **'Zona peligrosa'**
  String get settingsDanger;

  /// No description provided for @deleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Borrar cuenta'**
  String get deleteAccount;

  /// No description provided for @deleteAccountHint.
  ///
  /// In es, this message translates to:
  /// **'Se borra definitivamente a los 30 días. Hasta entonces puedes recuperarla iniciando sesión.'**
  String get deleteAccountHint;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar tu cuenta?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In es, this message translates to:
  /// **'Se cerrarán todas tus sesiones. La cuenta, con sus perfiles y datos, se borrará definitivamente a los 30 días. Hasta entonces puedes recuperarla iniciando sesión.'**
  String get deleteAccountBody;

  /// No description provided for @deleteOwnsEvents.
  ///
  /// In es, this message translates to:
  /// **'Eres responsable de eventos. Cédelos a otra persona o bórralos antes de borrar tu cuenta.'**
  String get deleteOwnsEvents;

  /// No description provided for @loginAccountDeleted.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta se borrará el {date}. Inicia sesión antes para recuperarla.'**
  String loginAccountDeleted(String date);

  /// No description provided for @loginPasswordRemoved.
  ///
  /// In es, this message translates to:
  /// **'Contraseña quitada y sesiones cerradas. Ya solo puedes entrar con Google.'**
  String get loginPasswordRemoved;

  /// No description provided for @reauthTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirma que eres tú'**
  String get reauthTitle;

  /// No description provided for @reauthBody.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña para continuar.'**
  String get reauthBody;

  /// No description provided for @reauthSubmit.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get reauthSubmit;

  /// No description provided for @reauthFailed.
  ///
  /// In es, this message translates to:
  /// **'Contraseña incorrecta.'**
  String get reauthFailed;

  /// No description provided for @settingsLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsLogout;

  /// No description provided for @confirmEmailChangeTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambio de email'**
  String get confirmEmailChangeTitle;

  /// No description provided for @confirmEmailChangeDone.
  ///
  /// In es, this message translates to:
  /// **'Email cambiado. Se han cerrado todas las sesiones: inicia sesión con el email nuevo.'**
  String get confirmEmailChangeDone;

  /// No description provided for @categoryIndividual.
  ///
  /// In es, this message translates to:
  /// **'Individual'**
  String get categoryIndividual;

  /// No description provided for @categoryTeams.
  ///
  /// In es, this message translates to:
  /// **'Equipos de 2 o 3'**
  String get categoryTeams;

  /// No description provided for @categoryAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir categoría'**
  String get categoryAdd;

  /// No description provided for @categoryEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar categoría'**
  String get categoryEdit;

  /// No description provided for @categoryRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar categoría'**
  String get categoryRemove;

  /// No description provided for @categoryNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get categoryNameLabel;

  /// No description provided for @categoryMinAge.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get categoryMinAge;

  /// No description provided for @categoryMaxAge.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get categoryMaxAge;

  /// No description provided for @categoryByTeams.
  ///
  /// In es, this message translates to:
  /// **'Por equipos'**
  String get categoryByTeams;

  /// No description provided for @categoryGroupSize.
  ///
  /// In es, this message translates to:
  /// **'Grupos de {size}'**
  String categoryGroupSize(int size);

  /// No description provided for @categoryAgesInvalid.
  ///
  /// In es, this message translates to:
  /// **'La edad mínima no puede ser mayor que la máxima.'**
  String get categoryAgesInvalid;

  /// No description provided for @categoriesInUse.
  ///
  /// In es, this message translates to:
  /// **'Una categoría con grupos o equipos solo puede cambiar de nombre.'**
  String get categoriesInUse;

  /// No description provided for @categoriesInvalid.
  ///
  /// In es, this message translates to:
  /// **'Revisa las categorías: las edades no pueden solaparse.'**
  String get categoriesInvalid;

  /// No description provided for @standingTeam.
  ///
  /// In es, this message translates to:
  /// **'{team} · {detail}'**
  String standingTeam(String team, String detail);

  /// No description provided for @categoryAgeSuffix.
  ///
  /// In es, this message translates to:
  /// **'años'**
  String get categoryAgeSuffix;

  /// No description provided for @categoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get categoryLabel;

  /// No description provided for @categoryByAge.
  ///
  /// In es, this message translates to:
  /// **'Automática por edad'**
  String get categoryByAge;

  /// No description provided for @importButton.
  ///
  /// In es, this message translates to:
  /// **'Importar alumnos'**
  String get importButton;

  /// No description provided for @importFormatTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo debe ser la lista'**
  String get importFormatTitle;

  /// No description provided for @importFormatBody.
  ///
  /// In es, this message translates to:
  /// **'Una fila por alumno: nombre, apellidos, fecha de nacimiento (dd/mm/aaaa), estatura en cm (opcional) y categoría (opcional). Vale una o varias fotos, un CSV, un Excel, un TXT o el texto pegado.'**
  String get importFormatBody;

  /// No description provided for @importTemplate.
  ///
  /// In es, this message translates to:
  /// **'Descargar plantilla'**
  String get importTemplate;

  /// No description provided for @importPickPhotos.
  ///
  /// In es, this message translates to:
  /// **'Elegir fotos'**
  String get importPickPhotos;

  /// No description provided for @importPickFile.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo'**
  String get importPickFile;

  /// No description provided for @importPasteHint.
  ///
  /// In es, this message translates to:
  /// **'O pega aquí la lista'**
  String get importPasteHint;

  /// No description provided for @importConsent.
  ///
  /// In es, this message translates to:
  /// **'Confirmo que todos los alumnos de esta lista, y sus tutores si son menores, han aceptado inscribirse en este evento sin excepción, y que la lista se procesará con un servicio de IA externo (Anthropic) solo para leerla. Las imágenes y archivos no se guardan.'**
  String get importConsent;

  /// No description provided for @importRead.
  ///
  /// In es, this message translates to:
  /// **'Leer lista'**
  String get importRead;

  /// No description provided for @importReading.
  ///
  /// In es, this message translates to:
  /// **'Leyendo la lista… puede tardar hasta un minuto.'**
  String get importReading;

  /// No description provided for @importReadError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido leer la lista. Prueba con una foto más nítida o con un archivo.'**
  String get importReadError;

  /// No description provided for @importTooMany.
  ///
  /// In es, this message translates to:
  /// **'Has leído muchas listas en la última hora. Prueba más tarde.'**
  String get importTooMany;

  /// No description provided for @importInvalidFiles.
  ///
  /// In es, this message translates to:
  /// **'Solo fotos (JPG, PNG, WebP), CSV, TXT o Excel: hasta {max} archivos de 10 MB.'**
  String importInvalidFiles(int max);

  /// No description provided for @importSummary.
  ///
  /// In es, this message translates to:
  /// **'{total} alumnos · {errors} con errores · {warnings} para revisar'**
  String importSummary(int total, int errors, int warnings);

  /// No description provided for @importRegister.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Inscribir 1 alumno} other{Inscribir {count} alumnos}}'**
  String importRegister(int count);

  /// No description provided for @importRegistered.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 alumno inscrito} other{{count} alumnos inscritos}}'**
  String importRegistered(int count);

  /// No description provided for @importRegisterRefused.
  ///
  /// In es, this message translates to:
  /// **'No se ha inscrito nadie: revisa las filas marcadas.'**
  String get importRegisterRefused;

  /// No description provided for @importAddRow.
  ///
  /// In es, this message translates to:
  /// **'Añadir alumno'**
  String get importAddRow;

  /// No description provided for @importEditRow.
  ///
  /// In es, this message translates to:
  /// **'Editar alumno'**
  String get importEditRow;

  /// No description provided for @importRemoveRow.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la lista'**
  String get importRemoveRow;

  /// No description provided for @importStartOver.
  ///
  /// In es, this message translates to:
  /// **'Volver a subir'**
  String get importStartOver;

  /// No description provided for @importEmpty.
  ///
  /// In es, this message translates to:
  /// **'La lista no tiene alumnos.'**
  String get importEmpty;

  /// No description provided for @importUseCategory.
  ///
  /// In es, this message translates to:
  /// **'Usar {name}'**
  String importUseCategory(String name);

  /// No description provided for @fieldFirstName.
  ///
  /// In es, this message translates to:
  /// **'el nombre'**
  String get fieldFirstName;

  /// No description provided for @fieldLastName.
  ///
  /// In es, this message translates to:
  /// **'los apellidos'**
  String get fieldLastName;

  /// No description provided for @fieldBirthDate.
  ///
  /// In es, this message translates to:
  /// **'la fecha de nacimiento'**
  String get fieldBirthDate;

  /// No description provided for @fieldHeight.
  ///
  /// In es, this message translates to:
  /// **'la estatura'**
  String get fieldHeight;

  /// No description provided for @fieldCategory.
  ///
  /// In es, this message translates to:
  /// **'la categoría'**
  String get fieldCategory;

  /// No description provided for @issueMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta {field}'**
  String issueMissing(String field);

  /// No description provided for @issueTooLong.
  ///
  /// In es, this message translates to:
  /// **'Demasiado largo: {field}'**
  String issueTooLong(String field);

  /// No description provided for @issueInvalidDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha no válida: {text}'**
  String issueInvalidDate(String text);

  /// No description provided for @issueFutureDate.
  ///
  /// In es, this message translates to:
  /// **'La fecha de nacimiento tiene que ser anterior a hoy'**
  String get issueFutureDate;

  /// No description provided for @issueHeight.
  ///
  /// In es, this message translates to:
  /// **'Estatura {cm}: tiene que estar entre 50 y 250 cm'**
  String issueHeight(String cm);

  /// No description provided for @issueNoCategory.
  ///
  /// In es, this message translates to:
  /// **'Ninguna categoría del evento es para {age} años'**
  String issueNoCategory(String age);

  /// No description provided for @issueUnknownCategory.
  ///
  /// In es, this message translates to:
  /// **'La categoría «{name}» no existe en el evento'**
  String issueUnknownCategory(String name);

  /// No description provided for @issueChosenCategoryGone.
  ///
  /// In es, this message translates to:
  /// **'La categoría elegida ya no existe'**
  String get issueChosenCategoryGone;

  /// No description provided for @issueCategoryMismatch.
  ///
  /// In es, this message translates to:
  /// **'Indica {written}, pero por su edad le corresponde {byAge}'**
  String issueCategoryMismatch(String written, String byAge);

  /// No description provided for @issueDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Repetido en la lista (fila {row})'**
  String issueDuplicate(String row);

  /// No description provided for @issueAlreadyRegistered.
  ///
  /// In es, this message translates to:
  /// **'Ya está inscrito en el evento'**
  String get issueAlreadyRegistered;

  /// No description provided for @issueUnsure.
  ///
  /// In es, this message translates to:
  /// **'Revisa {field}: no se leyó con seguridad'**
  String issueUnsure(String field);

  /// No description provided for @legalSection.
  ///
  /// In es, this message translates to:
  /// **'Legal'**
  String get legalSection;

  /// No description provided for @legalPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get legalPrivacy;

  /// No description provided for @legalTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos de uso'**
  String get legalTerms;

  /// No description provided for @legalCookies.
  ///
  /// In es, this message translates to:
  /// **'Política de cookies'**
  String get legalCookies;

  /// No description provided for @legalNotice.
  ///
  /// In es, this message translates to:
  /// **'Aviso legal'**
  String get legalNotice;

  /// No description provided for @legalPrivacyShort.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get legalPrivacyShort;

  /// No description provided for @legalTermsShort.
  ///
  /// In es, this message translates to:
  /// **'Términos'**
  String get legalTermsShort;

  /// No description provided for @legalCookiesShort.
  ///
  /// In es, this message translates to:
  /// **'Cookies'**
  String get legalCookiesShort;

  /// No description provided for @legalLicenses.
  ///
  /// In es, this message translates to:
  /// **'Licencias'**
  String get legalLicenses;

  /// No description provided for @legalPrivacyLink.
  ///
  /// In es, this message translates to:
  /// **'política de privacidad'**
  String get legalPrivacyLink;

  /// No description provided for @legalTermsLink.
  ///
  /// In es, this message translates to:
  /// **'términos de uso'**
  String get legalTermsLink;

  /// No description provided for @legalNotFound.
  ///
  /// In es, this message translates to:
  /// **'Esta página legal no existe.'**
  String get legalNotFound;

  /// No description provided for @registerLegalOutdated.
  ///
  /// In es, this message translates to:
  /// **'Los términos de uso o la política de privacidad han cambiado. Revísalos y vuelve a aceptarlos.'**
  String get registerLegalOutdated;

  /// No description provided for @participantPrivacyNotice.
  ///
  /// In es, this message translates to:
  /// **'Los datos del alumno se tratan según la {privacy}.'**
  String participantPrivacyNotice(String privacy);

  /// No description provided for @importPrivacyNotice.
  ///
  /// In es, this message translates to:
  /// **'Los datos de los alumnos se tratan según la {privacy}.'**
  String importPrivacyNotice(String privacy);

  /// No description provided for @serverCurrent.
  ///
  /// In es, this message translates to:
  /// **'Servidor: {name}'**
  String serverCurrent(String name);

  /// No description provided for @serverChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get serverChange;

  /// No description provided for @serverDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegir servidor'**
  String get serverDialogTitle;

  /// No description provided for @serverHall.
  ///
  /// In es, this message translates to:
  /// **'Pabellón'**
  String get serverHall;

  /// No description provided for @serverInternet.
  ///
  /// In es, this message translates to:
  /// **'Internet'**
  String get serverInternet;

  /// No description provided for @serverOther.
  ///
  /// In es, this message translates to:
  /// **'Otra URL'**
  String get serverOther;

  /// No description provided for @serverUrlLabel.
  ///
  /// In es, this message translates to:
  /// **'URL del servidor'**
  String get serverUrlLabel;

  /// No description provided for @serverUrlHint.
  ///
  /// In es, this message translates to:
  /// **'https://servidor.ejemplo'**
  String get serverUrlHint;

  /// No description provided for @serverUrlInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe una URL que empiece por http:// o https:// y tenga servidor.'**
  String get serverUrlInvalid;

  /// No description provided for @serverUrlCleartext.
  ///
  /// In es, this message translates to:
  /// **'Sin https la app solo llega al pabellón (192.168.137.1): con esta URL no conectará.'**
  String get serverUrlCleartext;

  /// No description provided for @serverUse.
  ///
  /// In es, this message translates to:
  /// **'Usar'**
  String get serverUse;

  /// No description provided for @syncConnected.
  ///
  /// In es, this message translates to:
  /// **'Conectado'**
  String get syncConnected;

  /// No description provided for @syncOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get syncOffline;

  /// No description provided for @syncPending.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 acción pendiente} other{{count} acciones pendientes}}'**
  String syncPending(int count);

  /// No description provided for @syncRejected.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 acción rechazada} other{{count} acciones rechazadas}}'**
  String syncRejected(int count);

  /// No description provided for @syncRejectedShow.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get syncRejectedShow;

  /// No description provided for @syncRejectedTitle.
  ///
  /// In es, this message translates to:
  /// **'Acciones rechazadas'**
  String get syncRejectedTitle;

  /// No description provided for @syncRejectedBody.
  ///
  /// In es, this message translates to:
  /// **'El servidor no aceptó estas acciones y no cuentan en el combate. Avisa al club si hace falta.'**
  String get syncRejectedBody;

  /// No description provided for @syncRejectedDismiss.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la lista'**
  String get syncRejectedDismiss;

  /// No description provided for @syncExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar acciones pendientes'**
  String get syncExport;

  /// No description provided for @syncExportBody.
  ///
  /// In es, this message translates to:
  /// **'Si este dispositivo no vuelve a conectar, entrega el fichero al club: lo importa desde su panel y no se pierde nada.'**
  String get syncExportBody;

  /// No description provided for @syncExportSave.
  ///
  /// In es, this message translates to:
  /// **'Descargar CSV'**
  String get syncExportSave;

  /// No description provided for @importOps.
  ///
  /// In es, this message translates to:
  /// **'Importar acciones de un dispositivo'**
  String get importOps;

  /// No description provided for @importOpsResult.
  ///
  /// In es, this message translates to:
  /// **'Importadas: {applied} nuevas · {duplicates} ya estaban · {inReview} a revisión · {skipped} rechazadas'**
  String importOpsResult(
    int applied,
    int duplicates,
    int inReview,
    int skipped,
  );

  /// No description provided for @importOpsError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido importar: el fichero no es de acciones pendientes o es de otro evento.'**
  String get importOpsError;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @matOfflineBoard.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: tablero guardado en este dispositivo. Sin recomendado; puedes empezar un pendiente si no hay otro en curso.'**
  String get matOfflineBoard;

  /// No description provided for @matInReview.
  ///
  /// In es, this message translates to:
  /// **'En revisión del club'**
  String get matInReview;

  /// No description provided for @refusalFinished.
  ///
  /// In es, this message translates to:
  /// **'El combate ya está finalizado.'**
  String get refusalFinished;

  /// No description provided for @refusalOver.
  ///
  /// In es, this message translates to:
  /// **'El combate ya ha acabado.'**
  String get refusalOver;

  /// No description provided for @refusalRunning.
  ///
  /// In es, this message translates to:
  /// **'El reloj ya está en marcha.'**
  String get refusalRunning;

  /// No description provided for @refusalNotRunning.
  ///
  /// In es, this message translates to:
  /// **'El reloj no está en marcha.'**
  String get refusalNotRunning;

  /// No description provided for @refusalNothingToUndo.
  ///
  /// In es, this message translates to:
  /// **'No hay nada que deshacer.'**
  String get refusalNothingToUndo;

  /// No description provided for @refusalNotOver.
  ///
  /// In es, this message translates to:
  /// **'El combate todavía no ha acabado.'**
  String get refusalNotOver;

  /// No description provided for @refusalNotForAge.
  ///
  /// In es, this message translates to:
  /// **'El aviso de una mano solo es para alumnos de 4 a 7 años.'**
  String get refusalNotForAge;

  /// No description provided for @refusalInReview.
  ///
  /// In es, this message translates to:
  /// **'El combate está en revisión del club.'**
  String get refusalInReview;

  /// No description provided for @refusalMatBusy.
  ///
  /// In es, this message translates to:
  /// **'Hay otro combate en curso en este tapiz.'**
  String get refusalMatBusy;

  /// No description provided for @reviewBannerReferee.
  ///
  /// In es, this message translates to:
  /// **'En revisión del club: este combate queda parado hasta que el club aplique o descarte las acciones de este móvil.'**
  String get reviewBannerReferee;

  /// No description provided for @reviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Acciones del móvil en revisión'**
  String get reviewTitle;

  /// No description provided for @reviewReasonKnownEvents.
  ///
  /// In es, this message translates to:
  /// **'Otro dispositivo escribió en el combate mientras el móvil estaba sin conexión.'**
  String get reviewReasonKnownEvents;

  /// No description provided for @reviewReasonRules.
  ///
  /// In es, this message translates to:
  /// **'Las reglas del marcador no permitían una acción del móvil.'**
  String get reviewReasonRules;

  /// No description provided for @reviewReasonAge.
  ///
  /// In es, this message translates to:
  /// **'Aviso de una mano a quien no tiene de 4 a 7 años.'**
  String get reviewReasonAge;

  /// No description provided for @reviewReasonMatBusy.
  ///
  /// In es, this message translates to:
  /// **'Había otro combate en curso en el tapiz.'**
  String get reviewReasonMatBusy;

  /// No description provided for @reviewReasonFighterBusy.
  ///
  /// In es, this message translates to:
  /// **'Un alumno estaba combatiendo en otro tapiz.'**
  String get reviewReasonFighterBusy;

  /// No description provided for @reviewReasonUnknown.
  ///
  /// In es, this message translates to:
  /// **'Choque con el servidor.'**
  String get reviewReasonUnknown;

  /// No description provided for @reviewApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get reviewApply;

  /// No description provided for @reviewDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get reviewDiscard;

  /// No description provided for @reviewApplyConfirm.
  ///
  /// In es, this message translates to:
  /// **'Se añaden las acciones del móvil en orden y con su hora. Las que las reglas no permitan se saltan.'**
  String get reviewApplyConfirm;

  /// No description provided for @reviewDiscardConfirm.
  ///
  /// In es, this message translates to:
  /// **'Las acciones del móvil no cuentan en el combate. Quedan guardadas en el registro.'**
  String get reviewDiscardConfirm;

  /// No description provided for @reviewApplied.
  ///
  /// In es, this message translates to:
  /// **'Aplicadas: {applied} · Saltadas: {skipped}'**
  String reviewApplied(int applied, int skipped);

  /// No description provided for @reviewDiscarded.
  ///
  /// In es, this message translates to:
  /// **'Acciones descartadas.'**
  String get reviewDiscarded;

  /// No description provided for @matsInReview.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 combate en revisión} other{{count} combates en revisión}}'**
  String matsInReview(int count);

  /// No description provided for @logoutPending.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Tienes 1 acción sin enviar; si sales se perderá.} other{Tienes {count} acciones sin enviar; si sales se perderán.}}'**
  String logoutPending(int count);

  /// No description provided for @refusalNotStarted.
  ///
  /// In es, this message translates to:
  /// **'Inicia el tiempo antes de puntuar.'**
  String get refusalNotStarted;

  /// No description provided for @undoneWhat.
  ///
  /// In es, this message translates to:
  /// **'Deshecho: {what}'**
  String undoneWhat(String what);

  /// No description provided for @whatPoint.
  ///
  /// In es, this message translates to:
  /// **'+1 {corner}'**
  String whatPoint(String corner);

  /// No description provided for @whatWarning.
  ///
  /// In es, this message translates to:
  /// **'advertencia {corner}'**
  String whatWarning(String corner);

  /// No description provided for @whatOneHand.
  ///
  /// In es, this message translates to:
  /// **'una mano {corner}'**
  String whatOneHand(String corner);

  /// No description provided for @whatDisqualification.
  ///
  /// In es, this message translates to:
  /// **'descalificación {corner}'**
  String whatDisqualification(String corner);

  /// No description provided for @winner.
  ///
  /// In es, this message translates to:
  /// **'Ganador'**
  String get winner;

  /// No description provided for @draw.
  ///
  /// In es, this message translates to:
  /// **'Empate'**
  String get draw;

  /// No description provided for @matLocked.
  ///
  /// In es, this message translates to:
  /// **'No se puede abrir todavía'**
  String get matLocked;

  /// No description provided for @needsGuardian.
  ///
  /// In es, this message translates to:
  /// **'Falta tutor'**
  String get needsGuardian;

  /// No description provided for @settingsRemoveMatConfirm.
  ///
  /// In es, this message translates to:
  /// **'Se quita el Tapiz {number}; su árbitro deja de estar asignado.'**
  String settingsRemoveMatConfirm(int number);

  /// No description provided for @draftTitle.
  ///
  /// In es, this message translates to:
  /// **'Grupo nuevo'**
  String get draftTitle;

  /// No description provided for @draftReady.
  ///
  /// In es, this message translates to:
  /// **'Completo'**
  String get draftReady;

  /// No description provided for @draftMissing.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Falta 1} other{Faltan {count}}}'**
  String draftMissing(int count);

  /// No description provided for @draftSlot.
  ///
  /// In es, this message translates to:
  /// **'Hueco {number}'**
  String draftSlot(int number);

  /// No description provided for @ghostOf.
  ///
  /// In es, this message translates to:
  /// **'{name} (comodín)'**
  String ghostOf(String name);

  /// No description provided for @settingsAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceHint.
  ///
  /// In es, this message translates to:
  /// **'Automático sigue al modo claro u oscuro del dispositivo. Se guarda solo en este dispositivo.'**
  String get settingsAppearanceHint;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @accountSuspended.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta está suspendida. Si crees que es un error, escribe al contacto de privacidad que aparece en las páginas legales.'**
  String get accountSuspended;

  /// No description provided for @backTo.
  ///
  /// In es, this message translates to:
  /// **'Volver a {place}'**
  String backTo(String place);

  /// No description provided for @reasonApplyWarning.
  ///
  /// In es, this message translates to:
  /// **'Poner advertencia'**
  String get reasonApplyWarning;

  /// No description provided for @reasonApplyDisqualify.
  ///
  /// In es, this message translates to:
  /// **'Descalificar'**
  String get reasonApplyDisqualify;

  /// No description provided for @accountMenu.
  ///
  /// In es, this message translates to:
  /// **'Mi cuenta'**
  String get accountMenu;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @clubLeague.
  ///
  /// In es, this message translates to:
  /// **'Liga'**
  String get clubLeague;

  /// No description provided for @phaseNumber.
  ///
  /// In es, this message translates to:
  /// **'Fase {number}'**
  String phaseNumber(int number);

  /// No description provided for @leagueSwitchPhase.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de fase'**
  String get leagueSwitchPhase;

  /// No description provided for @leaguePodiumSummary.
  ///
  /// In es, this message translates to:
  /// **'Podio: {firsts} oros, {seconds} platas y {thirds} bronces por categoría'**
  String leaguePodiumSummary(int firsts, int seconds, int thirds);

  /// No description provided for @leagueEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar liga'**
  String get leagueEdit;

  /// No description provided for @leaguePhases.
  ///
  /// In es, this message translates to:
  /// **'Fases'**
  String get leaguePhases;

  /// No description provided for @leagueNewPhase.
  ///
  /// In es, this message translates to:
  /// **'Nueva fase'**
  String get leagueNewPhase;

  /// No description provided for @leaguePhaseEntries.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 inscrito} other{{count} inscritos}}'**
  String leaguePhaseEntries(int count);

  /// No description provided for @leagueCurrentPhase.
  ///
  /// In es, this message translates to:
  /// **'Esta fase'**
  String get leagueCurrentPhase;

  /// No description provided for @disciplineTambo.
  ///
  /// In es, this message translates to:
  /// **'Tambo'**
  String get disciplineTambo;

  /// No description provided for @disciplineGround.
  ///
  /// In es, this message translates to:
  /// **'Suelo'**
  String get disciplineGround;

  /// No description provided for @disciplineThrows.
  ///
  /// In es, this message translates to:
  /// **'Derribos'**
  String get disciplineThrows;

  /// No description provided for @disciplineTechnicalExpression.
  ///
  /// In es, this message translates to:
  /// **'Expresión técnica'**
  String get disciplineTechnicalExpression;

  /// No description provided for @disciplineSoon.
  ///
  /// In es, this message translates to:
  /// **'{name} (próximamente)'**
  String disciplineSoon(String name);

  /// No description provided for @leagueStandings.
  ///
  /// In es, this message translates to:
  /// **'Clasificación de la liga'**
  String get leagueStandings;

  /// No description provided for @leagueStandingsCsv.
  ///
  /// In es, this message translates to:
  /// **'Descargar CSV'**
  String get leagueStandingsCsv;

  /// No description provided for @leaguePhasePoints.
  ///
  /// In es, this message translates to:
  /// **'Fase {number}: {total} ({attendance} por asistir + {matches} en combates)'**
  String leaguePhasePoints(int number, int total, int attendance, int matches);

  /// No description provided for @leaguePhaseAbsent.
  ///
  /// In es, this message translates to:
  /// **'Fase {number}: no inscrito'**
  String leaguePhaseAbsent(int number);

  /// No description provided for @leagueNoPoints.
  ///
  /// In es, this message translates to:
  /// **'Sin puntos todavía: sin puesto'**
  String get leagueNoPoints;

  /// No description provided for @leagueCategoryHeader.
  ///
  /// In es, this message translates to:
  /// **'{category} · {count, plural, =1{1 persona} other{{count} personas}}'**
  String leagueCategoryHeader(String category, int count);

  /// No description provided for @medalGold.
  ///
  /// In es, this message translates to:
  /// **'Oro'**
  String get medalGold;

  /// No description provided for @medalSilver.
  ///
  /// In es, this message translates to:
  /// **'Plata'**
  String get medalSilver;

  /// No description provided for @medalBronze.
  ///
  /// In es, this message translates to:
  /// **'Bronce'**
  String get medalBronze;

  /// No description provided for @leaguePhaseDefaultName.
  ///
  /// In es, this message translates to:
  /// **'{league} · Fase {number}'**
  String leaguePhaseDefaultName(String league, int number);

  /// No description provided for @leagueNewPhaseTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva fase {number}'**
  String leagueNewPhaseTitle(int number);

  /// No description provided for @leagueNewPhaseHint.
  ///
  /// In es, this message translates to:
  /// **'Se copian de esta fase los tapices con sus árbitros, los ayudantes, las categorías, los clubes y las reglas del marcador. Las inscripciones empiezan vacías: después puedes inscribir a los de otras fases.'**
  String get leagueNewPhaseHint;

  /// No description provided for @leaguePhaseName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la fase'**
  String get leaguePhaseName;

  /// No description provided for @leagueDiscipline.
  ///
  /// In es, this message translates to:
  /// **'Modalidad'**
  String get leagueDiscipline;

  /// No description provided for @leagueAttendancePoints.
  ///
  /// In es, this message translates to:
  /// **'Puntos por asistir'**
  String get leagueAttendancePoints;

  /// No description provided for @leagueAttendanceInvalid.
  ///
  /// In es, this message translates to:
  /// **'Entre 0 y 100'**
  String get leagueAttendanceInvalid;

  /// No description provided for @leagueNewPhaseCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear fase'**
  String get leagueNewPhaseCreate;

  /// No description provided for @leagueNewPhaseDone.
  ///
  /// In es, this message translates to:
  /// **'Fase {number} creada'**
  String leagueNewPhaseDone(int number);

  /// No description provided for @leagueName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la liga'**
  String get leagueName;

  /// No description provided for @leaguePodium.
  ///
  /// In es, this message translates to:
  /// **'Podio general'**
  String get leaguePodium;

  /// No description provided for @leaguePodiumHint.
  ///
  /// In es, this message translates to:
  /// **'Cuántos oros, platas y bronces da cada categoría en la clasificación final. Los empates comparten medalla.'**
  String get leaguePodiumHint;

  /// No description provided for @leagueCategoryPodiums.
  ///
  /// In es, this message translates to:
  /// **'Categorías con podio propio'**
  String get leagueCategoryPodiums;

  /// No description provided for @leagueOwnPodium.
  ///
  /// In es, this message translates to:
  /// **'Podio propio'**
  String get leagueOwnPodium;

  /// No description provided for @reenrolButton.
  ///
  /// In es, this message translates to:
  /// **'Inscribir de otras fases'**
  String get reenrolButton;

  /// No description provided for @reenrolTitle.
  ///
  /// In es, this message translates to:
  /// **'Inscribir de otras fases'**
  String get reenrolTitle;

  /// No description provided for @reenrolEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todos los de otras fases ya están inscritos en esta.'**
  String get reenrolEmpty;

  /// No description provided for @reenrolHint.
  ///
  /// In es, this message translates to:
  /// **'Se inscriben con sus datos de la última fase; la categoría sale de su edad en esta.'**
  String get reenrolHint;

  /// No description provided for @reenrolSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre, categoría o club'**
  String get reenrolSearch;

  /// No description provided for @reenrolSelectAll.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar todos ({count})'**
  String reenrolSelectAll(int count);

  /// No description provided for @reenrolLastPhase.
  ///
  /// In es, this message translates to:
  /// **'Última: fase {number}'**
  String reenrolLastPhase(int number);

  /// No description provided for @reenrolGuardianConsent.
  ///
  /// In es, this message translates to:
  /// **'Tengo el consentimiento de los tutores de los menores seleccionados'**
  String get reenrolGuardianConsent;

  /// No description provided for @reenrolConfirm.
  ///
  /// In es, this message translates to:
  /// **'Inscribir ({count})'**
  String reenrolConfirm(int count);

  /// No description provided for @reenrolDone.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 inscrito} other{{count} inscritos}}'**
  String reenrolDone(int count);

  /// No description provided for @settingsAttendanceHint.
  ///
  /// In es, this message translates to:
  /// **'Los suma a la clasificación quien compite en un grupo de esta fase. Al cambiarlos se recalcula la clasificación.'**
  String get settingsAttendanceHint;

  /// No description provided for @draftTakenElsewhere.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{{names} ya está en otro grupo: se ha quitado del grupo nuevo.} other{{names} ya están en otro grupo: se han quitado del grupo nuevo.}}'**
  String draftTakenElsewhere(int count, String names);

  /// No description provided for @teamGhostMember.
  ///
  /// In es, this message translates to:
  /// **'entra como comodín'**
  String get teamGhostMember;

  /// No description provided for @teamGhostHint.
  ///
  /// In es, this message translates to:
  /// **'Quien ya tiene equipo o grupo entra como comodín: combate, pero no puntúa por este equipo.'**
  String get teamGhostHint;

  /// No description provided for @ghostMemberName.
  ///
  /// In es, this message translates to:
  /// **'{name} (comodín)'**
  String ghostMemberName(String name);

  /// No description provided for @teamOverlapTitle.
  ///
  /// In es, this message translates to:
  /// **'No se puede: alumnos en dos equipos del grupo'**
  String get teamOverlapTitle;

  /// No description provided for @teamOverlapLine.
  ///
  /// In es, this message translates to:
  /// **'{name}: {teams}'**
  String teamOverlapLine(String name, String teams);

  /// No description provided for @groupCreatedBy.
  ///
  /// In es, this message translates to:
  /// **'por {name}'**
  String groupCreatedBy(String name);

  /// No description provided for @staffTitle.
  ///
  /// In es, this message translates to:
  /// **'Personal'**
  String get staffTitle;

  /// No description provided for @staffHint.
  ///
  /// In es, this message translates to:
  /// **'Quién está detrás de cada cuenta: se verá en los tapices y en quién ha hecho cada grupo.'**
  String get staffHint;

  /// No description provided for @staffNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la persona'**
  String get staffNameHint;

  /// No description provided for @staffReferee.
  ///
  /// In es, this message translates to:
  /// **'árbitro'**
  String get staffReferee;

  /// No description provided for @staffHelper.
  ///
  /// In es, this message translates to:
  /// **'ayudante'**
  String get staffHelper;

  /// No description provided for @cancelMatch.
  ///
  /// In es, this message translates to:
  /// **'Cancelar combate'**
  String get cancelMatch;

  /// No description provided for @cancelMatchTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar el combate: vuelve a pendiente y todo a 0. ¿Por qué?'**
  String get cancelMatchTitle;

  /// No description provided for @cancelMatchDone.
  ///
  /// In es, this message translates to:
  /// **'Combate cancelado: vuelve a estar pendiente.'**
  String get cancelMatchDone;

  /// No description provided for @reopenMatch.
  ///
  /// In es, this message translates to:
  /// **'Reabrir combate'**
  String get reopenMatch;

  /// No description provided for @reopenMatchTitle.
  ///
  /// In es, this message translates to:
  /// **'Reabrir el combate para corregirlo. ¿Por qué?'**
  String get reopenMatchTitle;

  /// No description provided for @reopenMatchDone.
  ///
  /// In es, this message translates to:
  /// **'Combate reabierto: corrige y vuelve a finalizar.'**
  String get reopenMatchDone;

  /// No description provided for @refusalNotFinished.
  ///
  /// In es, this message translates to:
  /// **'El combate no está finalizado.'**
  String get refusalNotFinished;

  /// No description provided for @tlCancel.
  ///
  /// In es, this message translates to:
  /// **'Combate cancelado'**
  String get tlCancel;

  /// No description provided for @tlReopen.
  ///
  /// In es, this message translates to:
  /// **'Combate reabierto'**
  String get tlReopen;

  /// No description provided for @matOneAtATime.
  ///
  /// In es, this message translates to:
  /// **'Hay un combate en curso: el siguiente se podrá empezar cuando acabe.'**
  String get matOneAtATime;

  /// No description provided for @matQueued.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get matQueued;

  /// No description provided for @keepMatch.
  ///
  /// In es, this message translates to:
  /// **'Seguir con el combate'**
  String get keepMatch;

  /// No description provided for @watchClockRunning.
  ///
  /// In es, this message translates to:
  /// **'Reloj en marcha'**
  String get watchClockRunning;

  /// No description provided for @watchClockStopped.
  ///
  /// In es, this message translates to:
  /// **'Reloj parado'**
  String get watchClockStopped;

  /// No description provided for @placeInCategory.
  ///
  /// In es, this message translates to:
  /// **'{place}.º en {category} · {age} años'**
  String placeInCategory(int place, String category, int age);

  /// No description provided for @recordTotals.
  ///
  /// In es, this message translates to:
  /// **'Asistencia {attendance} + combates {matches} = {total} puntos'**
  String recordTotals(int attendance, int matches, int total);

  /// No description provided for @recordNoMatches.
  ///
  /// In es, this message translates to:
  /// **'Aún no está en ningún grupo.'**
  String get recordNoMatches;

  /// No description provided for @recordVs.
  ///
  /// In es, this message translates to:
  /// **'Contra {rival}'**
  String recordVs(String rival);

  /// No description provided for @recordWhere.
  ///
  /// In es, this message translates to:
  /// **'{mat} · Grupo {group}'**
  String recordWhere(String mat, int group);

  /// No description provided for @recordWon.
  ///
  /// In es, this message translates to:
  /// **'Ganado'**
  String get recordWon;

  /// No description provided for @recordLost.
  ///
  /// In es, this message translates to:
  /// **'Perdido'**
  String get recordLost;

  /// No description provided for @recordDraw.
  ///
  /// In es, this message translates to:
  /// **'Empate'**
  String get recordDraw;

  /// No description provided for @recordAsGhost.
  ///
  /// In es, this message translates to:
  /// **'como comodín (no puntúa)'**
  String get recordAsGhost;

  /// No description provided for @recordWarnings.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 advertencia} other{{count} advertencias}}'**
  String recordWarnings(num count);

  /// No description provided for @recordOneHand.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 de una mano} other{{count} de una mano}}'**
  String recordOneHand(num count);

  /// No description provided for @recordDisqualified.
  ///
  /// In es, this message translates to:
  /// **'Descalificado'**
  String get recordDisqualified;

  /// No description provided for @leagueDisqualifications.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 descalificación} other{{count} descalificaciones}}'**
  String leagueDisqualifications(int count);

  /// No description provided for @recordRivalDisqualified.
  ///
  /// In es, this message translates to:
  /// **'Rival descalificado'**
  String get recordRivalDisqualified;

  /// No description provided for @recordOpen.
  ///
  /// In es, this message translates to:
  /// **'Ver combates'**
  String get recordOpen;

  /// No description provided for @openLeague.
  ///
  /// In es, this message translates to:
  /// **'Abrir la liga'**
  String get openLeague;

  /// No description provided for @podiumPreset.
  ///
  /// In es, this message translates to:
  /// **'{gold, plural, =1{1 oro} other{{gold} oros}} · {silver, plural, =1{1 plata} other{{silver} platas}} · {bronze, plural, =1{1 bronce} other{{bronze} bronces}}'**
  String podiumPreset(int gold, int silver, int bronze);

  /// No description provided for @podiumOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get podiumOther;

  /// No description provided for @podiumAsGeneral.
  ///
  /// In es, this message translates to:
  /// **'Como el general ({podium})'**
  String podiumAsGeneral(String podium);

  /// No description provided for @podiumOwn.
  ///
  /// In es, this message translates to:
  /// **'Propio'**
  String get podiumOwn;

  /// No description provided for @podiumLess.
  ///
  /// In es, this message translates to:
  /// **'Uno menos: {metal}'**
  String podiumLess(String metal);

  /// No description provided for @podiumMore.
  ///
  /// In es, this message translates to:
  /// **'Uno más: {metal}'**
  String podiumMore(String metal);

  /// No description provided for @leagueCategoryPodiumsHint.
  ///
  /// In es, this message translates to:
  /// **'Casi todas usan el general; elige \"Propio\" solo en las que den otras medallas.'**
  String get leagueCategoryPodiumsHint;
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
