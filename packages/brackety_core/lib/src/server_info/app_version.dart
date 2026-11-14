import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/gen/core_localizations.dart';

/// "Versión 0.6.0 (8)" in small print, from the pubspec (on the web, the build's version.json),
/// so anyone can say which version a device runs (Raul, 2026-11-14). Nothing until it is known,
/// nor where the platform does not say.
class AppVersionText extends StatefulWidget {
  const AppVersionText({super.key, this.textAlign});

  final TextAlign? textAlign;

  @override
  State<AppVersionText> createState() => _AppVersionTextState();
}

class _AppVersionTextState extends State<AppVersionText> {
  late final Future<PackageInfo?> _info = PackageInfo.fromPlatform()
      .then<PackageInfo?>((info) => info, onError: (_) => null);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _info,
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null || info.version.isEmpty) {
          return const SizedBox.shrink();
        }
        final l10n = CoreLocalizations.of(context);
        return Text(
          info.buildNumber.isEmpty
              ? l10n.appVersion(info.version)
              : l10n.appVersionBuild(info.version, info.buildNumber),
          textAlign: widget.textAlign,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        );
      },
    );
  }
}
