import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time, as a provider so tests can fix it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
