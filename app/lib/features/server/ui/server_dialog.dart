import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/server_choice.dart';
import 'server_texts.dart';

/// Picks the hall, Internet or a typed URL; pops the chosen URL, or null if cancelled.
class ServerDialog extends StatefulWidget {
  const ServerDialog({super.key, required this.current});

  final String current;

  @override
  State<ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<ServerDialog> {
  final _formKey = GlobalKey<FormState>();
  late ServerOption _option = optionOf(widget.current);
  late final _url = TextEditingController(
    text: _option == ServerOption.other ? widget.current : '',
  );

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    final url = switch (_option) {
      ServerOption.hall => hallServerUrl,
      ServerOption.internet => internetServerUrl,
      ServerOption.other =>
        _formKey.currentState!.validate() ? parseServerUrl(_url.text) : null,
    };
    if (url != null) Navigator.of(context).pop(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.serverDialogTitle),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RadioGroup<ServerOption>(
                groupValue: _option,
                onChanged: (option) => setState(() => _option = option!),
                child: Column(
                  children: [
                    for (final option in ServerOption.values)
                      RadioListTile<ServerOption>(
                        value: option,
                        contentPadding: EdgeInsets.zero,
                        title: Text(serverOptionName(l10n, option)),
                        subtitle: switch (option) {
                          ServerOption.hall => const Text(hallServerUrl),
                          ServerOption.internet => const Text(
                            internetServerUrl,
                          ),
                          ServerOption.other => null,
                        },
                      ),
                  ],
                ),
              ),
              if (_option == ServerOption.other)
                Form(
                  key: _formKey,
                  child: _UrlField(controller: _url, onSubmitted: _submit),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.serverUse)),
      ],
    );
  }
}

class _UrlField extends StatelessWidget {
  const _UrlField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final warning = BracketyColors.of(context).warning;
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => TextFormField(
        controller: controller,
        autofocus: true,
        autocorrect: false,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        // Clears the error as soon as it is fixed, so the cleartext warning can show.
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        onFieldSubmitted: (_) => onSubmitted(),
        decoration: InputDecoration(
          labelText: l10n.serverUrlLabel,
          hintText: l10n.serverUrlHint,
          helperText: isBlockedCleartext(value.text)
              ? l10n.serverUrlCleartext
              : null,
          helperMaxLines: 3,
          helperStyle: TextStyle(color: warning),
        ),
        validator: (text) =>
            parseServerUrl(text ?? '') == null ? l10n.serverUrlInvalid : null,
      ),
    );
  }
}
