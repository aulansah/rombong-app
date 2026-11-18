import 'error/failure.dart';

/// The outcome of a use case: either a value or a [Failure].
///
/// A sealed class lets callers handle both cases with an exhaustive `switch`,
/// so a forgotten error path is a compile error instead of a crash:
///
///   switch (result) {
///     case Ok(:final value): ...
///     case Err(:final failure): ...
///   }
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

extension ResultX<T> on Result<T> {
  /// The failure, or null when the result is [Ok].
  Failure? get failureOrNull => switch (this) {
        Ok() => null,
        Err(:final failure) => failure,
      };
}
