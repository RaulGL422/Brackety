import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';
import '../server_info/build_info.dart';
import '../server_info/server_info.dart';

/// The release and commit this app was built from; empty outside the web images (local, Android).
final buildInfoProvider = Provider<({String version, String commit})>(
  (_) => (version: builtVersion, commit: builtCommit),
);

/// How often the app asks the server which release it runs (also when the app comes back).
const updateCheckEvery = Duration(minutes: 5);

/// True once the server runs another release than the one this app was built from: the web and
/// the api are deployed together, so a reload brings the matching app. Without a build version
/// (local, Android) it never asks.
final updateAvailableProvider = NotifierProvider<UpdateCheck, bool>(
  UpdateCheck.new,
);

class UpdateCheck extends Notifier<bool> {
  @override
  bool build() {
    if (ref.watch(buildInfoProvider).version.isEmpty) return false;
    final timer = Timer.periodic(updateCheckEvery, (_) => check());
    final lifecycle = AppLifecycleListener(onResume: check);
    ref.onDispose(() {
      timer.cancel();
      lifecycle.dispose();
    });
    Future.microtask(check);
    return false;
  }

  Future<void> check() async {
    if (state) return;
    try {
      final response = await ref
          .read(dioProvider)
          .get<Map<String, dynamic>>('/api/v1/info');
      final server = ServerInfo.fromJson(response.data!);
      if (ref.mounted) state = differs(ref.read(buildInfoProvider), server);
    } on DioException {
      // No connection now (a hall without Internet, a phone in a tunnel): asked again later.
    }
  }

  /// A commit is only compared when both sides know theirs.
  static bool differs(
    ({String version, String commit}) build,
    ServerInfo server,
  ) =>
      server.version.isNotEmpty &&
      (server.version != build.version ||
          (server.commit.isNotEmpty &&
              build.commit.isNotEmpty &&
              server.commit != build.commit));
}
