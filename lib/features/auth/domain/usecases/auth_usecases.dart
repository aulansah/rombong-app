import 'package:equatable/equatable.dart';

import '../../../../core/result.dart';
import '../../../../core/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class Login implements UseCase<User, LoginParams> {
  const Login(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<User>> call(LoginParams p) =>
      _repository.login(email: p.email.trim(), password: p.password);
}

class RegisterParams extends Equatable {
  const RegisterParams({required this.name, required this.email, required this.password});
  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

/// Creates the account and signs the user in, so the app goes straight to
/// the home screen after registration.
class Register implements UseCase<User, RegisterParams> {
  const Register(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<User>> call(RegisterParams p) async {
    final created = await _repository.register(
      name: p.name.trim(),
      email: p.email.trim(),
      password: p.password,
    );
    if (created is Err<User>) return created;
    return _repository.login(email: p.email.trim(), password: p.password);
  }
}

class GetCurrentUser implements UseCase<User?, NoParams> {
  const GetCurrentUser(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<User?>> call(NoParams _) => _repository.currentUser();
}

class Logout implements UseCase<void, NoParams> {
  const Logout(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(NoParams _) => _repository.logout();
}
