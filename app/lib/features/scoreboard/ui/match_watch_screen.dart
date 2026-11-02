import 'dart:async';

import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mat/data/mat_board.dart';
import '../../mat/ui/fighter_text.dart';
import '../data/match_view.dart';
import '../data/scoreboard_repository.dart';
import 'timeline_list.dart';

const _watchRefresh = Duration(seconds: 5);

final watchedMatchProvider = FutureProvider.autoDispose
    .family<MatchView, String>((ref, matchId) {
      final timer = Timer(_watchRefresh, ref.invalidateSelf);
      ref.onDispose(timer.cancel);
      return ref.watch(scoreboardRepositoryProvider).load(matchId);
    });

/// A match seen by the club: score and timeline, without controls.
class MatchWatchScreen extends ConsumerWidget {
  const MatchWatchScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = watchedMatchProvider(matchId);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.timeline)),
      body: AsyncView(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        data: (view) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  Text(switch (view.status) {
                    MatchStatus.pending => l10n.matchNotStarted,
                    MatchStatus.inProgress => l10n.matchLive,
                    MatchStatus.finished => l10n.matchFinished,
                  }, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    '${view.red.title(l10n)}  ${view.red.points} - '
                    '${view.blue.points}  ${view.blue.title(l10n)}',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: TimelineList(view: view)),
          ],
        ),
      ),
    );
  }
}
