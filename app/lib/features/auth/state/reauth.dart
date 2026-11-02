import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_api.dart';
import '../data/api_error.dart';
import 'session_controller.dart';

/// Asks the user to prove it is them (the password dialog, which calls [Reauth.confirmPassword]).
/// Returns false when they cancel.
typedef ProveIdentity = Future<bool> Function();

/// The user closed the password dialog: the action is simply not done.
class ReauthCancelled implements Exception {
  const ReauthCancelled();
}

/// The account has no password and the app cannot reauthenticate with Google yet.
class ReauthNeedsGoogle implements Exception {
  const ReauthNeedsGoogle();
}

/// A new one on every sign-in or sign-out, so a token never outlives its session.
final reauthProvider = Provider<Reauth>((ref) {
  ref.watch(sessionProvider.select((s) => s.status));
  return Reauth(ref.watch(accountApiProvider));
});

/// Keeps the 5-minute reauth token in memory, so several sensitive actions in a row ask for the
/// password once.
class Reauth {
  Reauth(this._api, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final AccountApi _api;
  final DateTime Function() _now;

  // Renewed a little early: a token that expires on the way gets a 403 and a second dialog.
  static const _margin = Duration(seconds: 15);

  String? _token;
  DateTime? _expiresAt;

  String? get _validToken {
    final expiresAt = _expiresAt;
    if (expiresAt == null || !_now().isBefore(expiresAt)) return null;
    return _token;
  }

  /// Throws the [DioException] of the server: 403 `REAUTH_FAILED` for a wrong password, 429 locked.
  Future<void> confirmPassword(String password) async {
    final reauth = await _api.reauth(password);
    _token = reauth.token;
    _expiresAt = _now().add(reauth.expiresIn - _margin);
  }

  /// Runs [action] with a live token, asking via [prove] when there is none. If the server says
  /// the token no longer counts (its sessions were closed), asks once more and repeats it once.
  Future<T> run<T>(
    Future<T> Function(String token) action,
    ProveIdentity prove,
  ) async {
    var retried = false;
    while (true) {
      final token = _validToken ?? await _prove(prove);
      try {
        return await action(token);
      } on DioException catch (e) {
        if (retried || ApiError.from(e).code != 'REAUTH_REQUIRED') rethrow;
        retried = true;
        _forget();
      }
    }
  }

  Future<String> _prove(ProveIdentity prove) async {
    if (!await prove()) throw const ReauthCancelled();
    final token = _validToken;
    if (token == null) throw const ReauthCancelled();
    return token;
  }

  void _forget() {
    _token = null;
    _expiresAt = null;
  }
}
