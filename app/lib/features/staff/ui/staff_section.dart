import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/ui/widgets/confirm_dialog.dart';
import '../../club/data/staff_member.dart';
import '../../club/state/club_providers.dart';
import '../../events/data/my_event.dart';
import '../data/staff_repository.dart';

String staffRoleName(AppLocalizations l10n, StaffRole role) => switch (role) {
  StaffRole.grouper => l10n.staffHelper,
  StaffRole.referee => l10n.staffReferee,
};

/// The club's pending invitations and the button to invite someone (F1-5).
class StaffInvitations extends ConsumerWidget {
  const StaffInvitations({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pending = ref.watch(invitationsProvider(eventId)).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final i in pending)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mail_outline),
            title: Text(i.email, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              [
                staffRoleName(l10n, i.role),
                i.expired ? l10n.invitationExpired : l10n.invitationPending,
              ].join(' · '),
            ),
            trailing: IconButton(
              tooltip: l10n.invitationCancel,
              icon: const Icon(Icons.close),
              onPressed: () => _run(
                context,
                ref,
                () => ref.read(staffRepositoryProvider).cancel(eventId, i.id),
                l10n.invitationCancelled,
              ),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.person_add_alt),
            label: Text(l10n.invitationInvite),
            onPressed: () => _invite(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<(String, StaffRole)>(
      context: context,
      builder: (_) => const _InviteDialog(),
    );
    if (result == null || !context.mounted) return;
    final (email, role) = result;
    await _run(
      context,
      ref,
      () => ref.read(staffRepositoryProvider).invite(eventId, email, role),
      l10n.invitationSent(email),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String done,
  ) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    try {
      await action();
      toasts.show(done, kind: ToastKind.success);
    } on DioException catch (e) {
      toasts.show(staffErrorMessage(l10n, e), kind: ToastKind.error);
    }
    ref.invalidate(invitationsProvider(eventId));
  }
}

/// "Quitar" next to a helper or referee: one entry per role they have.
class StaffRemoveButton extends ConsumerWidget {
  const StaffRemoveButton({
    super.key,
    required this.eventId,
    required this.member,
  });

  final String eventId;
  final StaffMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roles = [
      for (final r in member.roles)
        if (r != 'CLUB') StaffRole.fromWire(r),
    ];
    return PopupMenuButton<StaffRole>(
      tooltip: l10n.staffRemoveTooltip(member.username),
      icon: const Icon(Icons.person_remove_outlined),
      itemBuilder: (_) => [
        for (final r in roles)
          PopupMenuItem(
            value: r,
            child: Text(l10n.staffRemoveAs(staffRoleName(l10n, r))),
          ),
      ],
      onSelected: (role) async {
        final toasts = Toasts.of(context);
        final confirmed = await confirmAction(
          context,
          body: l10n.staffRemoveConfirm(
            member.username,
            staffRoleName(l10n, role),
          ),
          confirmLabel: l10n.staffRemove,
          destructive: true,
        );
        if (!confirmed) return;
        try {
          await ref
              .read(staffRepositoryProvider)
              .remove(eventId, member.id, role);
          toasts.show(l10n.staffRemoved, kind: ToastKind.success);
        } on DioException catch (e) {
          toasts.show(staffErrorMessage(l10n, e), kind: ToastKind.error);
        }
        ref.invalidate(eventSettingsProvider(eventId));
      },
    );
  }
}

String permissionName(AppLocalizations l10n, EventPermission p) => switch (p) {
  EventPermission.view => l10n.permissionView,
  EventPermission.groups => l10n.permissionGroups,
  EventPermission.teams => l10n.permissionTeams,
  EventPermission.measures => l10n.permissionMeasures,
  EventPermission.ownMat => l10n.permissionOwnMat,
  EventPermission.phase => l10n.permissionPhase,
  EventPermission.control => l10n.permissionControl,
  EventPermission.reviews => l10n.permissionReviews,
  EventPermission.deviceImport => l10n.permissionDeviceImport,
  EventPermission.participants => l10n.permissionParticipants,
  EventPermission.moveGroups => l10n.permissionMoveGroups,
};

/// What a helper or referee may do in the event (F1-7 C): the club ticks it here.
class StaffPermissionsButton extends ConsumerWidget {
  const StaffPermissionsButton({
    super.key,
    required this.eventId,
    required this.member,
  });

  final String eventId;
  final StaffMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.permissionsTooltip(member.username),
      icon: const Icon(Icons.admin_panel_settings_outlined),
      onPressed: () async {
        final toasts = Toasts.of(context);
        final chosen = await showDialog<Set<EventPermission>>(
          context: context,
          builder: (_) => _PermissionsDialog(member: member),
        );
        if (chosen == null) return;
        try {
          await ref
              .read(staffRepositoryProvider)
              .setPermissions(eventId, member.id, chosen);
          toasts.show(l10n.permissionsSaved, kind: ToastKind.success);
        } on DioException catch (e) {
          toasts.show(staffErrorMessage(l10n, e), kind: ToastKind.error);
        }
        ref.invalidate(eventSettingsProvider(eventId));
      },
    );
  }
}

class _PermissionsDialog extends StatefulWidget {
  const _PermissionsDialog({required this.member});

  final StaffMember member;

  @override
  State<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<_PermissionsDialog> {
  late final _chosen = {...widget.member.permissions};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.permissionsTitle(widget.member.label)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.permissionsHint),
            for (final p in EventPermission.values)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _chosen.contains(p),
                title: Text(permissionName(l10n, p)),
                onChanged: (on) =>
                    setState(() => on! ? _chosen.add(p) : _chosen.remove(p)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _chosen),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

String staffErrorMessage(AppLocalizations l10n, DioException error) =>
    switch (error.response?.data) {
      {'code': 'ALREADY_STAFF'} => l10n.staffErrorAlready,
      {'code': 'INVITATION_TOO_SOON'} => l10n.staffErrorTooSoon,
      {'code': 'TOO_MANY_INVITATIONS'} => l10n.staffErrorTooMany,
      {'code': 'REFEREE_ON_MAT'} => l10n.staffErrorOnMat,
      _ => l10n.saveError,
    };

class _InviteDialog extends StatefulWidget {
  const _InviteDialog();

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _role = StaffRole.referee;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.invitationInvite),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.invitationHint),
              const SizedBox(height: AppSpacing.m),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l10n.invitationEmail),
                validator: (v) =>
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(v?.trim() ?? '')
                    ? null
                    : l10n.invitationEmailInvalid,
              ),
              const SizedBox(height: AppSpacing.m),
              SegmentedButton<StaffRole>(
                segments: [
                  for (final r in StaffRole.values)
                    ButtonSegment(
                      value: r,
                      label: Text(staffRoleName(l10n, r)),
                    ),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.single),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, (_email.text.trim(), _role));
            }
          },
          child: Text(l10n.invitationSend),
        ),
      ],
    );
  }
}
