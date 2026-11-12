import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'bell.dart';

PlatformBell createBell() => _WebBell();

/// The web plays the sounds with the Web Audio API, decoded once into memory. An HTML audio
/// element per ring (what the app did before) fetched the file at the moment of the bell, and
/// browsers refuse to start one that a tap did not start: the end of the time, a points end
/// seen by polling or the first bell of a page could stay silent. An audio context opened by a
/// tap ([unlock]) plays any sound later, also from a timer.
class _WebBell implements PlatformBell {
  _WebBell() {
    for (final sound in BellSound.values) {
      unawaited(_load(sound));
    }
  }

  final web.AudioContext _context = web.AudioContext();
  final _buffers = <BellSound, web.AudioBuffer>{};
  var _unlocked = false;

  Future<void> _load(BellSound sound) async {
    try {
      final data = await rootBundle.load('assets/sounds/${sound.file}');
      // decodeAudioData takes the bytes over: it gets its own copy.
      final bytes = Uint8List.fromList(data.buffer.asUint8List());
      _buffers[sound] = await _context
          .decodeAudioData(bytes.buffer.toJS)
          .toDart;
    } catch (_) {
      // Without the sound the scoreboard still works; the referee sees the clock.
    }
  }

  @override
  void unlock() {
    _playEvenWhenSilenced();
    if (_unlocked && _context.state == 'running') return;
    unawaited(_context.resume().toDart.then((_) {}, onError: (_) {}));
    // Safari also wants a sound started during the tap: a silent one.
    final silence = _context.createBuffer(1, 1, 22050);
    _start(silence);
    _unlocked = true;
  }

  @override
  void play(BellSound sound) {
    final buffer = _buffers[sound];
    if (buffer == null) return;
    if (_context.state == 'running') {
      _start(buffer);
      return;
    }
    // Suspended (no tap yet, or the browser paused it): try to resume, but a bell that comes
    // seconds late would only confuse, so it is dropped then.
    final asked = DateTime.now();
    _context.resume().toDart.then((_) {
      if (DateTime.now().difference(asked) < const Duration(seconds: 1)) {
        _start(buffer);
      }
    }, onError: (_) {});
  }

  /// Safari on iOS treats page sound as "ambient": the silent switch mutes it. Declared as playback
  /// (Audio Session API, Safari 16.4+), the bells sound like a video's would. Other browsers lack
  /// the property and keep their behaviour.
  void _playEvenWhenSilenced() {
    final session = web.window.navigator.getProperty<JSObject?>(
      'audioSession'.toJS,
    );
    if (session != null &&
        session.getProperty<JSString?>('type'.toJS)?.toDart != 'playback') {
      session.setProperty('type'.toJS, 'playback'.toJS);
    }
  }

  void _start(web.AudioBuffer buffer) {
    final source = _context.createBufferSource()..buffer = buffer;
    source.connect(_context.destination);
    source.start();
  }

  @override
  void dispose() =>
      unawaited(_context.close().toDart.then((_) {}, onError: (_) {}));
}
