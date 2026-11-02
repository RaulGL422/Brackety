import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/state/session_controller.dart';
import '../features/auth/ui/check_email_screen.dart';
import '../features/auth/ui/confirm_email_change_screen.dart';
import '../features/auth/ui/forgot_password_screen.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/register_screen.dart';
import '../features/auth/ui/reset_password_screen.dart';
import '../features/auth/ui/settings_screen.dart';
import '../features/auth/ui/verify_email_screen.dart';
import '../features/club/ui/club_panel_screen.dart';
import '../features/events/ui/events_screen.dart';
import '../features/grouping/ui/categories_screen.dart';
import '../features/grouping/ui/group_builder_screen.dart';
import '../features/grouping/ui/team_category_screen.dart';
import '../features/mat/ui/mat_board_screen.dart';
import '../features/scoreboard/ui/match_watch_screen.dart';
import '../features/scoreboard/ui/scoreboard_screen.dart';
import '../l10n/gen/app_localizations.dart';

// Email links land here whatever the session (the server builds them, docs/modulos/auth.md).
const _anySession = {
  '/connection',
  '/verify-email',
  '/reset-password',
  '/forgot-password',
  '/confirm-email-change',
};
const _signedOutOnly = {'/login', '/register', '/register/sent'};

final routerProvider = Provider<GoRouter>((ref) {
  // The router asks for the session on every navigation; this tells it when to ask again.
  final sessionChanged = ValueNotifier(0);
  ref.listen(
    sessionProvider.select((s) => s.status),
    (_, _) => sessionChanged.value++,
  );

  final router = GoRouter(
    refreshListenable: sessionChanged,
    redirect: (context, state) {
      final at = state.matchedLocation;
      if (_anySession.contains(at)) return null;
      return switch (ref.read(sessionProvider).status) {
        SessionStatus.restoring => at == '/loading' ? null : '/loading',
        SessionStatus.signedOut =>
          _signedOutOnly.contains(at) ? null : '/login',
        SessionStatus.signedIn =>
          _signedOutOnly.contains(at) || at == '/loading' ? '/' : null,
      };
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          passwordChanged:
              state.uri.queryParameters['passwordChanged'] == 'true',
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
        routes: [
          GoRoute(
            path: 'sent',
            builder: (_, state) =>
                CheckEmailScreen(email: state.extra as String?),
          ),
        ],
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) =>
            VerifyEmailScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) =>
            ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: '/confirm-email-change',
        builder: (_, state) =>
            ConfirmEmailChangeScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
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
        path: '/events/:eventId/categories/:categoryId/teams',
        builder: (_, state) => TeamCategoryScreen(
          eventId: state.pathParameters['eventId']!,
          categoryId: state.pathParameters['categoryId']!,
          categoryName: state.uri.queryParameters['name'] ?? '',
          teamSize: int.tryParse(state.uri.queryParameters['size'] ?? '') ?? 3,
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
