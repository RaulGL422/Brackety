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
  String get registerAccept =>
      'Acepto los términos de uso y la política de privacidad.';

  @override
  String get registerAcceptRequired => 'Debes aceptarlos para crear la cuenta.';

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
  String draftCount(int count) {
    return '$count/4';
  }

  @override
  String get draftGhost => 'Competidor fantasma';

  @override
  String get draftGhostHint => 'Elige al fantasma: combate pero no puntúa.';

  @override
  String get draftAddGroup => 'Añadir grupo';

  @override
  String get draftRemoveGroup => 'Quitar grupo';

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
  String groupsCreatedBody(String groups, int mat) {
    return '$groups → Tapiz $mat';
  }

  @override
  String get groupsConflict =>
      'Algún alumno ya está en un grupo. La lista se ha actualizado.';

  @override
  String get groupsError => 'No se han podido crear los grupos.';

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
    return 'Grupo $number · $category años';
  }

  @override
  String get matRecommended => 'Siguiente recomendado';

  @override
  String get matInProgress => 'En curso';

  @override
  String get matPending => 'Pendientes';

  @override
  String get matFinished => 'Terminados';

  @override
  String get matWaiting => 'Un luchador está combatiendo en otro tapiz';

  @override
  String get matNoneAvailable => 'Ningún combate puede empezar ahora.';

  @override
  String get versus => 'vs';

  @override
  String scoreboardTitle(int mat, int group) {
    return 'Tapiz $mat · Grupo $group';
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
    return '$action · $fighter';
  }

  @override
  String get reasonLabel => 'Motivo (obligatorio)';

  @override
  String get reasonConfirm => '¿Seguro? Queda registrado.';

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
  String get clubStandings => 'Puntuaciones';

  @override
  String get clubMats => 'Tapices';

  @override
  String get clubParticipants => 'Inscripciones';

  @override
  String get clubSettings => 'Configuración';

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
    return '$groups grupos · $pending combates pendientes';
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
  String get settingsMaxGroups => 'Grupos por tapiz a la vez';

  @override
  String get settingsMaxGroupsHint => '1 = sin multigrupo';

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
  String get exportCsv => 'Exportar CSV';

  @override
  String get exportStandings => 'Clasificación';

  @override
  String get exportMatches => 'Combates';

  @override
  String get exportTimeline => 'Línea de tiempo';

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
  String get individualGroupHint =>
      'Para quien se quede sin equipo: grupos de 4 alumnos.';

  @override
  String categoryTeamCounts(
    int participants,
    int inTeams,
    int teams,
    int grouped,
  ) {
    return '$participants inscritos · $inTeams en $teams equipos · $grouped en grupos';
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
}
