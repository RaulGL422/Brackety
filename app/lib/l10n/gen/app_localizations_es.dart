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
  String get comingSoon => 'Disponible pronto';

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
}
