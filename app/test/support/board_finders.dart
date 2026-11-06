import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _corner(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);

/// The board's tile of the match [red] vs [blue] (English corner names).
Finder matchTile(String red, String blue) => find.ancestor(
  of: _corner('Blue: $blue'),
  matching: find.ancestor(
    of: _corner('Red: $red'),
    matching: find.byType(ListTile),
  ),
);
