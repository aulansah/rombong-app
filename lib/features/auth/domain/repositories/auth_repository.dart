import '../../../../core/result.dart';
import '../entities/user.dart';

/// The contract the domain layer needs. The data layer implements it.
/// This is the dependency inversion at the heart of Clean Architecture:
/// domain defines the interface, data depends on domain, never the reverse.
abstract interface class AuthRepository {
  Future<Result<User>> login({required String email, required String password});

  Future<Result<User>> register({
    required String name,
    required String email,
    required String password,
  });

  /// The user of the saved session, or null when nobody is signed in.
  Future<Result<User?>> currentUser();

  Future<Result<void>> logout();
}
