import 'package:ecommerce_app/core/usecase.dart';
import 'package:ecommerce_app/features/auth/domain/entities/user.dart';
import 'package:ecommerce_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:ecommerce_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLogin extends Mock implements Login {}

class MockRegister extends Mock implements Register {}

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockLogout extends Mock implements Logout {}

const testUser = User(id: 'u1', name: 'Auldy', email: 'auldy@example.com', role: 'customer');

/// mocktail needs a fallback value for custom types used with `any()`.
void registerFallbacks() {
  registerFallbackValue(const NoParams());
  registerFallbackValue(const LoginParams(email: '', password: ''));
  registerFallbackValue(const RegisterParams(name: '', email: '', password: ''));
}
