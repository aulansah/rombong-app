import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/auth_usecases.dart';

// Wiring of the auth feature: data → domain. Presentation code only reads
// the use case providers; tests override them with mocks.

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
);

/// Typed as the domain interface, so nothing above this line knows about
/// AuthRepositoryImpl.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    storage: ref.watch(tokenStorageProvider),
  ),
);

final loginUseCaseProvider = Provider<Login>((ref) => Login(ref.watch(authRepositoryProvider)));

final registerUseCaseProvider = Provider<Register>((ref) => Register(ref.watch(authRepositoryProvider)));

final getCurrentUserUseCaseProvider =
    Provider<GetCurrentUser>((ref) => GetCurrentUser(ref.watch(authRepositoryProvider)));

final logoutUseCaseProvider = Provider<Logout>((ref) => Logout(ref.watch(authRepositoryProvider)));
