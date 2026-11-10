import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/admin_session.dart';
import '../data/metrics_api.dart';

final metricsApiProvider = Provider<MetricsApi>(
  (ref) => MetricsApi(ref.watch(adminDioProvider)),
);

// No automatic retry: the screen shows the error with its own retry button.
final metricsProvider =
    AsyncNotifierProvider.autoDispose<MetricsController, AdminMetrics>(
      MetricsController.new,
      retry: (_, _) => null,
    );

class MetricsController extends AsyncNotifier<AdminMetrics> {
  @override
  Future<AdminMetrics> build() => ref.read(metricsApiProvider).read();

  void refresh() => ref.invalidateSelf();
}
