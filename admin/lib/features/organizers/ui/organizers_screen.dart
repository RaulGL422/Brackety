import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../core/confirm_dialog.dart';
import '../../../core/page_header.dart';
import '../../../core/table_line.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/admin_api_error.dart';
import '../../auth/ui/admin_texts.dart';
import '../data/organizers_api.dart';
import '../state/organizers_controller.dart';
import 'organizer_tile.dart';

class OrganizersScreen extends ConsumerWidget {
  const OrganizersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final organizers = ref.watch(organizersProvider);
    final pendingOnly = ref.watch(
      organizerFilterProvider.select((f) => f == OrganizerFilter.pending),
    );
    final refresh = ref.read(organizersProvider.notifier).refresh;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: l10n.organizersTitle, onRefresh: refresh),
          const SizedBox(height: AppSpacing.s),
          const _FilterBar(),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: AsyncView(
              value: organizers,
              onRetry: refresh,
              data: (organizers) => organizers.isEmpty
                  ? Text(
                      pendingOnly
                          ? l10n.organizersEmptyPending
                          : l10n.organizersEmpty,
                      textAlign: TextAlign.center,
                    )
                  : _OrganizerList(organizers),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(organizerFilterProvider);
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        for (final filter in OrganizerFilter.values)
          ChoiceChip(
            label: Text(switch (filter) {
              OrganizerFilter.pending => l10n.organizerFilterPending,
              OrganizerFilter.validated => l10n.organizerFilterValidated,
              OrganizerFilter.all => l10n.organizerFilterAll,
            }),
            selected: filter == selected,
            onSelected: (_) =>
                ref.read(organizerFilterProvider.notifier).select(filter),
          ),
      ],
    );
  }
}

class _OrganizerList extends ConsumerWidget {
  const _OrganizerList(this.organizers);

  final List<Organizer> organizers;

  Future<void> _validate(
    BuildContext context,
    WidgetRef ref,
    Organizer organizer,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = organizer.organizationName ?? organizer.email;
    final confirmed = await confirmAction(
      context,
      title: l10n.organizerValidateTitle(name),
      body: l10n.organizerValidateBody,
      confirmLabel: l10n.organizerValidate,
    );
    if (!confirmed || !context.mounted) return;
    final toasts = Toasts.of(context);
    String? message;
    try {
      final result = await ref
          .read(organizersProvider.notifier)
          .validate(organizer.accountId);
      message = result == ValidateResult.validated
          ? l10n.organizerValidatedDone(name)
          : l10n.organizerNotFound;
    } on DioException catch (e) {
      message = actionErrorMessage(l10n, AdminApiError.from(e));
    }
    if (message != null) {
      toasts.show(message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _layout(context, ref, constraints.maxWidth >= tableMinWidth),
    );
  }

  Widget _layout(BuildContext context, WidgetRef ref, bool table) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (table) ...[
          TableHeader(
            flexes: organizerColumns,
            labels: organizerColumnLabels(AppLocalizations.of(context)),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: ListView.separated(
            itemCount: organizers.length,
            separatorBuilder: (_, _) => table
                ? const Divider(height: 1)
                : const SizedBox(height: AppSpacing.s),
            itemBuilder: (context, i) => OrganizerTile(
              organizer: organizers[i],
              table: table,
              onValidate: () => _validate(context, ref, organizers[i]),
            ),
          ),
        ),
      ],
    );
  }
}
