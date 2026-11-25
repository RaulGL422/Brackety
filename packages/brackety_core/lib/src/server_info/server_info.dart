import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';

class ServerInfo {
  const ServerInfo({
    required this.name,
    required this.today,
    this.version = '',
    this.commit = '',
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) => ServerInfo(
    name: json['name'] as String,
    today: DateTime.parse(json['today'] as String),
    version: json['version'] as String? ?? '',
    commit: json['commit'] as String? ?? '',
  );

  final String name;

  /// The release the server runs (0.8.2, 0.8.2-dev.89) and its commit; empty when not built with them.
  final String version;
  final String commit;

  /// The server's "today", which a local scenario run may have shifted.
  final DateTime today;
}

// No automatic retry: the connection screen must show a failure at once and retry on demand.
final serverInfoProvider = FutureProvider.autoDispose<ServerInfo>(
  retry: (_, _) => null,
  (ref) async {
    final response = await ref
        .watch(dioProvider)
        .get<Map<String, dynamic>>('/api/v1/info');
    return ServerInfo.fromJson(response.data!);
  },
);
