// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Brackety Admin';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navConnection => 'Conexión';

  @override
  String get dashboardTitle => 'Panel de superadmin';

  @override
  String get dashboardSubtitle => 'Gestión global de la plataforma.';

  @override
  String get navDesignSystem => 'Diseño';

  @override
  String get dsTitle => 'Sistema de diseño';

  @override
  String get dsIntro =>
      'Solo en builds debug. Todo lo de abajo usa el tema real con la paleta y el modo elegidos.';

  @override
  String get dsPalette => 'Paleta';

  @override
  String get dsPaletteElectric => 'Eléctrico';

  @override
  String get dsPaletteFire => 'Fuego';

  @override
  String get dsPaletteNight => 'Noche';

  @override
  String get dsMode => 'Modo';

  @override
  String get dsModeLight => 'Claro';

  @override
  String get dsModeDark => 'Oscuro';

  @override
  String dsTextScale(int percent) {
    return 'Texto al $percent %';
  }

  @override
  String get dsColors => 'Colores';

  @override
  String get dsStatusColors => 'Estados';

  @override
  String get dsCompetitorColors => 'Colores de competidor';

  @override
  String get dsContrastHint =>
      'AA: texto normal (≥ 4,5). AA grande: solo texto grande (≥ 3). ✗: no usar para texto.';

  @override
  String get dsContrastLarge => 'AA grande';

  @override
  String get dsTypography => 'Tipografía';

  @override
  String get dsTypeSample => 'Liga de ejemplo 2027 · 0123456789';

  @override
  String get dsSpacing => 'Espaciado';

  @override
  String get dsRadius => 'Radios';

  @override
  String get dsComponents => 'Componentes';

  @override
  String get dsSave => 'Guardar';

  @override
  String get dsTonal => 'Inscribirse';

  @override
  String get dsCancel => 'Cancelar';

  @override
  String get dsMore => 'Ver más';

  @override
  String get dsDisabled => 'Desactivado';

  @override
  String get dsFieldLabel => 'Nombre del club';

  @override
  String get dsFieldHint => 'Club Deportivo Ejemplo';

  @override
  String get dsFieldError => 'Campo obligatorio';

  @override
  String get dsNotifications => 'Notificaciones';

  @override
  String get dsCategoryKids => 'Infantil';

  @override
  String get dsCategoryCadet => 'Cadete';

  @override
  String get dsCategorySenior => 'Sénior';

  @override
  String get dsCardTitle => 'Liga de ejemplo 2027';

  @override
  String get dsCardSubtitle => '3 fases · 120 inscritos';

  @override
  String get dsPaid => 'Pagado';

  @override
  String get dsPending => 'Pendiente';

  @override
  String get dsRejected => 'Rechazado';

  @override
  String get dsSamples => 'Ejemplos';

  @override
  String get dsScoreboard => 'Marcador';

  @override
  String get dsColorA => 'Color A';

  @override
  String get dsColorB => 'Color B';

  @override
  String dsPenalties(int count) {
    return 'Amonestaciones: $count';
  }

  @override
  String get dsStandings => 'Clasificación';

  @override
  String get dsPosition => 'Pos.';

  @override
  String get dsCompetitor => 'Competidor';

  @override
  String get dsWins => 'V';

  @override
  String get dsLosses => 'D';

  @override
  String get dsPoints => 'Pts';
}
