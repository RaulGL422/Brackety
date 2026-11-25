// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'core_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class CoreLocalizationsEs extends CoreLocalizations {
  CoreLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String appVersion(String version) {
    return 'Versión $version';
  }

  @override
  String appVersionBuild(String version, String build) {
    return 'Versión $version ($build)';
  }

  @override
  String get connectionTitle => 'Conexión';

  @override
  String get connectionServer => 'Servidor';

  @override
  String get connectionStatusOk => 'Conectado';

  @override
  String get connectionStatusError => 'Sin conexión con el servidor';

  @override
  String connectionServerToday(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Fecha del servidor: $dateString';
  }

  @override
  String get debugNoScenario => 'sin escenario';

  @override
  String debugSimulatedDate(String date) {
    return '$date (simulada)';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get licenses => 'Licencias de software';

  @override
  String get closeNotice => 'Cerrar aviso';

  @override
  String get cancel => 'Cancelar';

  @override
  String get saved => 'Guardado';

  @override
  String get save => 'Guardar';

  @override
  String get close => 'Cerrar';

  @override
  String get loadError => 'No se ha podido cargar. Comprueba la conexión.';

  @override
  String get updateTitle => 'Hay una versión nueva de Brackety';

  @override
  String get updateBody => 'Actualiza para seguir. Tarda unos segundos.';

  @override
  String get updateButton => 'Actualizar';

  @override
  String get updateWaiting =>
      'Hay una versión nueva: podrás actualizar en cuanto se envíen las acciones pendientes.';

  @override
  String get changelogTitle => 'Cambios';

  @override
  String get changelogMenu => 'Cambios (debug)';

  @override
  String get changelogSearch => 'Buscar en los cambios';

  @override
  String get changelogClear => 'Borrar la búsqueda';

  @override
  String changelogCount(int shown, int total) {
    return '$shown de $total cambios';
  }

  @override
  String get changelogNoMatch => 'Ningún cambio tiene todas esas palabras.';

  @override
  String get changelogMissing =>
      'La lista de cambios solo viene en las compilaciones de debug.';
}
