import 'package:audioplayers/audioplayers.dart';

import 'bell.dart';

PlatformBell createBell() => _AudioBell();

/// Android: one player per sound, loaded at once, so a sound never waits for its file nor cuts
/// another one short.
class _AudioBell implements PlatformBell {
  _AudioBell() {
    for (final sound in BellSound.values) {
      final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      player.setSource(AssetSource('sounds/${sound.file}'));
      _players[sound] = player;
    }
  }

  final _players = <BellSound, AudioPlayer>{};

  @override
  void play(BellSound sound) {
    final player = _players[sound]!;
    player.stop().then((_) => player.resume());
  }

  @override
  void unlock() {}

  @override
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
  }
}
