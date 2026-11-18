import 'result.dart';

/// One business action, such as "log in". Presentation code depends on use
/// cases, never on repositories or Dio directly.
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// Parameter type for use cases that need no input.
final class NoParams {
  const NoParams();
}
