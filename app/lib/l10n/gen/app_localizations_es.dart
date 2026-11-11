// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Brackety';

  @override
  String get navConnection => 'Conexión';

  @override
  String get loading => 'Cargando…';

  @override
  String get retry => 'Reintentar';

  @override
  String get loadError => 'No se ha podido cargar. Comprueba la conexión.';

  @override
  String get noServer => 'No hay conexión con el servidor.';

  @override
  String get unexpectedError => 'Algo ha ido mal. Inténtalo de nuevo.';

  @override
  String tooManyRequests(int seconds) {
    return 'Demasiadas peticiones. Espera $seconds s y vuelve a intentarlo.';
  }

  @override
  String get tooManyRequestsWait =>
      'Demasiadas peticiones. Espera un momento y vuelve a intentarlo.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get fieldRequired => 'Campo obligatorio.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailInvalid => 'Escribe un email válido.';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordHint => 'Mínimo 10 caracteres.';

  @override
  String get passwordTooShort =>
      'La contraseña necesita al menos 10 caracteres.';

  @override
  String get passwordTooLong =>
      'La contraseña admite como máximo 128 caracteres.';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get goToLogin => 'Ir a iniciar sesión';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginSubmit => 'Entrar';

  @override
  String get loginInvalid => 'Email o contraseña incorrectos.';

  @override
  String loginLocked(String lockId) {
    return 'Cuenta bloqueada 15 minutos por demasiados intentos fallidos. Si necesitas ayuda, indica el código $lockId.';
  }

  @override
  String get loginForgot => '¿Has olvidado la contraseña?';

  @override
  String get loginNoAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get loginPasswordChanged =>
      'Contraseña cambiada. Ya puedes entrar con la nueva.';

  @override
  String get loginDemoAccounts => 'Cuentas de prueba (solo en desarrollo)';

  @override
  String get restoreTitle => 'Cuenta pendiente de borrado';

  @override
  String restoreBody(String date) {
    return 'Tu cuenta se borrará el $date. ¿Quieres recuperarla?';
  }

  @override
  String get restoreConfirm => 'Recuperar cuenta';

  @override
  String get restoreExpired =>
      'Ha pasado demasiado tiempo. Vuelve a entrar para recuperar la cuenta.';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerSubmit => 'Crear cuenta';

  @override
  String get registerBirthDate => 'Fecha de nacimiento';

  @override
  String get registerUnderage =>
      'Los menores de 14 años no pueden crear su propia cuenta. Su padre, madre o tutor lo da de alta desde su cuenta añadiendo un perfil de menor (disponible próximamente).';

  @override
  String get registerProfile => '¿Cómo vas a usar Brackety?';

  @override
  String get registerProfileRequired => 'Elige un perfil.';

  @override
  String get profileClub => 'Club';

  @override
  String get profileClubHint =>
      'Organiza eventos e inscribe a sus deportistas.';

  @override
  String get profileExternalEntity => 'Entidad externa';

  @override
  String get profileExternalEntityHint =>
      'Federación, ayuntamiento u otra entidad que organiza eventos.';

  @override
  String get profileHelper => 'Ayudante';

  @override
  String get profileHelperHint =>
      'Colabora en los eventos: grupos, mesa o arbitraje.';

  @override
  String get profileExternal => 'Externo';

  @override
  String get profileExternalHint =>
      'Sigue eventos y resultados sin pertenecer a un club.';

  @override
  String get profileStudent => 'Alumno';

  @override
  String get profileStudentHint => 'Deportista que compite con su club.';

  @override
  String registerAccept(String terms, String privacy) {
    return 'Acepto los $terms y la $privacy.';
  }

  @override
  String get registerAcceptRequired => 'Debes aceptarlos para crear la cuenta.';

  @override
  String get registerOrganizationName => 'Nombre de la organización';

  @override
  String get registerOrganizationNameLength => 'Entre 2 y 200 caracteres.';

  @override
  String get registerTaxId => 'CIF';

  @override
  String get registerTaxIdHelper =>
      'La plataforma lo usa para verificar la organización antes de que pueda publicar eventos.';

  @override
  String get registerTaxIdInvalid => 'CIF no válido.';

  @override
  String get registerRepresentative =>
      'Soy mayor de edad y represento a esta organización.';

  @override
  String get registerRepresentativeRequired =>
      'Debes confirmarlo para registrar la organización.';

  @override
  String get registerHaveAccount => '¿Ya tienes cuenta? Entra';

  @override
  String get checkEmailTitle => 'Revisa tu email';

  @override
  String get checkEmailBody =>
      'Te hemos enviado un email. Abre su enlace para verificar la cuenta; caduca en 24 horas.';

  @override
  String get resendEmail => 'Reenviar email';

  @override
  String get resendSent => 'Email enviado.';

  @override
  String get verifyBanner =>
      'Verifica tu email: algunas acciones lo necesitan.';

  @override
  String get verifyTitle => 'Verificar email';

  @override
  String get verifySuccess => 'Email verificado. ¡Gracias!';

  @override
  String get linkInvalid => 'El enlace no es válido o ha caducado.';

  @override
  String get forgotTitle => 'Recuperar contraseña';

  @override
  String get forgotIntro =>
      'Escribe tu email y te enviaremos un enlace para elegir una contraseña nueva.';

  @override
  String get forgotSubmit => 'Enviar enlace';

  @override
  String get forgotSent =>
      'Si hay una cuenta con ese email, te hemos enviado un enlace para cambiar la contraseña.';

  @override
  String get resetTitle => 'Nueva contraseña';

  @override
  String get resetNewPassword => 'Nueva contraseña';

  @override
  String get resetConfirmPassword => 'Repite la contraseña';

  @override
  String get resetMismatch => 'Las contraseñas no coinciden.';

  @override
  String get resetSubmit => 'Cambiar contraseña';

  @override
  String get resetRequestNew => 'Pedir otro enlace';

  @override
  String get logout => 'Salir';

  @override
  String get eventsTitle => 'Mis eventos';

  @override
  String get eventsEmpty => 'No tienes eventos asignados.';

  @override
  String get roleClub => 'Club';

  @override
  String get roleGrouper => 'Ayudante';

  @override
  String get roleReferee => 'Árbitro';

  @override
  String get eventMakeGroups => 'Crear grupos';

  @override
  String eventMyMat(int number) {
    return 'Tapiz $number';
  }

  @override
  String get eventClubPanel => 'Panel del club';

  @override
  String get categoriesTitle => 'Categorías';

  @override
  String get categoriesEmpty => 'Todavía no hay inscritos.';

  @override
  String categoryCounts(int participants, int grouped) {
    return '$participants inscritos · $grouped en grupos';
  }

  @override
  String categoryAges(String name) {
    return '$name años';
  }

  @override
  String get sortByName => 'Nombre';

  @override
  String get sortByHeight => 'Estatura';

  @override
  String participantDetails(int age, String height) {
    return '$age años · $height';
  }

  @override
  String heightCm(int cm) {
    return '$cm cm';
  }

  @override
  String get heightUnknown => 'sin estatura';

  @override
  String participantGrouped(int group, int mat) {
    return 'Grupo $group · Tapiz $mat';
  }

  @override
  String draftGroup(int number) {
    return 'Grupo $number';
  }

  @override
  String get draftGhost => 'Competidor fantasma';

  @override
  String get draftGhostHint => 'Elige al fantasma: combate pero no puntúa.';

  @override
  String createGroup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Crear grupos',
      one: 'Crear grupo',
    );
    return '$_temp0';
  }

  @override
  String groupsCreatedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Grupos creados',
      one: 'Grupo creado',
    );
    return '$_temp0';
  }

  @override
  String get groupsConflict =>
      'Algún alumno ya está en un grupo o el tapiz se ha quedado sin árbitro. La lista se ha actualizado.';

  @override
  String get groupsError => 'No se ha podido crear el grupo.';

  @override
  String get ok => 'Aceptar';

  @override
  String get ghostBadge => 'Fantasma';

  @override
  String matTitle(int number) {
    return 'Tapiz $number';
  }

  @override
  String get matEmpty => 'Todavía no hay grupos en este tapiz.';

  @override
  String matGroupHeader(int number, String category) {
    return 'Grupo $number, de $category años';
  }

  @override
  String get matRecommended => 'Combate recomendado';

  @override
  String get matInProgress => 'En curso';

  @override
  String get matPending => 'Otros combates disponibles';

  @override
  String get matYours => 'Tu tapiz';

  @override
  String matToPlay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count por disputar',
      one: '1 por disputar',
    );
    return '$_temp0';
  }

  @override
  String get matOpenScoreboard => 'Abrir el marcador';

  @override
  String get matBackToScoreboard => 'Volver al marcador';

  @override
  String get matWatch => 'Ver el combate';

  @override
  String get matGroups => 'Grupos en este tapiz';

  @override
  String get matFinished => 'Disputados';

  @override
  String get matWaiting => 'Un luchador está combatiendo ahora';

  @override
  String get matNoneAvailable => 'Ningún combate puede empezar ahora.';

  @override
  String get versus => 'vs';

  @override
  String scoreboardTitle(int mat, int group) {
    return 'Tapiz $mat, grupo $group';
  }

  @override
  String get cornerRed => 'Rojo';

  @override
  String get cornerBlue => 'Azul';

  @override
  String get clockStart => 'Iniciar';

  @override
  String get clockStop => 'Parar';

  @override
  String get clockResume => 'Reanudar';

  @override
  String get finishMatch => 'Finalizar combate';

  @override
  String get matchFinished => 'Combate finalizado';

  @override
  String get backToMat => 'Volver al tapiz';

  @override
  String get undo => 'Deshacer';

  @override
  String get timeline => 'Línea de tiempo';

  @override
  String get addPoint => '+1';

  @override
  String addPointFor(String corner) {
    return '+1 $corner';
  }

  @override
  String sanctionsFor(String corner) {
    return 'Avisos: $corner';
  }

  @override
  String warningsCount(int count) {
    return 'Advertencias: $count';
  }

  @override
  String oneHandCount(int count) {
    return 'Una mano: $count';
  }

  @override
  String get disqualified => 'Descalificado';

  @override
  String get actionWarning => 'Advertencia';

  @override
  String get actionOneHand => 'Advertencia por golpear con una mano';

  @override
  String get actionDisqualify => 'Descalificación';

  @override
  String reasonTitle(String action, String fighter) {
    return '$action: $fighter';
  }

  @override
  String get reasonLabel => 'Motivo';

  @override
  String get reasonConfirm =>
      'Escribe el motivo. Queda en el historial del combate.';

  @override
  String get confirm => 'Confirmar';

  @override
  String get endPoints => 'Fin por puntos';

  @override
  String get endTime => 'Fin del tiempo';

  @override
  String get endDisqualification => 'Fin por descalificación';

  @override
  String actionRefused(String detail) {
    return 'No se ha podido registrar. $detail';
  }

  @override
  String get tlStart => 'Inicio del tiempo';

  @override
  String get tlStop => 'Parada';

  @override
  String get tlPoint => 'Punto';

  @override
  String get tlUndo => 'Deshacer';

  @override
  String get tlFinish => 'Fin del combate';

  @override
  String get tlAutomatic => 'automático';

  @override
  String get tlUndone => 'deshecho';

  @override
  String get tlRivalPoint => 'punto al rival';

  @override
  String get removePoint => '−1';

  @override
  String removePointFor(String corner) {
    return 'Quitar un punto a $corner';
  }

  @override
  String whatPointRemoved(String corner) {
    return '−1 $corner';
  }

  @override
  String whatClockAdjust(String delta) {
    return '$delta s al reloj';
  }

  @override
  String clockAdjustBy(String delta) {
    return '$delta s';
  }

  @override
  String clockAdjustTooltip(String delta) {
    return 'Ajustar el reloj $delta s';
  }

  @override
  String get clockAdjustHint => 'Ajustar el reloj (parado)';

  @override
  String get tlPointRemoved => 'Punto quitado';

  @override
  String get tlClockAdjust => 'Ajuste del reloj';

  @override
  String get tlNextUndo => 'lo siguiente que deshace Deshacer';

  @override
  String undoDetail(String what, String clock) {
    return '$what · $clock';
  }

  @override
  String get recentActions => 'Últimas acciones';

  @override
  String get refusalNoPoints => 'No tiene puntos que quitar.';

  @override
  String get refusalClockRunning => 'Para el reloj antes de ajustarlo.';

  @override
  String get refusalClockLimit => 'El reloj no puede ir más allá.';

  @override
  String get settingsMatchRules => 'Combates';

  @override
  String get settingsMatchLength => 'Duración del combate (min:s)';

  @override
  String get settingsMatchLengthHint =>
      'De 0:30 a 20:00. No cambia con un combate en curso.';

  @override
  String get settingsMatchLengthInvalid =>
      'Escribe minutos y segundos entre 0:30 y 20:00, por ejemplo 3:00.';

  @override
  String get settingsPointsLimit => 'Puntos para acabar el combate';

  @override
  String get settingsPointsLimitHint =>
      'Al llegar uno, acaba. La descalificación da estos puntos al rival. No cambia una vez empezado un combate.';

  @override
  String get settingsMatchRulesConflict =>
      'No se puede cambiar ahora: hay un combate en curso o ya empezado.';

  @override
  String get settingsPointsLimitInvalid => 'Entre 1 y 99.';

  @override
  String get matWaitingTitle => 'En espera';

  @override
  String get matStartRecommended => 'Empezar este combate';

  @override
  String get matRecommendedWhy =>
      'Sus luchadores son los que más han descansado y ninguno acaba de combatir.';

  @override
  String get matAfterCurrent => 'Cuando acabe el combate en curso.';

  @override
  String get undoGroup => 'Deshacer grupo';

  @override
  String undoGroupNumber(int number) {
    return 'Deshacer el Grupo $number';
  }

  @override
  String undoGroupConfirm(int number) {
    return 'Se deshace el Grupo $number y sus combates. Sus alumnos vuelven a la lista para agruparlos de nuevo.';
  }

  @override
  String undoGroupDone(int number) {
    return 'Grupo $number deshecho';
  }

  @override
  String get undoGroupStarted =>
      'Ya ha empezado un combate de este grupo: solo el administrador puede deshacerlo.';

  @override
  String get undoGroupError => 'No se ha podido deshacer el grupo.';

  @override
  String get clubStandings => 'Puntos';

  @override
  String get clubMats => 'Tapices';

  @override
  String get clubParticipants => 'Inscritos';

  @override
  String get clubSettings => 'Ajustes';

  @override
  String get allCategories => 'Todas las categorías';

  @override
  String get noCategory => 'Sin categoría';

  @override
  String get sortByPoints => 'Puntos';

  @override
  String get standingsEmpty => 'Todavía no hay puntuaciones.';

  @override
  String standingsTotal(int total) {
    return '$total pts';
  }

  @override
  String standingsDetail(int attendance, int points, int matches) {
    return 'Asistencia $attendance · Combates $points ($matches)';
  }

  @override
  String get matsEmpty => 'No hay tapices.';

  @override
  String matSummary(int groups, int pending) {
    String _temp0 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups grupos',
      one: '1 grupo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      pending,
      locale: localeName,
      other: '$pending combates pendientes',
      one: '1 combate pendiente',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get matNoReferee => 'Sin árbitro';

  @override
  String matEstimatedEnd(String time) {
    return 'Fin estimado $time';
  }

  @override
  String get matFighting => 'Combate en curso';

  @override
  String get matIdle => 'Parado';

  @override
  String get participantAdd => 'Inscribir alumno';

  @override
  String get participantEdit => 'Editar alumno';

  @override
  String get firstName => 'Nombre';

  @override
  String get lastName => 'Apellidos';

  @override
  String get birthDate => 'Fecha de nacimiento';

  @override
  String get heightOptional => 'Estatura en cm (opcional)';

  @override
  String get heightInvalid => 'Entre 50 y 250 cm';

  @override
  String get guardianConsent => 'El tutor legal está de acuerdo';

  @override
  String get guardianConsentRequired => 'Obligatorio para menores de 18 años.';

  @override
  String participantAgeCategory(int age, String category) {
    return '$age años · $category';
  }

  @override
  String deleteParticipantTitle(String name) {
    return '¿Borrar a $name?';
  }

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Borrar';

  @override
  String get saved => 'Guardado';

  @override
  String get saveConflict => 'No se puede: ya hay grupos que dependen de esto.';

  @override
  String get saveInvalid => 'Revisa los datos.';

  @override
  String get saveError => 'No se ha podido guardar.';

  @override
  String get settingsName => 'Nombre del evento';

  @override
  String get settingsDate => 'Fecha';

  @override
  String get settingsAddMat => 'Añadir tapiz';

  @override
  String get settingsRemoveMat => 'Quitar el último tapiz';

  @override
  String get settingsReferee => 'Árbitro';

  @override
  String categoryRange(String name, int min, int max) {
    return '$name · de $min a $max años';
  }

  @override
  String get exportMenu => 'Exportar';

  @override
  String get exportStandings => 'Clasificación (CSV)';

  @override
  String get exportMatches => 'Combates (CSV)';

  @override
  String get exportTimeline => 'Línea de tiempo (CSV)';

  @override
  String get exportEventPackage => 'Exportar paquete del evento';

  @override
  String get exportError => 'No se ha podido exportar.';

  @override
  String get matchLive => 'En curso';

  @override
  String get matchNotStarted => 'Sin empezar';

  @override
  String teamName(int number) {
    return 'Equipo $number';
  }

  @override
  String teamGhostName(int number) {
    return 'Equipo $number (fantasma)';
  }

  @override
  String get tabParticipants => 'Alumnos';

  @override
  String get tabTeams => 'Equipos';

  @override
  String get individualGroup => 'Grupo individual';

  @override
  String get teamGroup => 'Grupo por equipos';

  @override
  String get matPickerLabel => 'Tapiz';

  @override
  String get matAuto => 'Automático';

  @override
  String get matAutoOption => 'El que antes quede libre';

  @override
  String get matAutoHint =>
      'Se asignará automáticamente al tapiz que antes quede libre.';

  @override
  String matManualHint(String mat) {
    return 'Irá al $mat, elegido a mano.';
  }

  @override
  String get individualGroupHint =>
      'Para quien se quede sin equipo: grupos de 4 alumnos.';

  @override
  String categoryTeamCounts(int participants, int teams, int grouped) {
    return '$participants inscritos · $teams equipos · $grouped en grupos';
  }

  @override
  String newTeamCount(int count, int size) {
    return 'Equipo nuevo · $count/$size';
  }

  @override
  String get createTeam => 'Crear equipo';

  @override
  String teamCreated(String team) {
    return 'Creado el $team';
  }

  @override
  String get teamConflict =>
      'Algún alumno ya está en un equipo o grupo. La lista se ha actualizado.';

  @override
  String get teamError => 'No se ha podido crear el equipo.';

  @override
  String get teamsEmpty => 'Todavía no hay equipos: créalos en Alumnos.';

  @override
  String get deleteTeam => 'Deshacer equipo';

  @override
  String deleteTeamConfirm(String team) {
    return '¿Deshacer el $team? Sus alumnos quedan libres.';
  }

  @override
  String get deleteTeamError => 'No se ha podido deshacer el equipo.';

  @override
  String get draftGhostTeam => 'Equipo fantasma';

  @override
  String draftGhostTeamHint(int size) {
    return 'Elige $size alumnos cualesquiera de la categoría: combaten pero no puntúan.';
  }

  @override
  String pickGhostTeam(int count, int size) {
    return 'Elegir alumnos · $count/$size';
  }

  @override
  String get settingsTitle => 'Ajustes de la cuenta';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsEmailVerified => 'Verificado';

  @override
  String get settingsEmailUnverified => 'Sin verificar';

  @override
  String get settingsChangeEmail => 'Cambiar email';

  @override
  String get changeEmailNew => 'Email nuevo';

  @override
  String get changeEmailSubmit => 'Enviar enlace';

  @override
  String changeEmailSent(String email) {
    return 'Hemos enviado un email a $email. Abre su enlace para terminar el cambio (caduca en 24 horas).';
  }

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageHint =>
      'También es el de los emails que te enviamos.';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsLanguageError => 'No se ha podido cambiar el idioma.';

  @override
  String get settingsProfiles => 'Perfiles';

  @override
  String get profileValidated => 'Validado';

  @override
  String get profilePendingValidation => 'Pendiente de validación';

  @override
  String profileTaxId(String taxId) {
    return 'CIF: $taxId';
  }

  @override
  String get profileAdd => 'Añadir perfil';

  @override
  String get profileAdded => 'Perfil añadido.';

  @override
  String get profileRemove => 'Quitar perfil';

  @override
  String profileRemoveConfirm(String profile) {
    return '¿Quitar el perfil $profile?';
  }

  @override
  String get profileRemoved => 'Perfil quitado.';

  @override
  String get removeAction => 'Quitar';

  @override
  String get profileLast => 'Tu cuenta necesita al menos un perfil.';

  @override
  String get profileCombination =>
      'Ese perfil no se puede combinar con los que ya tienes.';

  @override
  String get profileNeedsVerifiedEmail =>
      'Verifica tu email antes de añadir perfiles.';

  @override
  String get settingsSignInMethods => 'Métodos de acceso';

  @override
  String get signInPassword => 'Email y contraseña';

  @override
  String get signInGoogle => 'Google';

  @override
  String get googleUnlink => 'Desvincular';

  @override
  String get googleUnlinkConfirm =>
      '¿Desvincular tu cuenta de Google? Solo podrás entrar con email y contraseña.';

  @override
  String get googleUnlinked => 'Google desvinculado.';

  @override
  String get passwordRemove => 'Quitar contraseña';

  @override
  String get passwordRemoveConfirm =>
      'Solo podrás entrar con Google y se cerrarán todas tus sesiones, también esta. Para volver a tener contraseña, usa «¿Has olvidado la contraseña?».';

  @override
  String get lastSignInMethod =>
      'Es tu único método de acceso. Añade otro antes.';

  @override
  String get needsGoogle =>
      'Esta acción pide confirmar con Google, que llegará pronto a la app.';

  @override
  String get settingsData => 'Tus datos';

  @override
  String get settingsDataHint =>
      'Descarga una copia de los datos de tu cuenta (JSON).';

  @override
  String get settingsExport => 'Exportar mis datos';

  @override
  String get settingsDanger => 'Zona peligrosa';

  @override
  String get deleteAccount => 'Borrar cuenta';

  @override
  String get deleteAccountHint =>
      'Se borra definitivamente a los 30 días. Hasta entonces puedes recuperarla iniciando sesión.';

  @override
  String get deleteAccountTitle => '¿Borrar tu cuenta?';

  @override
  String get deleteAccountBody =>
      'Se cerrarán todas tus sesiones. La cuenta, con sus perfiles y datos, se borrará definitivamente a los 30 días. Hasta entonces puedes recuperarla iniciando sesión.';

  @override
  String get deleteOwnsEvents =>
      'Eres responsable de eventos. Cédelos a otra persona o bórralos antes de borrar tu cuenta.';

  @override
  String loginAccountDeleted(String date) {
    return 'Tu cuenta se borrará el $date. Inicia sesión antes para recuperarla.';
  }

  @override
  String get loginPasswordRemoved =>
      'Contraseña quitada y sesiones cerradas. Ya solo puedes entrar con Google.';

  @override
  String get reauthTitle => 'Confirma que eres tú';

  @override
  String get reauthBody => 'Escribe tu contraseña para continuar.';

  @override
  String get reauthSubmit => 'Confirmar';

  @override
  String get reauthFailed => 'Contraseña incorrecta.';

  @override
  String get settingsLogout => 'Cerrar sesión';

  @override
  String get confirmEmailChangeTitle => 'Cambio de email';

  @override
  String get confirmEmailChangeDone =>
      'Email cambiado. Se han cerrado todas las sesiones: inicia sesión con el email nuevo.';

  @override
  String get categoryIndividual => 'Individual';

  @override
  String categoryTeams(int size) {
    return 'Equipos de $size';
  }

  @override
  String get categoryAdd => 'Añadir categoría';

  @override
  String get categoryEdit => 'Editar categoría';

  @override
  String get categoryRemove => 'Quitar categoría';

  @override
  String get categoryNameLabel => 'Nombre';

  @override
  String get categoryMinAge => 'Desde';

  @override
  String get categoryMaxAge => 'Hasta';

  @override
  String get categoryByTeams => 'Por equipos';

  @override
  String get categoryTeamSize => 'Alumnos por equipo';

  @override
  String categoryGroupSize(int size) {
    return 'Grupos de $size';
  }

  @override
  String get categoryAgesInvalid =>
      'La edad mínima no puede ser mayor que la máxima.';

  @override
  String get categoriesInUse =>
      'Una categoría con grupos o equipos solo puede cambiar de nombre.';

  @override
  String get categoriesInvalid =>
      'Revisa las categorías: las edades no pueden solaparse.';

  @override
  String standingTeam(String team, String detail) {
    return '$team · $detail';
  }

  @override
  String get categoryAgeSuffix => 'años';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get categoryByAge => 'Automática por edad';

  @override
  String get importButton => 'Importar alumnos';

  @override
  String get importFormatTitle => 'Cómo debe ser la lista';

  @override
  String get importFormatBody =>
      'Una fila por alumno: nombre, apellidos, fecha de nacimiento (dd/mm/aaaa), estatura en cm (opcional) y categoría (opcional). Vale una o varias fotos, un CSV, un Excel, un TXT o el texto pegado.';

  @override
  String get importTemplate => 'Descargar plantilla';

  @override
  String get importPickPhotos => 'Elegir fotos';

  @override
  String get importPickFile => 'Elegir archivo';

  @override
  String get importPasteHint => 'O pega aquí la lista';

  @override
  String get importConsent =>
      'Confirmo que todos los alumnos de esta lista, y sus tutores si son menores, han aceptado inscribirse en este evento sin excepción, y que la lista se procesará con un servicio de IA externo (Anthropic) solo para leerla. Las imágenes y archivos no se guardan.';

  @override
  String get importRead => 'Leer lista';

  @override
  String get importReading => 'Leyendo la lista… puede tardar hasta un minuto.';

  @override
  String get importReadError =>
      'No se ha podido leer la lista. Prueba con una foto más nítida o con un archivo.';

  @override
  String get importTooMany =>
      'Has leído muchas listas en la última hora. Prueba más tarde.';

  @override
  String importInvalidFiles(int max) {
    return 'Solo fotos (JPG, PNG, WebP), CSV, TXT o Excel: hasta $max archivos de 10 MB.';
  }

  @override
  String importSummary(int total, int errors, int warnings) {
    return '$total alumnos · $errors con errores · $warnings para revisar';
  }

  @override
  String importRegister(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Inscribir $count alumnos',
      one: 'Inscribir 1 alumno',
    );
    return '$_temp0';
  }

  @override
  String importRegistered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alumnos inscritos',
      one: '1 alumno inscrito',
    );
    return '$_temp0';
  }

  @override
  String get importRegisterRefused =>
      'No se ha inscrito nadie: revisa las filas marcadas.';

  @override
  String get importAddRow => 'Añadir alumno';

  @override
  String get importEditRow => 'Editar alumno';

  @override
  String get importRemoveRow => 'Quitar de la lista';

  @override
  String get importStartOver => 'Volver a subir';

  @override
  String get importEmpty => 'La lista no tiene alumnos.';

  @override
  String importUseCategory(String name) {
    return 'Usar $name';
  }

  @override
  String get fieldFirstName => 'el nombre';

  @override
  String get fieldLastName => 'los apellidos';

  @override
  String get fieldBirthDate => 'la fecha de nacimiento';

  @override
  String get fieldHeight => 'la estatura';

  @override
  String get fieldCategory => 'la categoría';

  @override
  String issueMissing(String field) {
    return 'Falta $field';
  }

  @override
  String issueTooLong(String field) {
    return 'Demasiado largo: $field';
  }

  @override
  String issueInvalidDate(String text) {
    return 'Fecha no válida: $text';
  }

  @override
  String get issueFutureDate =>
      'La fecha de nacimiento tiene que ser anterior a hoy';

  @override
  String issueHeight(String cm) {
    return 'Estatura $cm: tiene que estar entre 50 y 250 cm';
  }

  @override
  String issueNoCategory(String age) {
    return 'Ninguna categoría del evento es para $age años';
  }

  @override
  String issueUnknownCategory(String name) {
    return 'La categoría «$name» no existe en el evento';
  }

  @override
  String get issueChosenCategoryGone => 'La categoría elegida ya no existe';

  @override
  String issueCategoryMismatch(String written, String byAge) {
    return 'Indica $written, pero por su edad le corresponde $byAge';
  }

  @override
  String issueDuplicate(String row) {
    return 'Repetido en la lista (fila $row)';
  }

  @override
  String get issueAlreadyRegistered => 'Ya está inscrito en el evento';

  @override
  String issueUnsure(String field) {
    return 'Revisa $field: no se leyó con seguridad';
  }

  @override
  String get legalSection => 'Legal';

  @override
  String get legalPrivacy => 'Política de privacidad';

  @override
  String get legalTerms => 'Términos de uso';

  @override
  String get legalCookies => 'Política de cookies';

  @override
  String get legalNotice => 'Aviso legal';

  @override
  String get legalPrivacyShort => 'Privacidad';

  @override
  String get legalTermsShort => 'Términos';

  @override
  String get legalCookiesShort => 'Cookies';

  @override
  String get legalLicenses => 'Licencias';

  @override
  String get legalPrivacyLink => 'política de privacidad';

  @override
  String get legalTermsLink => 'términos de uso';

  @override
  String get legalNotFound => 'Esta página legal no existe.';

  @override
  String get registerLegalOutdated =>
      'Los términos de uso o la política de privacidad han cambiado. Revísalos y vuelve a aceptarlos.';

  @override
  String participantPrivacyNotice(String privacy) {
    return 'Los datos del alumno se tratan según la $privacy.';
  }

  @override
  String importPrivacyNotice(String privacy) {
    return 'Los datos de los alumnos se tratan según la $privacy.';
  }

  @override
  String serverCurrent(String name) {
    return 'Servidor: $name';
  }

  @override
  String get serverChange => 'Cambiar';

  @override
  String get serverDialogTitle => 'Elegir servidor';

  @override
  String get serverHall => 'Pabellón';

  @override
  String get serverInternet => 'Internet';

  @override
  String get serverOther => 'Otra URL';

  @override
  String get serverUrlLabel => 'URL del servidor';

  @override
  String get serverUrlHint => 'https://servidor.ejemplo';

  @override
  String get serverUrlInvalid =>
      'Escribe una URL que empiece por http:// o https:// y tenga servidor.';

  @override
  String get serverUrlCleartext =>
      'Sin https la app solo llega al pabellón (192.168.137.1): con esta URL no conectará.';

  @override
  String get serverUse => 'Usar';

  @override
  String get syncConnected => 'Conectado';

  @override
  String get syncOffline => 'Sin conexión';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acciones pendientes',
      one: '1 acción pendiente',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acciones rechazadas',
      one: '1 acción rechazada',
    );
    return '$_temp0';
  }

  @override
  String get syncRejectedShow => 'Ver';

  @override
  String get syncRejectedTitle => 'Acciones rechazadas';

  @override
  String get syncRejectedBody =>
      'El servidor no aceptó estas acciones y no cuentan en el combate. Avisa al club si hace falta.';

  @override
  String get syncRejectedDismiss => 'Quitar de la lista';

  @override
  String get close => 'Cerrar';

  @override
  String get matOfflineBoard =>
      'Sin conexión: tablero guardado en el móvil. Sin recomendado; puedes empezar un pendiente si no hay otro en curso.';

  @override
  String get matInReview => 'En revisión del club';

  @override
  String get refusalFinished => 'El combate ya está finalizado.';

  @override
  String get refusalOver => 'El combate ya ha acabado.';

  @override
  String get refusalRunning => 'El reloj ya está en marcha.';

  @override
  String get refusalNotRunning => 'El reloj no está en marcha.';

  @override
  String get refusalNothingToUndo => 'No hay nada que deshacer.';

  @override
  String get refusalNotOver => 'El combate todavía no ha acabado.';

  @override
  String get refusalNotForAge =>
      'El aviso de una mano solo es para alumnos de 4 a 7 años.';

  @override
  String get refusalInReview => 'El combate está en revisión del club.';

  @override
  String get refusalMatBusy => 'Hay otro combate en curso en este tapiz.';

  @override
  String get reviewBannerReferee =>
      'En revisión del club: este combate queda parado hasta que el club aplique o descarte las acciones de este móvil.';

  @override
  String get reviewTitle => 'Acciones del móvil en revisión';

  @override
  String get reviewReasonKnownEvents =>
      'Otro dispositivo escribió en el combate mientras el móvil estaba sin conexión.';

  @override
  String get reviewReasonRules =>
      'Las reglas del marcador no permitían una acción del móvil.';

  @override
  String get reviewReasonAge =>
      'Aviso de una mano a quien no tiene de 4 a 7 años.';

  @override
  String get reviewReasonMatBusy => 'Había otro combate en curso en el tapiz.';

  @override
  String get reviewReasonFighterBusy =>
      'Un alumno estaba combatiendo en otro tapiz.';

  @override
  String get reviewReasonUnknown => 'Choque con el servidor.';

  @override
  String get reviewApply => 'Aplicar';

  @override
  String get reviewDiscard => 'Descartar';

  @override
  String get reviewApplyConfirm =>
      'Se añaden las acciones del móvil en orden y con su hora. Las que las reglas no permitan se saltan.';

  @override
  String get reviewDiscardConfirm =>
      'Las acciones del móvil no cuentan en el combate. Quedan guardadas en el registro.';

  @override
  String reviewApplied(int applied, int skipped) {
    return 'Aplicadas: $applied · Saltadas: $skipped';
  }

  @override
  String get reviewDiscarded => 'Acciones descartadas.';

  @override
  String matsInReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count combates en revisión',
      one: '1 combate en revisión',
    );
    return '$_temp0';
  }

  @override
  String logoutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tienes $count acciones sin enviar; si sales se perderán.',
      one: 'Tienes 1 acción sin enviar; si sales se perderá.',
    );
    return '$_temp0';
  }

  @override
  String get refusalNotStarted => 'Inicia el tiempo antes de puntuar.';

  @override
  String undoneWhat(String what) {
    return 'Deshecho: $what';
  }

  @override
  String whatPoint(String corner) {
    return '+1 $corner';
  }

  @override
  String whatWarning(String corner) {
    return 'advertencia $corner';
  }

  @override
  String whatOneHand(String corner) {
    return 'una mano $corner';
  }

  @override
  String whatDisqualification(String corner) {
    return 'descalificación $corner';
  }

  @override
  String get winner => 'Ganador';

  @override
  String get draw => 'Empate';

  @override
  String get matLocked => 'No se puede abrir todavía';

  @override
  String get needsGuardian => 'Falta tutor';

  @override
  String settingsRemoveMatConfirm(int number) {
    return 'Se quita el Tapiz $number; su árbitro deja de estar asignado.';
  }

  @override
  String get draftTitle => 'Grupo nuevo';

  @override
  String get draftReady => 'Completo';

  @override
  String draftMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltan $count',
      one: 'Falta 1',
    );
    return '$_temp0';
  }

  @override
  String draftSlot(int number) {
    return 'Hueco $number';
  }

  @override
  String ghostOf(String name) {
    return '$name (fantasma)';
  }

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsAppearanceHint =>
      'Automático sigue al modo claro u oscuro del dispositivo. Se guarda solo en este dispositivo.';

  @override
  String get themeSystem => 'Automático';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get refusalStale =>
      'El combate ha cambiado en otro dispositivo. Revisa el marcador y vuelve a pulsar.';

  @override
  String get accountSuspended =>
      'Esta cuenta está suspendida. Si crees que es un error, escribe al contacto de privacidad que aparece en las páginas legales.';

  @override
  String backTo(String place) {
    return 'Volver a $place';
  }

  @override
  String get reasonApplyWarning => 'Poner advertencia';

  @override
  String get reasonApplyDisqualify => 'Descalificar';

  @override
  String get accountMenu => 'Mi cuenta';

  @override
  String get back => 'Volver';
}
