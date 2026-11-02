import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/club/ui/club_panel_screen.dart';
import '../features/events/ui/events_screen.dart';
import '../features/grouping/ui/categories_screen.dart';
import '../features/grouping/ui/group_builder_screen.dart';
import '../features/mat/ui/mat_board_screen.dart';
import '../features/scoreboard/ui/match_watch_screen.dart';
import '../features/scoreboard/ui/scoreboard_screen.dart';
import '../features/session/state/session_controller.dart';
import '../features/session/ui/login_screen.dart';
import '../l10n/gen/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // The router asks for the session on every navigation; this tells it when to ask again.
  final sessionChanged = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => sessionChanged.value++);

  final router = GoRouter(
    refreshListenable: sessionChanged,
    redirect: (context, state) {
      final status = ref.read(sessionProvider).status;
      final at = state.matchedLocation;
      if (at == '/connection') return null;
      return switch (status) {
        SessionStatus.restoring => at == '/loading' ? null : '/loading',
        SessionStatus.signedOut => at == '/login' ? null : '/login',
        SessionStatus.signedIn =>
          at == '/login' || at == '/loading' ? '/' : null,
      };
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/connection',
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).navConnection),
          ),
          body: const ConnectionScreen(),
        ),
      ),
      GoRoute(path: '/', builder: (_, _) => const EventsScreen()),
      GoRoute(
        path: '/events/:eventId/categories',
        builder: (_, state) =>
            CategoriesScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/events/:eventId/categories/:categoryId',
        builder: (_, state) => GroupBuilderScreen(
          eventId: state.pathParameters['eventId']!,
          categoryId: state.pathParameters['categoryId']!,
          categoryName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/events/:eventId/club',
        builder: (_, state) =>
            ClubPanelScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/club/mats/:matId',
        builder: (_, state) => MatBoardScreen(
          matId: state.pathParameters['matId']!,
          readOnly: true,
        ),
      ),
      GoRoute(
        path: '/club/matches/:matchId',
        builder: (_, state) =>
            MatchWatchScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/mats/:matId',
        builder: (_, state) =>
            MatBoardScreen(matId: state.pathParameters['matId']!),
      ),
      GoRoute(
        path: '/matches/:matchId',
        builder: (_, state) =>
            ScoreboardScreen(matchId: state.pathParameters['matchId']!),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    sessionChanged.dispose();
  });
  return router;
});
