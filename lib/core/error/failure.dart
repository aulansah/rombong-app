import 'package:equatable/equatable.dart';

/// A failure the UI can show. Exceptions never leave the data layer; they are
/// converted into one of these.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The server could not be reached (backend down, wrong URL, no network).
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// 401: the session is missing or expired.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

/// Any other error response from the API, using the backend's error format:
/// { "message": "...", "error": { "code": "...", "details": [{field, message}] } }
final class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    required this.statusCode,
    this.code,
    this.fieldErrors = const {},
  });

  final int statusCode;
  final String? code;

  /// Field name → message, from a 422 VALIDATION_ERROR.
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [message, statusCode, code, fieldErrors];
}

/// Something the app did not expect (a bug or a malformed response).
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
