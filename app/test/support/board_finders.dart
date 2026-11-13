import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The corner's label, then a team's people and where they are after a ". ".
Finder _corner(String label) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      (w.properties.label == label ||
          (w.properties.label?.startsWith('$label. ') ?? false)),
);

/// The board's tile of the match [red] vs [blue] (English corner names).
Finder matchTile(String red, String blue) => find.ancestor(
  of: _corner('Blue: $blue'),
  matching: find.ancestor(
    of: _corner('Red: $red'),
    matching: find.byType(ListTile),
  ),
);
