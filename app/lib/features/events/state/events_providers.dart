import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_controller.dart';
import '../data/my_event.dart';

final myEventsProvider = FutureProvider.autoDispose<List<MyEvent>>((ref) async {
  final response = await ref
      .watch(apiProvider)
      .get<List<dynamic>>('/api/v1/events');
  return [
    for (final json in response.data!)
      MyEvent.fromJson(json as Map<String, dynamic>),
  ];
});

final myEventProvider = FutureProvider.autoDispose.family<MyEvent, String>((
  ref,
  eventId,
) async {
  final events = await ref.watch(myEventsProvider.future);
  return events.firstWhere((e) => e.id == eventId);
});
