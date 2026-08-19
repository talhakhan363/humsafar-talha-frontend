import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';

void main() {
  group('ApiException.fromJson', () {
    test('parses the standard SDS error envelope', () {
      final json = {
        'code': 'invalid_credentials',
        'message': 'Email or password is incorrect.',
        'details': {'field': 'password'},
      };

      final exception = ApiException.fromJson(json, statusCode: 401);

      expect(exception.code, 'invalid_credentials');
      expect(exception.message, 'Email or password is incorrect.');
      expect(exception.details, {'field': 'password'});
      expect(exception.statusCode, 401);
    });

    test('falls back sensibly when code/message are missing', () {
      final exception = ApiException.fromJson(<String, dynamic>{});

      expect(exception.code, 'unknown_error');
      expect(exception.message, isNotEmpty);
    });
  });

  group('ApiException.unexpected', () {
    test('carries the given message with the unexpected_error code', () {
      final exception = ApiException.unexpected('Connection timed out', statusCode: null);

      expect(exception.code, 'unexpected_error');
      expect(exception.message, 'Connection timed out');
      expect(exception.statusCode, isNull);
    });
  });
}
