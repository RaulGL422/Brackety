import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/api_error.dart';
import '../../auth/state/session_controller.dart';
import '../../auth/ui/widgets/auth_form_page.dart';
import '../../auth/ui/widgets/form_message.dart';
import '../../events/state/events_providers.dart';
import '../data/staff_repository.dart';
import 'staff_section.dart';

final _offerProvider = FutureProvider.autoDispose
    .family<InvitationOffer, String>(
      retry: (_, _) => null,
      (ref, token) => ref.watch(staffRepositoryProvider).offer(token),
    );

/// Opened from the invitation email (F1-5), once signed in: who invites, to what and as what. Only the invited
/// email can accept; with another account it says so and offers to sign out.
class InvitationScreen extends ConsumerStatefulWidget {
  const InvitationScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
  var _accepting = false;

  Future<void> _accept(String token) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    setState(() => _accepting = true);
    try {
      await ref.read(staffRepositoryProvider).accept(token);
      ref.invalidate(myEventsProvider);
      toasts.show(l10n.invitationAccepted, kind: ToastKind.success);
      if (mounted) context.go('/');
    } on DioException catch (e) {
      toasts.show(
        e.response?.statusCode == 403
            ? l10n.invitationVerifyFirst
            : l10n.linkInvalid,
        kind: ToastKind.error,
      );
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final token = widget.token;
    return AuthFormPage(
      title: l10n.invitationTitle,
      children: [
        if (token == null || token.isEmpty)
          FormMessage.error(l10n.linkInvalid)
        else
          switch (ref.watch(_offerProvider(token))) {
            AsyncData(:final value) => _Offer(
              offer: value,
              accepting: _accepting,
              onAccept: () => _accept(token),
            ),
            AsyncError(:final DioException error)
                when ApiError.from(error).noResponse =>
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormMessage.error(l10n.noServer),
                  const SizedBox(height: AppSpacing.l),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(_offerProvider(token)),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            AsyncError() => FormMessage.error(l10n.invitationInvalid),
            _ => const Center(child: CircularProgressIndicator()),
          },
      ],
    );
  }
}

class _Offer extends ConsumerWidget {
  const _Offer({
    required this.offer,
    required this.accepting,
    required this.onAccept,
  });

  final InvitationOffer offer;
  final bool accepting;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.invitationFrom(offer.organizer, staffRoleName(l10n, offer.role)),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(offer.eventName, style: text.titleLarge),
        Text(DateFormat.yMMMMd(locale).format(offer.eventDate)),
        const SizedBox(height: AppSpacing.l),
        if (offer.forYou)
          FilledButton(
            onPressed: accepting ? null : onAccept,
            child: Text(l10n.invitationAccept),
          )
        else ...[
          FormMessage.error(l10n.invitationOtherEmail(offer.email)),
          const SizedBox(height: AppSpacing.m),
          // Signing out keeps this link: the sign-in comes back here.
          OutlinedButton(
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
            child: Text(l10n.invitationSwitchAccount),
          ),
        ],
      ],
    );
  }
}
