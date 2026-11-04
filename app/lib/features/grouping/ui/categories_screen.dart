import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../state/grouping_providers.dart';

/// Categories with participants, youngest first (the server sends them in that order).
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = categoriesProvider(eventId);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      body: AsyncView(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        data: (categories) => categories.isEmpty
            ? Center(child: Text(l10n.categoriesEmpty))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(provider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    final done = c.grouped == c.participants;
                    return ListTile(
                      title: Text(l10n.categoryAges(c.name)),
                      subtitle: Text(
                        c.isTeam
                            ? l10n.categoryTeamCounts(
                                c.participants,
                                c.teams,
                                c.grouped,
                              )
                            : l10n.categoryCounts(c.participants, c.grouped),
                      ),
                      leading: Icon(
                        done
                            ? Icons.check_circle
                            : c.isTeam
                            ? Icons.diversity_3_outlined
                            : Icons.groups_outlined,
                        color: done ? BracketyColors.of(context).success : null,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => c.isTeam
                          ? context.push(
                              Uri(
                                path:
                                    '/events/$eventId/categories/${c.id}/teams',
                                queryParameters: {
                                  'name': c.name,
                                  'size': '${c.teamSize}',
                                },
                              ).toString(),
                            )
                          : context.push(
                              '/events/$eventId/categories/${c.id}',
                              extra: c.name,
                            ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
