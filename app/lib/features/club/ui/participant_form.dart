import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../events/state/events_providers.dart';
import '../../legal/ui/legal_links.dart';
import '../data/club_models.dart';
import '../data/club_repository.dart';
import '../state/club_providers.dart';
import 'club_panel_screen.dart';
import 'organizations_editor.dart';

/// Age on [day], as the server counts it for categories.
int ageOn(DateTime birthDate, DateTime day) {
  final age = day.year - birthDate.year;
  final birthdayPassed =
      day.month > birthDate.month ||
      (day.month == birthDate.month && day.day >= birthDate.day);
  return birthdayPassed ? age : age - 1;
}

/// Adds a student, or edits [participant]. Closes itself once saved.
Future<void> showParticipantForm(
  BuildContext context,
  String eventId, {
  Participant? participant,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ParticipantForm(eventId: eventId, participant: participant),
);

class _ParticipantForm extends ConsumerStatefulWidget {
  const _ParticipantForm({required this.eventId, this.participant});

  final String eventId;
  final Participant? participant;

  @override
  ConsumerState<_ParticipantForm> createState() => _ParticipantFormState();
}

class _ParticipantFormState extends ConsumerState<_ParticipantForm> {
  final _form = GlobalKey<FormState>();
  late final _firstName = TextEditingController(
    text: widget.participant?.firstName,
  );
  late final _lastName = TextEditingController(
    text: widget.participant?.lastName,
  );
  late final _height = TextEditingController(
    text: widget.participant?.heightCm?.toString(),
  );
  late DateTime? _birthDate = widget.participant?.birthDate;
  late bool _consent = widget.participant?.guardianConsent ?? false;
  late String? _categoryId = widget.participant?.chosenCategoryId;
  late String? _organizationId = widget.participant?.organizationId;
  var _birthDateMissing = false;
  var _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _height.dispose();
    super.dispose();
  }

  bool get _isMinor {
    final eventDate = ref.read(myEventProvider(widget.eventId)).value?.date;
    return _birthDate != null &&
        ageOn(_birthDate!, eventDate ?? DateTime.now()) < adultAge;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    ref.watch(myEventProvider(widget.eventId));
    final needsConsent = _isMinor && !_consent;
    String? required(String? v) =>
        v == null || v.trim().isEmpty ? l10n.fieldRequired : null;
    return AlertDialog(
      scrollable: true,
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(
        widget.participant == null ? l10n.participantAdd : l10n.participantEdit,
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _firstName,
                  decoration: InputDecoration(labelText: l10n.firstName),
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  validator: required,
                ),
                TextFormField(
                  controller: _lastName,
                  decoration: InputDecoration(labelText: l10n.lastName),
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  validator: required,
                ),
                const SizedBox(height: AppSpacing.s),
                InkWell(
                  onTap: _pickBirthDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.birthDate,
                      errorText: _birthDateMissing ? l10n.fieldRequired : null,
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _birthDate == null
                          ? ''
                          : DateFormat.yMd(locale).format(_birthDate!),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _height,
                  decoration: InputDecoration(labelText: l10n.heightOptional),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final cm = int.tryParse(v.trim());
                    return cm == null || cm < 50 || cm > 250
                        ? l10n.heightInvalid
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.s),
                CategoryChoice(
                  eventId: widget.eventId,
                  value: _categoryId,
                  onChanged: (id) => setState(() => _categoryId = id),
                ),
                OrganizationChoice(
                  eventId: widget.eventId,
                  value: _organizationId,
                  onChanged: (id) => setState(() => _organizationId = id),
                ),
                if (_isMinor)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _consent,
                    onChanged: (v) => setState(() => _consent = v ?? false),
                    title: Text(l10n.guardianConsent),
                    subtitle: Text(l10n.guardianConsentRequired),
                  ),
                const SizedBox(height: AppSpacing.s),
                PrivacyNotice(message: l10n.participantPrivacyNotice),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving || needsConsent ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 10),
      firstDate: DateTime(now.year - 100),
      lastDate: now.subtract(const Duration(days: 1)),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateMissing = false;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final valid = _form.currentState!.validate();
    setState(() => _birthDateMissing = _birthDate == null);
    if (!valid || _birthDate == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(clubRepositoryProvider)
          .saveParticipant(
            widget.eventId,
            participantId: widget.participant?.id,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            birthDate: _birthDate!,
            heightCm: int.tryParse(_height.text.trim()),
            guardianConsent: _isMinor && _consent,
            categoryId: _categoryId,
            organizationId: _organizationId,
          );
      ref.invalidate(participantsProvider(widget.eventId));
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      Toasts.of(context).show(saveErrorMessage(l10n, e), kind: ToastKind.error);
    }
  }
}

/// "By age" (null) or a category of the event chosen for this participant.
class CategoryChoice extends ConsumerWidget {
  const CategoryChoice({
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
    final categories =
        ref.watch(eventSettingsProvider(eventId)).value?.categories ?? [];
    return DropdownButtonFormField<String?>(
      initialValue: categories.any((c) => c.id == value) ? value : null,
      decoration: InputDecoration(labelText: l10n.categoryLabel),
      items: [
        DropdownMenuItem(child: Text(l10n.categoryByAge)),
        for (final c in categories)
          DropdownMenuItem(value: c.id, child: Text(c.name)),
      ],
      onChanged: onChanged,
    );
  }
}
