// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'core_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class CoreLocalizationsEs extends CoreLocalizations {
  CoreLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get retry => 'Reintentar';
}
