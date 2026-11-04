import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';

class ServerInfo {
  const ServerInfo({required this.name, required this.today});

  factory ServerInfo.fromJson(Map<String, dynamic> json) => ServerInfo(
    name: json['name'] as String,
    today: DateTime.parse(json['today'] as String),
  );

  final String name;

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
