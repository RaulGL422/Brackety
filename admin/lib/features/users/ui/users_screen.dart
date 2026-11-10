import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../core/page_header.dart';
import '../../../core/table_line.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/users_api.dart';
import '../state/users_controller.dart';
import 'user_detail_view.dart';

const _columns = [4, 3, 3, 2, 2];

/// Every account, newest first, searched by email or organization; one opens its detail.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedUserProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: selected == null
          ? const _UserList()
          : UserDetailView(accountId: selected),
    );
  }
}

class _UserList extends ConsumerWidget {
  const _UserList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final users = ref.watch(usersProvider);
    final refresh = ref.read(usersProvider.notifier).refresh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: l10n.usersTitle, onRefresh: refresh),
        const SizedBox(height: AppSpacing.s),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
          child: TextFormField(
            initialValue: ref.read(userSearchProvider).query,
            decoration: InputDecoration(
              labelText: l10n.usersSearch,
              prefixIcon: const Icon(Icons.search),
            ),
            textInputAction: TextInputAction.search,
            onFieldSubmitted: ref.read(userSearchProvider.notifier).search,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Expanded(
          child: AsyncView(
            value: users,
            onRetry: refresh,
            data: (page) => page.items.isEmpty
                ? Text(l10n.usersEmpty, textAlign: TextAlign.center)
                : _UserPageView(page),
          ),
        ),
      ],
    );
  }
}

class _UserPageView extends ConsumerWidget {
  const _UserPageView(this.page);

  final AdminUserPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final open = ref.read(selectedUserProvider.notifier).open;
    final go = ref.read(userSearchProvider.notifier).go;
    return LayoutBuilder(
      builder: (context, constraints) {
        final table = constraints.maxWidth >= tableMinWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (table) ...[
              TableHeader(
                flexes: _columns,
                labels: [
                  l10n.userColumnEmail,
                  l10n.userColumnOrganization,
                  l10n.userColumnProfiles,
                  l10n.userColumnCreated,
                  l10n.userColumnState,
                ],
              ),
              const Divider(height: 1),
            ],
            Expanded(
              child: ListView.separated(
                itemCount: page.items.length,
                separatorBuilder: (_, _) => table
                    ? const Divider(height: 1)
                    : const SizedBox(height: AppSpacing.s),
                itemBuilder: (context, i) {
                  final user = page.items[i];
                  return table
                      ? _UserLine(user: user, onOpen: () => open(user.id))
                      : _UserCard(user: user, onOpen: () => open(user.id));
                },
              ),
            ),
            if (page.pageCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.m),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.m,
                  children: [
                    OutlinedButton(
                      onPressed: page.page > 0 ? () => go(page.page - 1) : null,
                      child: Text(l10n.eventsPrevious),
                    ),
                    Text(l10n.eventsPageOf(page.page + 1, page.pageCount)),
                    OutlinedButton(
                      onPressed: page.hasNext ? () => go(page.page + 1) : null,
                      child: Text(l10n.eventsNext),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// "Club, Ayudante"; the API sends them sorted.
String profileNames(AppLocalizations l10n, List<String> profiles) => profiles
    .map(
      (p) => switch (p) {
        'CLUB' => l10n.userProfileClub,
        'EXTERNAL_ENTITY' => l10n.userProfileEntity,
        'HELPER' => l10n.userProfileHelper,
        'STUDENT' => l10n.userProfileStudent,
        _ => l10n.userProfileExternal,
      },
    )
    .join(', ');

/// Words, never colour alone: deleted, suspended, email not verified, or active.
String userState(AppLocalizations l10n, AdminUserRow user) => user.deleted
    ? l10n.userStateDeleted
    : user.suspended
    ? l10n.userStateSuspended
    : !user.emailVerified
    ? l10n.userStateUnverified
    : l10n.userStateActive;

class _UserLine extends StatelessWidget {
  const _UserLine({required this.user, required this.onOpen});

  final AdminUserRow user;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onOpen,
      child: TableLine(
        flexes: _columns,
        cells: [
          OneLineText(
            user.email,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          OneLineText(user.organization ?? '–'),
          Text(profileNames(l10n, user.profiles)),
          Text(l10n.userDate(user.createdAt.toLocal())),
          Text(userState(l10n, user)),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onOpen});

  final AdminUserRow user;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(user.email, style: text.titleMedium),
              if (user.organization case final organization?)
                Text(organization),
              Text(profileNames(l10n, user.profiles)),
              Text(userState(l10n, user), style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
