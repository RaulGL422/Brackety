import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/data/api_error.dart';
import '../../auth/state/session_controller.dart';
import '../../offline/data/offline_store.dart';
import '../../offline/state/offline_sync.dart';

/// A team or group a helper made without network: sent as is when the server answers again.
/// [people] and [teams] are who it takes, so the lists show them as pending meanwhile.
class QueuedCreation {
  const QueuedCreation({
    required this.id,
    required this.path,
    required this.body,
    required this.label,
    this.people = const [],
    this.teams = const [],
  });

  factory QueuedCreation.fromJson(Map<String, dynamic> json) => QueuedCreation(
    id: json['id'] as String,
    path: json['path'] as String,
    body: json['body'] as Map<String, dynamic>,
    label: json['label'] as String,
    people: [for (final p in json['people'] as List) p as String],
    teams: [for (final t in json['teams'] as List) t as String],
  );

  final String id;
  final String path;
  final Map<String, dynamic> body;

  /// "Grupo con Ana, Luis…" as the helper will read it in the result.
  final String label;
  final List<String> people;
  final List<String> teams;

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'body': body,
    'label': label,
    'people': people,
    'teams': teams,
  };
}

/// How a queued creation ended once sent: [created] false if the server refused it (someone in
/// it was taken meanwhile by another helper).
typedef QueuedResult = ({String label, bool created});

class HelperQueueState {
  const HelperQueueState({this.pending = const [], this.results = const []});

  final List<QueuedCreation> pending;

  /// Not shown yet to the helper.
  final List<QueuedResult> results;

  Set<String> get people => {for (final c in pending) ...c.people};
  Set<String> get teams => {for (final c in pending) ...c.teams};
}

final helperQueueProvider = NotifierProvider<HelperQueue, HelperQueueState>(
  HelperQueue.new,
);

/// Helpers keep working without network (Raul, 2026-11-13): what they create waits on the device
/// and goes in order when the background check finds the server again.
class HelperQueue extends Notifier<HelperQueueState> {
  static const _name = 'helper-queue';
  var _sending = false;

  OfflineStore get _store => ref.read(offlineStoreProvider);

  @override
  HelperQueueState build() {
    ref.listen(offlineSyncProvider.select((s) => s.connected), (_, connected) {
      if (connected) unawaited(send());
    });
    unawaited(_load());
    return const HelperQueueState();
  }

  Future<void> _load() async {
    final saved = await _store.read(_name);
    if (saved is! List || !ref.mounted) return;
    state = HelperQueueState(
      pending: [
        for (final c in saved)
          QueuedCreation.fromJson(c as Map<String, dynamic>),
      ],
    );
    unawaited(send());
  }

  Future<void> add({
    required String path,
    required Map<String, dynamic> body,
    required String label,
    List<String> people = const [],
    List<String> teams = const [],
  }) async {
    state = HelperQueueState(
      pending: [
        ...state.pending,
        QueuedCreation(
          id: const Uuid().v4(),
          path: path,
          body: body,
          label: label,
          people: people,
          teams: teams,
        ),
      ],
      results: state.results,
    );
    await _save();
  }

  /// Sends the queue in order; stops at the first one without answer.
  Future<void> send() async {
    if (_sending) return;
    _sending = true;
    try {
      while (ref.mounted && state.pending.isNotEmpty) {
        final next = state.pending.first;
        bool created;
        try {
          await ref.read(apiProvider).post<Object?>(next.path, data: next.body);
          created = true;
        } on DioException catch (e) {
          if (ApiError.from(e).noResponse) {
            ref.read(offlineSyncProvider.notifier).reportNoResponse();
            return;
          }
          created = false;
        }
        if (!ref.mounted) return;
        state = HelperQueueState(
          pending: [
            for (final c in state.pending)
              if (c.id != next.id) c,
          ],
          results: [...state.results, (label: next.label, created: created)],
        );
        await _save();
      }
    } finally {
      _sending = false;
    }
  }

  /// The results the helper has just been told about.
  void shown() => state = HelperQueueState(pending: state.pending);

  Future<void> _save() async {
    try {
      await _store.write(_name, [for (final c in state.pending) c.toJson()]);
    } on OfflineStoreException {
      // Kept in memory: it still goes while the app stays open.
    }
  }
}
