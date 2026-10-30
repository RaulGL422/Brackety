import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/session_controller.dart';

// Provisional sign-in for the phase 1 prototype; the auth module brings the real screens.
const _demoAccounts = [
  'club1',
  'ayudante1',
  'ayudante2',
  'arbitro1',
  'arbitro2',
  'arbitro3',
  'arbitro4',
  'arbitro5',
];

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login(String username, String password) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).login(username, password);
    } on DioException catch (e) {
      setState(
        () => _error = switch (e.response?.statusCode) {
          401 => l10n.loginInvalid,
          429 => l10n.loginLocked,
          _ => l10n.loginNoServer,
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
        actions: [
          IconButton(
            tooltip: l10n.navConnection,
            icon: const Icon(Icons.dns_outlined),
            onPressed: () => context.push('/connection'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppSpacing.l),
            children: [
              TextField(
                controller: _username,
                autofillHints: const [AutofillHints.username],
                decoration: InputDecoration(labelText: l10n.loginUsername),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(labelText: l10n.loginPassword),
                onSubmitted: (_) => _login(_username.text, _password.text),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.m),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.l),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _login(_username.text, _password.text),
                child: Text(l10n.loginSubmit),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.loginDemoAccounts,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.s),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    for (final account in _demoAccounts)
                      ActionChip(
                        label: Text(account),
                        onPressed: _busy
                            ? null
                            : () => _login(account, account),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
