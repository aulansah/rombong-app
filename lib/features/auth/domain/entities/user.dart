import 'package:equatable/equatable.dart';

/// The signed-in user, as the app understands it. Pure Dart: no JSON, no
/// Flutter, no Dio.
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String role;

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [id, name, email, role];
}
