import 'package:flutter/material.dart';

import '../state/group_draft.dart';

/// The checkbox of a participant or team in the group being built; a ghost is also ticked (its
/// row adds the "Ghost" chip). A real checkbox, so screen readers hear "ticked".
class PickMark extends StatelessWidget {
  const PickMark({super.key, required this.state, required this.onTap});

  final PickState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Checkbox(
    value: state == PickState.member || state == PickState.ghost,
    onChanged: state == PickState.unavailable ? null : (_) => onTap(),
  );
}
