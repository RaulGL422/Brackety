import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../data/api_error.dart';
import '../auth_texts.dart';

/// "Resend email" with its own busy, sent and error states.
class ResendButton extends StatefulWidget {
  const ResendButton({super.key, required this.send});

  final Future<void> Function() send;

  @override
  State<ResendButton> createState() => _ResendButtonState();
}

class _ResendButtonState extends State<ResendButton> {
  bool _busy = false;
  String? _result;

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _result = null;
    });
    String result;
    try {
      await widget.send();
      result = l10n.resendSent;
    } on DioException catch (e) {
      result = apiErrorMessage(l10n, ApiError.from(e));
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: _busy ? null : _send,
          child: Text(l10n.resendEmail),
        ),
        if (_result case final result?) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(result),
        ],
      ],
    );
  }
}
