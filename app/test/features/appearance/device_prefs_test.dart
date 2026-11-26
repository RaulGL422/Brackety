import 'package:brackety/features/appearance/data/device_prefs.dart';
import 'package:brackety/features/scoreboard/state/bell.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/match_fakes.dart';

void main() {
  // The buzz goes through the platform channel, mocked below.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('device prefs', () {
    test('a new device has the defaults', () {
      const prefs = DevicePrefs();

      expect(prefs.textScale, isNull);
      expect(prefs.moreContrast, isFalse);
      expect(prefs.finished, FinishedShown.latest);
      expect(
        (prefs.bell, prefs.vibrate, prefs.keepScreenOn),
        (true, true, true),
      );
    });

    test('what is saved comes back the same', () {
      final prefs = const DevicePrefs()
          .withTextScale(1.5)
          .copyWith(
            moreContrast: true,
            finished: FinishedShown.none,
            bell: false,
            vibrate: false,
            keepScreenOn: false,
          );

      final back = DevicePrefs.fromJson(prefs.toJson());

      expect(back.textScale, 1.5);
      expect(back.moreContrast, isTrue);
      expect(back.finished, FinishedShown.none);
      expect(
        (back.bell, back.vibrate, back.keepScreenOn),
        (false, false, false),
      );
    });

    test('an unknown value falls back to the default', () {
      final prefs = DevicePrefs.fromJson({
        'textScale': 3.7,
        'finished': 'someday',
      });

      expect(prefs.textScale, isNull);
      expect(prefs.finished, FinishedShown.latest);
      expect(prefs.bell, isTrue);
    });

    test('the text size goes back to the device', () {
      final prefs = const DevicePrefs().withTextScale(2).withTextScale(null);

      expect(prefs.textScale, isNull);
    });
  });

  group('preferred bell', () {
    late List<MethodCall> haptics;

    setUp(() {
      haptics = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
            return null;
          });
    });

    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    test('rings and buzzes at the end by default', () {
      final fake = FakeBell();
      final bell = PreferredBell(fake, () => const DevicePrefs());

      bell
        ..play(BellSound.start)
        ..play(BellSound.end);

      expect(fake.played, [BellSound.start, BellSound.end]);
      expect(haptics, hasLength(1));
    });

    test('stays silent and still when the device says so', () {
      final fake = FakeBell();
      final bell = PreferredBell(
        fake,
        () => const DevicePrefs(bell: false, vibrate: false),
      );

      bell
        ..play(BellSound.end)
        ..unlock();

      expect(fake.played, isEmpty);
      expect(haptics, isEmpty);
      // Unlocking the browser's audio still happens: turning it on later must work.
      expect(fake.unlocks, 1);
    });
  });
}
