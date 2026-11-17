import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/core_localizations.dart';
import '../network/dio_provider.dart';
import '../theme/tokens.dart';

/// What the debug server says it holds (docs/modulos/entornos.md). Production has no such endpoint.
class DebugStatus {
  const DebugStatus({
    required this.today,
    required this.simulated,
    this.scenario,
  });

  factory DebugStatus.fromJson(Map<String, dynamic> json) => DebugStatus(
    scenario: json['scenario'] as String?,
    today: DateTime.parse(json['today'] as String),
    simulated: json['simulated'] as bool,
  );

  /// The last loaded since the server started, or null.
  final String? scenario;
  final DateTime today;
  final bool simulated;
}

/// Null outside the debug environment (the endpoint answers 404 there) or when the server cannot be reached.
final debugStatusProvider = FutureProvider<DebugStatus?>(
  retry: (_, _) => null,
  (ref) async {
    try {
      final response = await ref
          .watch(dioProvider)
          .get<Map<String, dynamic>>('/api/v1/debug');
      return DebugStatus.fromJson(response.data!);
    } on DioException {
      return null;
    }
  },
);

/// "DEBUG · scenario · date" over every screen of the debug environment, so it is never taken for production.
class DebugBanner extends ConsumerWidget {
  const DebugBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(debugStatusProvider).value;
    if (status == null) return child;
    final l10n = CoreLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMd(locale).format(status.today);
    final text = [
      'DEBUG',
      status.scenario ?? l10n.debugNoScenario,
      status.simulated ? l10n.debugSimulatedDate(date) : date,
    ].join(' · ');
    return Column(
      children: [
        Material(
          color: Colors.deepOrange.shade700,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          // The banner took the top inset already.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
