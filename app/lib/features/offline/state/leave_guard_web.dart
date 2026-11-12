import 'dart:js_interop';

import 'package:web/web.dart' as web;

JSFunction? _listener;

/// [on]: the browser's own "leave site?" question on reload or close.
void guardLeaving(bool on) {
  if (on == (_listener != null)) return;
  if (on) {
    _listener = ((web.Event event) => event.preventDefault()).toJS;
    web.window.addEventListener('beforeunload', _listener);
  } else {
    web.window.removeEventListener('beforeunload', _listener);
    _listener = null;
  }
}
