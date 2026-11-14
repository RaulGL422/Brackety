import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/club_models.dart';
import '../data/club_repository.dart';
import '../state/club_providers.dart';

/// The clubs taking part, added by hand; each participant may belong to one. Every change is
/// saved at once, as the rest of the settings.
class OrganizationsEditor extends ConsumerStatefulWidget {
  const OrganizationsEditor({
    super.key,
    required this.eventId,
    required this.organizations,
  });

  final String eventId;
  final List<Organization> organizations;

  @override
  ConsumerState<OrganizationsEditor> createState() =>
      _OrganizationsEditorState();
}

class _OrganizationsEditorState extends ConsumerState<OrganizationsEditor> {
  late var _organizations = widget.organizations;
  var _saving = false;

  @override
  void didUpdateWidget(OrganizationsEditor old) {
    super.didUpdateWidget(old);
    if (old.organizations != widget.organizations) {
      _organizations = widget.organizations;
    }
  }

  Future<void> _save(List<Organization> next) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(clubRepositoryProvider)
          .saveOrganizations(widget.eventId, next);
      if (mounted) setState(() => _organizations = saved);
      ref
        ..invalidate(eventSettingsProvider(widget.eventId))
        ..invalidate(participantsProvider(widget.eventId));
      toasts.show(l10n.saved, duration: const Duration(seconds: 1));
    } on DioException catch (e) {
      toasts.show(switch (e.response?.statusCode) {
        409 => l10n.organizationsConflict,
        _ => l10n.saveError,
      }, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit(int? index) async {
    final edited = await showDialog<Organization>(
      context: context,
      builder: (_) => _OrganizationDialog(
        initial: index == null ? null : _organizations[index],
      ),
    );
    if (edited == null) return;
    await _save(
      index == null
          ? [..._organizations, edited]
          : ([..._organizations]..[index] = edited),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_organizations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: Text(l10n.organizationsEmpty),
          ),
        for (final (i, o) in _organizations.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(o.name),
            subtitle: o.shortName == null ? null : Text(o.shortName!),
            onTap: _saving ? null : () => _edit(i),
            trailing: IconButton(
              tooltip: l10n.organizationRemove,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving
                  ? null
                  : () => _save([..._organizations]..removeAt(i)),
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.organizationAdd),
          onPressed: _saving ? null : () => _edit(null),
        ),
      ],
    );
  }
}

class _OrganizationDialog extends StatefulWidget {
  const _OrganizationDialog({this.initial});

  final Organization? initial;

  @override
  State<_OrganizationDialog> createState() => _OrganizationDialogState();
}

class _OrganizationDialogState extends State<_OrganizationDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _shortName = TextEditingController(
    text: widget.initial?.shortName,
  );

  @override
  void dispose() {
    _name.dispose();
    _shortName.dispose();
    super.dispose();
  }

  void _done() {
    if (!_form.currentState!.validate()) return;
    final shortName = _shortName.text.trim();
    Navigator.pop(
      context,
      Organization(
        id: widget.initial?.id,
        name: _name.text.trim(),
        shortName: shortName.isEmpty ? null : shortName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(
        widget.initial == null ? l10n.organizationAdd : l10n.organizationEdit,
      ),
      content: SizedBox(
        width: AppSizes.formMaxWidth,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.organizationName),
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
              ),
              TextFormField(
                controller: _shortName,
                decoration: InputDecoration(
                  labelText: l10n.organizationShortName,
                ),
                maxLength: 20,
                onFieldSubmitted: (_) => _done(),
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
        FilledButton(onPressed: _done, child: Text(l10n.save)),
      ],
    );
  }
}

/// "No club" (null) or one of the event's clubs; nothing when the event has none.
class OrganizationChoice extends ConsumerWidget {
  const OrganizationChoice({
    super.key,
    required this.eventId,
    required this.value,
    required this.onChanged,
  });

  final String eventId;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final organizations =
        ref.watch(eventSettingsProvider(eventId)).value?.organizations ?? [];
    if (organizations.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: DropdownButtonFormField<String?>(
        initialValue: organizations.any((o) => o.id == value) ? value : null,
        // Club names can be long: they shrink with an ellipsis instead of overflowing.
        isExpanded: true,
        decoration: InputDecoration(labelText: l10n.organizationLabel),
        items: [
          DropdownMenuItem(child: Text(l10n.organizationNone)),
          for (final o in organizations)
            DropdownMenuItem(
              value: o.id,
              child: Text(o.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
