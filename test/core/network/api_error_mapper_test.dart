import 'package:dio/dio.dart';
import 'package:rombong/core/error/failure.dart';
import 'package:rombong/core/network/api_error_mapper.dart';
import 'package:rombong/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _response(int status, Object? body) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  test('422 maps message, code and field errors', () {
    final failure = mapDioException(_response(422, {
      'success': false,
      'message': 'Validation failed',
      'error': {
        'code': 'VALIDATION_ERROR',
        'details': [
          {'field': 'email', 'message': 'must be a valid email address'},
          {'field': 'password', 'message': 'is required'},
        ],
      },
      'request_id': 'abc',
    }));

    expect(failure, isA<ServerFailure>());
    final f = failure as ServerFailure;
    expect(f.message, 'Validation failed');
    expect(f.statusCode, 422);
    expect(f.code, 'VALIDATION_ERROR');
    expect(f.fieldErrors, {'email': 'must be a valid email address', 'password': 'is required'});
  });

  test('401 maps to UnauthorizedFailure', () {
    final failure = mapDioException(_response(401, {
      'success': false,
      'message': 'Invalid email or password',
      'error': {'code': 'UNAUTHORIZED'},
    }));
    expect(failure, const UnauthorizedFailure('Invalid email or password'));
  });

  test('409 keeps the backend message', () {
    final failure = mapDioException(_response(409, {
      'success': false,
      'message': 'Email is already registered',
      'error': {'code': 'CONFLICT'},
    }));
    expect((failure as ServerFailure).code, 'CONFLICT');
    expect(failure.message, 'Email is already registered');
  });

  test('connection errors map to NetworkFailure', () {
    final failure = mapDioException(DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    ));
    expect(failure, isA<NetworkFailure>());
  });

  test('non-JSON error body still produces a readable failure', () {
    final failure = mapDioException(_response(502, '<html>Bad Gateway</html>'));
    expect(failure, isA<ServerFailure>());
    expect(failure.message, contains('502'));
  });

  test('guard wraps success and failure', () async {
    expect(await guard(() async => 42), isA<Ok<int>>());
    final err = await guard<int>(() async => throw _response(500, null));
    expect(err, isA<Err<int>>());
  });
}
