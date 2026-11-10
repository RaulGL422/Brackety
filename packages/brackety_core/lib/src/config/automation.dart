import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

import 'api_config.dart';

SemanticsHandle? _semanticsHandle;

/// Keeps the semantics tree on in debug and `dev` builds: on Flutter web it is what lets
/// browser automation (Playwright) find widgets by label instead of a bare canvas.
/// Release builds keep it off unless a screen reader asks. See docs/08-ejecucion-local.md.
/// Call after the binding is initialized.
void enableSemanticsForAutomation({bool? enabled}) {
  if (!(enabled ?? (kDebugMode || isDevEnvironment))) return;
  if (_semanticsHandle != null) return;
  _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
}

@visibleForTesting
void disableSemanticsForAutomation() {
  _semanticsHandle?.dispose();
  _semanticsHandle = null;
}
