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
  String get loginTitle => 'Entrar';

  @override
  String get loginUsername => 'Usuario';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginSubmit => 'Entrar';

  @override
  String get loginInvalid => 'Usuario o contraseña incorrectos.';

  @override
  String get loginLocked => 'Demasiados intentos. Espera unos minutos.';

  @override
  String get loginNoServer => 'No hay conexión con el servidor.';

  @override
  String get loginDemoAccounts => 'Cuentas de prueba (solo en desarrollo)';

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
