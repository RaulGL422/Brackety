import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/up_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../state/league_providers.dart';
import 'league_tab.dart';

/// The league as the club enters it: its phases (each opens its own panel), the next phase, the
/// standings over all of them and the podiums. [eventId]: any phase of it, the way into its API.
class LeagueScreen extends ConsumerWidget {
  const LeagueScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(leagueProvider(eventId)).value?.name;
    return Scaffold(
      appBar: AppBar(
        leading: UpButton(label: l10n.eventsTitle, fallback: '/'),
        leadingWidth: UpButton.leadingWidth(context),
        title: Text(name ?? l10n.clubLeague),
      ),
      body: LeagueTab(eventId: eventId),
    );
  }
}
