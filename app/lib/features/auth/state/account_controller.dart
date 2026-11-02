import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/download/file_download.dart';
import '../data/account.dart';
import '../data/account_api.dart';
import '../data/registration.dart';
import 'reauth.dart';
import 'session_controller.dart';

const appLanguages = ['es', 'en'];

/// The signed-in account (`GET /me`), or null while signed out. Loaded on every sign-in because
/// its language is the app's.
final accountProvider = AsyncNotifierProvider<AccountController, Account?>(
  AccountController.new,
  // Settings show the error with a retry button; a silent retry would hide it.
  retry: (_, _) => null,
);

/// The account's language while signed in (the one its emails use too); null = the device's.
final appLocaleProvider = Provider<Locale?>((ref) {
  final code = ref.watch(accountProvider.select((a) => a.value?.locale));
  return appLanguages.contains(code) ? Locale(code!) : null;
});

class AccountController extends AsyncNotifier<Account?> {
  AccountApi get _api => ref.read(accountApiProvider);

  @override
  Future<Account?> build() async {
    final signedIn = ref.watch(
      sessionProvider.select((s) => s.status == SessionStatus.signedIn),
    );
    // A verification from the email link changes the badge.
    ref.watch(sessionProvider.select((s) => s.emailVerified));
    if (!signedIn) return null;
    return ref.read(accountApiProvider).me();
  }

  /// Shows the new language at once and puts the old one back if the server refuses.
  Future<void> setLocale(String locale) async {
    final current = state.value;
    if (current == null || current.locale == locale) return;
    state = AsyncData(current.withLocale(locale));
    try {
      state = AsyncData(await _api.updateLocale(locale));
    } on DioException {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> addProfile(ProfileType type) async {
    try {
      await _api.addProfile(type);
    } on DioException catch (e) {
      // The 403 comes from the access token, which may predate a verification made on another
      // device: a fresh one settles it.
      if (e.response?.statusCode != 403 || state.value?.emailVerified != true) {
        rethrow;
      }
      await ref.read(sessionProvider.notifier).refresh();
      await _api.addProfile(type);
    }
    ref.invalidateSelf();
  }

  Future<void> removeProfile(ProfileType type) async {
    await _api.removeProfile(type);
    ref.invalidateSelf();
  }

  /// The server always answers 202, whether the address is free or not.
  Future<void> changeEmail(String newEmail, ProveIdentity prove) =>
      _sensitive((token) => _api.changeEmail(newEmail.trim(), token), prove);

  Future<void> exportData(ProveIdentity prove) async {
    final bytes = await _sensitive(_api.export, prove);
    await ref.read(saveFileProvider)(
      exportFileName(DateTime.now()),
      bytes,
      'application/json',
    );
  }

  /// Ends the session here too: the server has closed them all.
  Future<void> deleteAccount(ProveIdentity prove) async {
    final deletesOn = await _sensitive(_api.deleteAccount, prove);
    await ref
        .read(sessionProvider.notifier)
        .sessionsClosed(AccountDeletionScheduled(deletesOn));
  }

  Future<void> unlinkGoogle(ProveIdentity prove) async {
    await _sensitive(_api.unlinkGoogle, prove);
    ref.invalidateSelf();
  }

  Future<void> removePassword(ProveIdentity prove) async {
    await _sensitive(_api.removePassword, prove);
    await ref
        .read(sessionProvider.notifier)
        .sessionsClosed(const PasswordRemoved());
  }

  Future<T> _sensitive<T>(
    Future<T> Function(String token) action,
    ProveIdentity prove,
  ) async {
    if (state.value?.hasPassword == false) throw const ReauthNeedsGoogle();
    return ref.read(reauthProvider).run(action, prove);
  }
}
