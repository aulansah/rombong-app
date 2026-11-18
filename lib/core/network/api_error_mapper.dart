import 'package:dio/dio.dart';

import '../error/failure.dart';
import '../result.dart';

/// Converts a Dio error into a [Failure], reading the backend's standard
/// error envelope.
Failure mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure(
        'Tidak bisa terhubung ke server. Pastikan backend sudah berjalan.',
      );
    default:
      break;
  }

  final response = e.response;
  if (response == null) {
    return UnexpectedFailure(e.message ?? 'Terjadi kesalahan yang tidak terduga.');
  }

  final status = response.statusCode ?? 0;
  var message = 'Terjadi kesalahan ($status).';
  String? code;
  final fieldErrors = <String, String>{};

  final body = response.data;
  if (body is Map<String, dynamic>) {
    message = body['message'] as String? ?? message;
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      code = error['code'] as String?;
      final details = error['details'];
      if (details is List) {
        for (final d in details) {
          if (d is Map && d['field'] != null) {
            fieldErrors['${d['field']}'] = '${d['message']}';
          }
        }
      }
    }
  }

  if (status == 401) return UnauthorizedFailure(message);
  return ServerFailure(message, statusCode: status, code: code, fieldErrors: fieldErrors);
}

/// Runs a data-layer call and turns any exception into an [Err], so
/// repositories stay free of repetitive try/catch blocks.
Future<Result<T>> guard<T>(Future<T> Function() run) async {
  try {
    return Ok(await run());
  } on DioException catch (e) {
    return Err(mapDioException(e));
  } catch (e) {
    return Err(UnexpectedFailure(e.toString()));
  }
}
