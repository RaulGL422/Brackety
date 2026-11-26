import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../appearance/data/device_prefs.dart';
import '../../../appearance/state/device_prefs_provider.dart';
import 'settings_section.dart';

/// What this device prefers, saved on it alone (Raul, 2026-11-26).
void _change(WidgetRef ref, DevicePrefs Function(DevicePrefs) update) =>
    ref.read(devicePrefsProvider.notifier).change(update);

/// The size of the text, over the device's own if chosen, and «Más contraste».
class TextContrastSection extends ConsumerWidget {
  const TextContrastSection({super.key});

  /// The dropdown's value for «as on the device»: a menu value cannot be null.
  static const _device = 0.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(devicePrefsProvider);
    return SettingsSection(
      title: l10n.prefsText,
      children: [
        DropdownButtonFormField<double>(
          initialValue: prefs.textScale ?? _device,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.prefsTextSize),
          items: [
            DropdownMenuItem(
              value: _device,
              child: Text(l10n.prefsTextSizeDevice),
            ),
            for (final scale in DevicePrefs.textScales)
              DropdownMenuItem(
                value: scale,
                child: Text(l10n.prefsTextSizePercent((scale * 100).round())),
              ),
          ],
          onChanged: (scale) => _change(
            ref,
            (p) => p.withTextScale(scale == _device ? null : scale),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          l10n.prefsTextPreview,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.s),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.prefsMoreContrast),
          subtitle: Text(l10n.prefsMoreContrastHint),
          value: prefs.moreContrast,
          onChanged: (on) => _change(ref, (p) => p.copyWith(moreContrast: on)),
        ),
      ],
    );
  }
}

/// How many finished events «Mis eventos» lists.
class MyEventsPrefsSection extends ConsumerWidget {
  const MyEventsPrefsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final finished = ref.watch(devicePrefsProvider.select((p) => p.finished));
    return SettingsSection(
      title: l10n.eventsTitle,
      children: [
        DropdownButtonFormField<FinishedShown>(
          initialValue: finished,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.prefsFinished),
          items: [
            for (final (value, label) in [
              (FinishedShown.latest, l10n.prefsFinishedLatest),
              (FinishedShown.all, l10n.prefsFinishedAll),
              (FinishedShown.none, l10n.prefsFinishedNone),
            ])
              DropdownMenuItem(value: value, child: Text(label)),
          ],
          onChanged: (value) =>
              _change(ref, (p) => p.copyWith(finished: value)),
        ),
      ],
    );
  }
}

/// The bell, the buzz and the screen while refereeing or keeping the table.
class ScoreboardPrefsSection extends ConsumerWidget {
  const ScoreboardPrefsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(devicePrefsProvider);
    Widget toggle(
      String title,
      String hint,
      bool value,
      DevicePrefs Function(DevicePrefs, bool) update,
    ) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(hint),
      value: value,
      onChanged: (on) => _change(ref, (p) => update(p, on)),
    );
    return SettingsSection(
      title: l10n.prefsScoreboard,
      children: [
        Text(l10n.prefsScoreboardHint),
        const SizedBox(height: AppSpacing.s),
        toggle(
          l10n.prefsBell,
          l10n.prefsBellHint,
          prefs.bell,
          (p, on) => p.copyWith(bell: on),
        ),
        toggle(
          l10n.prefsVibrate,
          l10n.prefsVibrateHint,
          prefs.vibrate,
          (p, on) => p.copyWith(vibrate: on),
        ),
        toggle(
          l10n.prefsScreenOn,
          l10n.prefsScreenOnHint,
          prefs.keepScreenOn,
          (p, on) => p.copyWith(keepScreenOn: on),
        ),
      ],
    );
  }
}
