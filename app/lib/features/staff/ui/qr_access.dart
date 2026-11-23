import 'dart:async';

import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/api_error.dart';
import '../../auth/ui/widgets/confirm_dialog.dart';
import '../../club/state/club_providers.dart';
import '../data/staff_repository.dart';
import '../data/temporary_access.dart';

/// Opens the QR access for someone without an account: their name, then the QR to scan.
class QrAccessButton extends ConsumerWidget {
  const QrAccessButton({
    super.key,
    required this.eventId,
    required this.role,
    this.mat,
    this.replaces,
  });

  final String eventId;
  final StaffRole role;

  /// For a referee: the mat they take.
  final int? mat;

  /// Who has [mat] now, if anyone: they leave it with the new QR.
  final String? replaces;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.qr_code_2),
      tooltip: mat == null
          ? l10n.qrAccessCreateHelper
          : l10n.qrAccessCreateReferee(mat!),
      onPressed: () async {
        if (replaces case final name? when mat != null) {
          final l10n = AppLocalizations.of(context);
          final go = await confirmAction(
            context,
            body: l10n.qrAccessReplacesReferee(mat!, name),
            confirmLabel: l10n.qrAccessCreate,
          );
          if (!go || !context.mounted) return;
        }
        await createQrAccess(context, ref, eventId, role, mat);
      },
    );
  }
}

Future<void> createQrAccess(
  BuildContext context,
  WidgetRef ref,
  String eventId,
  StaffRole role,
  int? mat,
) async {
  final l10n = AppLocalizations.of(context);
  final toasts = Toasts.of(context);
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(role: role, mat: mat),
  );
  if (name == null || !context.mounted) return;
  try {
    final access = await ref
        .read(temporaryAccessRepositoryProvider)
        .create(eventId, name: name, role: role, mat: mat);
    refreshQrAccesses(ref, eventId);
    if (context.mounted) await showQr(context, eventId, access);
  } on DioException catch (e) {
    toasts.show(qrAccessError(l10n, e), kind: ToastKind.error);
  }
}

/// A new code for [access]: whoever was signed in with the old one is out.
Future<void> renewQrAccess(
  BuildContext context,
  WidgetRef ref,
  String eventId,
  TemporaryAccess access,
) async {
  final l10n = AppLocalizations.of(context);
  final toasts = Toasts.of(context);
  try {
    final renewed = await ref
        .read(temporaryAccessRepositoryProvider)
        .renew(eventId, access.id);
    refreshQrAccesses(ref, eventId);
    if (context.mounted) await showQr(context, eventId, renewed);
  } on DioException catch (e) {
    toasts.show(qrAccessError(l10n, e), kind: ToastKind.error);
  }
}

void refreshQrAccesses(WidgetRef ref, String eventId) => ref
  ..invalidate(temporaryAccessesProvider(eventId))
  ..invalidate(eventSettingsProvider(eventId));

String qrAccessError(AppLocalizations l10n, DioException e) =>
    switch (ApiError.from(e).code) {
      'PHASE_FINISHED' => l10n.qrAccessPhaseFinished,
      'TOO_MANY_QR_ACCESSES' => l10n.qrAccessTooMany,
      _ => l10n.saveError,
    };

/// The QR and the sign-in and password to come back in. Once scanned the club hears who came in; it
/// stays open so the password can still be written down.
Future<void> showQr(
  BuildContext context,
  String eventId,
  TemporaryAccess access,
) => showDialog<void>(
  context: context,
  builder: (_) => _QrDialog(eventId: eventId, access: access),
);

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.role, this.mat});

  final StaffRole role;
  final int? mat;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState?.validate() ?? false) {
      Navigator.pop(context, _name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.mat == null
            ? l10n.qrAccessCreateHelper
            : l10n.qrAccessCreateReferee(widget.mat!),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.m,
            children: [
              Text(l10n.qrAccessHint),
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: 120,
                decoration: InputDecoration(labelText: l10n.qrAccessName),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                onFieldSubmitted: (_) => _submit(),
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
        FilledButton.icon(
          icon: const Icon(Icons.qr_code_2),
          label: Text(l10n.qrAccessCreate),
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _QrDialog extends ConsumerStatefulWidget {
  const _QrDialog({required this.eventId, required this.access});

  final String eventId;
  final TemporaryAccess access;

  @override
  ConsumerState<_QrDialog> createState() => _QrDialogState();
}

class _QrDialogState extends ConsumerState<_QrDialog> {
  static const _check = Duration(seconds: 3);
  Timer? _timer;
  var _signedIn = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_check, (_) => _checkSignedIn());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // The club's confirmation: as soon as the code is used, say who came in.
  Future<void> _checkSignedIn() async {
    final List<TemporaryAccess> all;
    try {
      all = await ref
          .read(temporaryAccessRepositoryProvider)
          .list(widget.eventId);
    } on DioException {
      return;
    }
    final now = all.where((a) => a.id == widget.access.id).firstOrNull;
    if (now == null || now.waiting || now.signedInAt == null || !mounted) {
      return;
    }
    _timer?.cancel();
    ref.invalidate(temporaryAccessesProvider(widget.eventId));
    setState(() => _signedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final link = qrLink(widget.access.link ?? '');
    return AlertDialog(
      scrollable: true,
      title: Text(widget.access.name),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.m,
          children: [
            _QrCode(
              link: link,
              label: l10n.qrAccessCodeLabel(widget.access.name),
            ),
            Text(l10n.qrAccessScan, textAlign: TextAlign.center),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppSpacing.s,
              children: [
                if (_signedIn)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                Flexible(
                  child: Text(
                    _signedIn
                        ? l10n.qrAccessSignedIn(widget.access.name)
                        : l10n.qrAccessWaiting,
                  ),
                ),
              ],
            ),
            if (widget.access case TemporaryAccess(
              :final signIn?,
              :final password?,
            ))
              _Credentials(signIn: signIn, password: password),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// White behind the code whatever the theme: phone cameras read dark on light.
class _QrCode extends StatelessWidget {
  const _QrCode({required this.link, required this.label});

  final String link;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(AppSpacing.m),
    // A fixed size: the dialog measures its content and the QR cannot be measured.
    child: SizedBox.square(
      dimension: 240,
      child: QrImageView(data: link, semanticsLabel: label),
    ),
  );
}

/// What to type in "Sign in" if the session closes: big, selectable, no look-alike characters.
class _Credentials extends StatelessWidget {
  const _Credentials({required this.signIn, required this.password});

  final String signIn;
  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final value = text.titleLarge?.copyWith(fontFamily: 'monospace');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Text(l10n.qrAccessSignInLabel, style: text.labelMedium),
        SelectableText(signIn, style: value),
        Text(l10n.qrAccessPasswordLabel, style: text.labelMedium),
        SelectableText(password, style: value),
        Text(l10n.qrAccessCredentialsHint, style: text.bodySmall),
      ],
    );
  }
}

/// The server gives the full link when it knows its public address; locally it gives only the
/// path, and the web app is on the same origin.
String qrLink(String link) =>
    link.startsWith('/') && Uri.base.scheme.startsWith('http')
    ? '${Uri.base.origin}$link'
    : link;
