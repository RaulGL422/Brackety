import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';

/// Only in the debug build (`--dart-define=BRACKETY_DEBUG=true`): the Scenarios tab exists there alone.
const debugEnvironment = bool.fromEnvironment('BRACKETY_DEBUG');

class Scenario {
  const Scenario({required this.name, required this.description});

  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
    name: json['name'] as String,
    description: json['description'] as String,
  );

  final String name;
  final String description;
}

class Snapshot {
  const Snapshot({required this.name, this.savedAt, this.scenario});

  factory Snapshot.fromJson(Map<String, dynamic> json) => Snapshot(
    name: json['name'] as String,
    savedAt: json['savedAt'] == null
        ? null
        : DateTime.parse(json['savedAt'] as String),
    scenario: json['scenario'] as String?,
  );

  final String name;
  final DateTime? savedAt;

  /// The scenario loaded when it was saved.
  final String? scenario;
}

/// The debug server's own API (docs/modulos/entornos.md): scenarios, simulated day and copies.
class DebugApi {
  DebugApi(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/admin/dev';

  Future<List<Scenario>> scenarios() async {
    final response = await _dio.get<List<dynamic>>('$_base/scenarios');
    return [
      for (final s in response.data!)
        Scenario.fromJson(s as Map<String, dynamic>),
    ];
  }

  /// Wipes everything. [today]: the simulated day, or null for the real one.
  Future<DebugStatus> load(String name, {DateTime? today}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/scenarios/$name/load',
      data: {'confirm': name, 'today': _day(today)},
    );
    return DebugStatus.fromJson(response.data!);
  }

  /// Null goes back to the real day.
  Future<DebugStatus> moveClock(DateTime? today) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/clock',
      data: {'today': _day(today)},
    );
    return DebugStatus.fromJson(response.data!);
  }

  Future<List<Snapshot>> snapshots() async {
    final response = await _dio.get<List<dynamic>>('$_base/snapshots');
    return [
      for (final s in response.data!)
        Snapshot.fromJson(s as Map<String, dynamic>),
    ];
  }

  Future<void> save(String name) =>
      _dio.post<void>('$_base/snapshots', data: {'name': name});

  Future<DebugStatus> restore(String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/snapshots/$name/restore',
    );
    return DebugStatus.fromJson(response.data!);
  }

  Future<void> delete(String name) =>
      _dio.delete<void>('$_base/snapshots/$name');

  static String? _day(DateTime? day) => day == null
      ? null
      : '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}
