import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/state/account_controller.dart';
import '../features/auth/state/session_controller.dart';
import '../features/auth/ui/check_email_screen.dart';
import '../features/auth/ui/confirm_email_change_screen.dart';
import '../features/auth/ui/forgot_password_screen.dart';
import '../features/auth/ui/legal_update_screen.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/register_screen.dart';
import '../features/auth/ui/reset_password_screen.dart';
import '../features/auth/ui/settings_screen.dart';
import '../features/auth/ui/verify_email_screen.dart';
import '../features/club/ui/club_panel_screen.dart';
import '../features/control/mat_groups_screen.dart';
import '../features/events/ui/events_screen.dart';
import '../features/exports/ui/export_screen.dart';
import '../features/grouping/ui/categories_screen.dart';
import '../features/grouping/ui/group_builder_screen.dart';
import '../features/grouping/ui/team_category_screen.dart';
import '../features/importing/ui/import_screen.dart';
import '../features/league/ui/league_screen.dart';
import '../features/legal/ui/legal_page_screen.dart';
import '../features/mat/ui/mat_board_screen.dart';
import '../features/scoreboard/ui/match_watch_screen.dart';
import '../features/scoreboard/ui/scoreboard_screen.dart';
import '../features/staff/ui/invitation_screen.dart';
import '../features/staff/ui/qr_sign_in_screen.dart';
import '../l10n/gen/app_localizations.dart';

// Email links land here whatever the session (the server builds them, docs/modulos/auth.md).
const _anySession = {
  '/connection',
  '/verify-email',
  '/reset-password',
  '/forgot-password',
  '/confirm-email-change',
  // A club's staff QR: signs in by itself, or asks first when another account is signed in.
  '/qr',
};
// Legal pages too: the sign-up links to them and the web shows them to anyone.
const _anySessionPrefix = '/legal/';
const _signedOutOnly = {'/login', '/register', '/register/sent'};

/// Where a reload or a link meant to go, kept through the session check (and the sign-in when it
/// is needed): only a path of this app, never another site.
String? _target(Uri uri) {
  final from = uri.queryParameters['from'];
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  return from;
}

/// Where [uri] leads in the end: the sign-in and the loading screen only pass on their own `from`
/// (also when an old address piled them up), so a reload never wraps one in another (Raul,
/// 2026-11-25: «/login?from=/login?from=…»).
Uri _destination(Uri uri) {
  var at = uri;
  while (at.path == '/login' || at.path == '/loading') {
    at = Uri.parse(_target(at) ?? '/');
  }
  return at;
}

/// Where [location] leads as the `from` of a detour, unless it is the app's home: nothing to come
/// back to.
String _via(String detour, Uri location) {
  final at = _destination(location).toString();
  return at == '/' ? detour : '$detour?from=${Uri.encodeQueryComponent(at)}';
}

/// Without a session the sign-in and sign-up pages stay (a piled-up sign-in comes down to one
/// `from`); the loading screen goes on to the page it was going to if it is one of them, and
/// anything else asks to sign in first.
String? _signedOut(String at, Uri uri) {
  if (at == '/login') {
    final from = _target(uri);
    final piled =
        from != null && {'/login', '/loading'}.contains(Uri.parse(from).path);
    return piled ? _via('/login', uri) : null;
  }
  if (_signedOutOnly.contains(at)) return null;
  final to = _destination(uri);
  if (at == '/loading' && _signedOutOnly.contains(to.path)) {
    return to.toString();
  }
  return _via('/login', uri);
}

const _legalUpdate = '/legal-update';

final routerProvider = Provider<GoRouter>((ref) {
  String? signedIn(String at, Uri uri) {
    final pending =
        ref.read(accountProvider).value?.pendingConsents.isNotEmpty ?? false;
    if (pending) {
      // Back afterwards to where the person was going, not to the sign-in on the way.
      return at == _legalUpdate ? null : _via(_legalUpdate, uri);
    }
    if (at == _legalUpdate) return _target(uri) ?? '/';
    if (_signedOutOnly.contains(at) || at == '/loading') {
      // A sign-up left behind is no place for a signed-in account: home instead.
      final to = _destination(uri);
      return _signedOutOnly.contains(to.path) ? '/' : to.toString();
    }
    return null;
  }

  // On the web the address follows every screen, also those opened with push: a reload comes
  // back to the same screen (a referee to the scoreboard), not to the start.
  GoRouter.optionURLReflectsImperativeAPIs = true;

  // The router asks for the session on every navigation; this tells it when to ask again.
  final sessionChanged = ValueNotifier(0);
  ref.listen(
    sessionProvider.select((s) => s.status),
    (_, _) => sessionChanged.value++,
  );
  // Changed legal texts to accept again keep the account on their screen until it does.
  ref.listen(
    accountProvider.select((a) => a.value?.pendingConsents.isNotEmpty ?? false),
    (_, _) => sessionChanged.value++,
  );

  final router = GoRouter(
    refreshListenable: sessionChanged,
    redirect: (context, state) {
      final at = state.matchedLocation;
      // Support and debug only: a customer typing the address goes home.
      if (at == '/connection' && !ref.read(connectionAllowedProvider)) {
        return '/';
      }
      if (_anySession.contains(at) || at.startsWith(_anySessionPrefix)) {
        return null;
      }
      return switch (ref.read(sessionProvider).status) {
        SessionStatus.restoring =>
          at == '/loading' ? null : _via('/loading', state.uri),
        SessionStatus.signedOut => _signedOut(at, state.uri),
        SessionStatus.signedIn => signedIn(at, state.uri),
      };
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: _legalUpdate, builder: (_, _) => const LegalUpdateScreen()),
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
      GoRoute(
        path: '/legal/:type',
        builder: (_, state) =>
            LegalPageScreen(slug: state.pathParameters['type']!),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      // From the invitation email; signed out, the sign-in comes back here.
      GoRoute(
        path: '/invitation',
        builder: (_, state) =>
            InvitationScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: '/qr',
        builder: (_, state) =>
            QrSignInScreen(code: state.uri.queryParameters['code']),
      ),
      GoRoute(
        path: '/changelog',
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: Text(CoreLocalizations.of(context).changelogTitle),
          ),
          body: const ChangelogView(),
        ),
      ),
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
          teamSize: int.tryParse(state.uri.queryParameters['teamSize'] ?? ''),
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
        path: '/events/:eventId/club/export',
        builder: (_, state) =>
            ExportScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/events/:eventId/club/import',
        builder: (_, state) =>
            ImportScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/leagues/:eventId',
        builder: (_, state) => LeagueScreen(
          key: ValueKey(state.pathParameters['eventId']),
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      ...clubPanelRoutes(),
      GoRoute(
        path: '/events/:eventId/mat-groups',
        builder: (_, state) =>
            MatGroupsScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/club/mats/:matId',
        builder: (_, state) => MatBoardScreen(
          matId: state.pathParameters['matId']!,
          readOnly: true,
          matNumber: int.tryParse(state.uri.queryParameters['number'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/club/matches/:matchId',
        builder: (_, state) =>
            MatchWatchScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/mats/:matId',
        builder: (_, state) => MatBoardScreen(
          matId: state.pathParameters['matId']!,
          matNumber: int.tryParse(state.uri.queryParameters['number'] ?? ''),
        ),
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
