import '../../../l10n/gen/app_localizations.dart';
import '../data/server_choice.dart';

String serverOptionName(AppLocalizations l10n, ServerOption option) =>
    switch (option) {
      ServerOption.hall => l10n.serverHall,
      ServerOption.internet => l10n.serverInternet,
      ServerOption.other => l10n.serverOther,
    };
