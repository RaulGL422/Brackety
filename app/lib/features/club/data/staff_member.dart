import '../../events/data/my_event.dart';

/// A helper or referee account of the event; [personName]: who is behind it, set by the club.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.username,
    this.personName,
    this.roles = const [],
    this.permissions = const {},
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    id: json['id'] as String,
    username: json['username'] as String,
    personName: json['personName'] as String?,
    roles: [for (final r in json['roles'] as List? ?? const []) r as String],
    permissions: EventPermission.fromJson(json['permissions']),
  );

  final String id;
  final String username;
  final String? personName;

  /// GROUPER and/or REFEREE.
  final List<String> roles;

  /// What the club lets them do (F1-7 C).
  final Set<EventPermission> permissions;

  /// "Juan Pérez (arbitro1)", or the sign-in alone; as the server labels them.
  String get label => personName == null ? username : '$personName ($username)';
}
